import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'ar_platform_bridge.dart';
import 'cylindrical_mapper.dart';

/// Orchestrates AR surface detection and manages the lifecycle of tracked
/// surfaces, bridging raw AR anchors into [CylindricalMapping] geometry.
///
/// Responsibilities:
/// - Listens to the [ArPlatformBridge] for new/updated surface anchors.
/// - Selects the best anchor for tattoo placement (closest to tap point).
/// - Maintains the active [CylindricalMapping] and updates it as tracking
///   refines the surface estimate.
/// - Emits [SurfaceTrackingEvent]s for the UI layer.
class SurfaceTracker {
  final ArPlatformBridge _bridge;
  final CylindricalMapper _mapper;

  /// Currently active mapping (the surface the tattoo is projected onto).
  CylindricalMapping? _activeMapping;
  CylindricalMapping? get activeMapping => _activeMapping;

  /// Currently selected anchor.
  SurfaceAnchor? _selectedAnchor;
  SurfaceAnchor? get selectedAnchor => _selectedAnchor;

  /// Event stream.
  final _eventController = StreamController<SurfaceTrackingEvent>.broadcast();
  Stream<SurfaceTrackingEvent> get events => _eventController.stream;

  /// All currently visible anchors.
  List<SurfaceAnchor> _visibleAnchors = [];
  List<SurfaceAnchor> get visibleAnchors => List.unmodifiable(_visibleAnchors);

  StreamSubscription? _anchorSubscription;
  StreamSubscription? _trackingSubscription;
  bool _hasLiDAR = false;

  SurfaceTracker({
    required ArPlatformBridge bridge,
    CylindricalMapper? mapper,
  })  : _bridge = bridge,
        _mapper = mapper ?? CylindricalMapper();

  /// Initialize tracking. Call once after the AR session starts.
  Future<void> initialize() async {
    _hasLiDAR = await _bridge.hasLiDAR();

    _anchorSubscription = _bridge.surfaceAnchors.listen(_onAnchorsUpdated);
    _trackingSubscription = _bridge.trackingState.listen(_onTrackingStateChanged);

    _eventController.add(SurfaceTrackingEvent.initialized(hasLiDAR: _hasLiDAR));
  }

  /// Handle user tap to select a surface for tattoo placement.
  Future<void> selectSurface(ui.Offset screenPoint, {
    BodyPart bodyPart = BodyPart.forearm,
  }) async {
    final hitResult = await _bridge.hitTest(screenPoint);
    if (hitResult == null) {
      _eventController.add(const SurfaceTrackingEvent.noSurfaceFound());
      return;
    }

    // If hit on an existing anchor, use it
    if (hitResult.anchor != null) {
      _selectedAnchor = hitResult.anchor;
    } else {
      // Place a new anchor at the hit point
      final transform = Matrix4.identity()..setTranslation(hitResult.worldPosition);
      _selectedAnchor = await _bridge.placeAnchor(transform);
    }

    // Derive cylindrical mapping
    _updateMapping(bodyPart: bodyPart);

    _eventController.add(SurfaceTrackingEvent.surfaceSelected(
      anchor: _selectedAnchor!,
      mapping: _activeMapping!,
    ));
  }

  /// Update the body part type (changes radius estimate for non-LiDAR).
  void setBodyPart(BodyPart part) {
    if (_selectedAnchor != null) {
      _updateMapping(bodyPart: part);
      _eventController.add(SurfaceTrackingEvent.mappingUpdated(
        mapping: _activeMapping!,
      ));
    }
  }

  /// Clear the selected surface.
  Future<void> clearSelection() async {
    if (_selectedAnchor != null) {
      await _bridge.removeAnchor(_selectedAnchor!.id);
      _selectedAnchor = null;
      _activeMapping = null;
      _eventController.add(const SurfaceTrackingEvent.selectionCleared());
    }
  }

  /// Release all resources.
  Future<void> dispose() async {
    await _anchorSubscription?.cancel();
    await _trackingSubscription?.cancel();
    await _eventController.close();
  }

  // ── Private ───────────────────────────────────────────

  void _onAnchorsUpdated(List<SurfaceAnchor> anchors) {
    _visibleAnchors = anchors;

    // If we have a selected anchor, check if it was updated
    if (_selectedAnchor != null) {
      final updated = anchors.where((a) => a.id == _selectedAnchor!.id).firstOrNull;
      if (updated != null && updated.type == SurfaceType.mesh) {
        // LiDAR mesh was refined — rebuild the cylinder fit
        _selectedAnchor = updated;
        _updateMapping();
        _eventController.add(SurfaceTrackingEvent.mappingUpdated(
          mapping: _activeMapping!,
        ));
      }
    }
  }

  void _onTrackingStateChanged(TrackingState state) {
    _eventController.add(SurfaceTrackingEvent.trackingStateChanged(state: state));
  }

  void _updateMapping({BodyPart bodyPart = BodyPart.forearm}) {
    if (_selectedAnchor == null) return;

    if (_selectedAnchor!.type == SurfaceType.mesh && _hasLiDAR) {
      // TODO: Extract mesh vertices from the anchor and fit cylinder
      // For now, fall through to plane estimate
    }

    _activeMapping = _mapper.estimateFromPlane(
      _selectedAnchor!,
      bodyPart: bodyPart,
    );
  }
}

/// Events emitted by [SurfaceTracker].
@immutable
sealed class SurfaceTrackingEvent {
  const SurfaceTrackingEvent();

  const factory SurfaceTrackingEvent.initialized({required bool hasLiDAR}) = _Initialized;
  const factory SurfaceTrackingEvent.surfaceSelected({
    required SurfaceAnchor anchor,
    required CylindricalMapping mapping,
  }) = _SurfaceSelected;
  const factory SurfaceTrackingEvent.mappingUpdated({
    required CylindricalMapping mapping,
  }) = _MappingUpdated;
  const factory SurfaceTrackingEvent.noSurfaceFound() = _NoSurfaceFound;
  const factory SurfaceTrackingEvent.selectionCleared() = _SelectionCleared;
  const factory SurfaceTrackingEvent.trackingStateChanged({
    required TrackingState state,
  }) = _TrackingStateChanged;
}

class _Initialized extends SurfaceTrackingEvent {
  final bool hasLiDAR;
  const _Initialized({required this.hasLiDAR});
}

class _SurfaceSelected extends SurfaceTrackingEvent {
  final SurfaceAnchor anchor;
  final CylindricalMapping mapping;
  const _SurfaceSelected({required this.anchor, required this.mapping});
}

class _MappingUpdated extends SurfaceTrackingEvent {
  final CylindricalMapping mapping;
  const _MappingUpdated({required this.mapping});
}

class _NoSurfaceFound extends SurfaceTrackingEvent {
  const _NoSurfaceFound();
}

class _SelectionCleared extends SurfaceTrackingEvent {
  const _SelectionCleared();
}

class _TrackingStateChanged extends SurfaceTrackingEvent {
  final TrackingState state;
  const _TrackingStateChanged({required this.state});
}
