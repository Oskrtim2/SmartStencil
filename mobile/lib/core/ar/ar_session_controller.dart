import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'ar_platform_bridge.dart';
import 'cylindrical_mapper.dart';
import 'surface_tracker.dart';

/// The top-level AR session controller that orchestrates:
/// - AR engine lifecycle (init → start → pause → resume → destroy)
/// - Surface tracking and cylindrical mapping
/// - Tattoo texture management (load into GPU, zero source bytes)
/// - Shader uniform state (opacity, UV transform)
/// - Frame-by-frame render state for the UI layer
///
/// The UI binds to [renderState] and rebuilds the shader on each frame.
class ArSessionController extends ChangeNotifier {
  final ArPlatformBridge _bridge;
  late final SurfaceTracker _surfaceTracker;
  final CylindricalMapper _mapper = CylindricalMapper();

  // ── Session State ──────────────────────────────────
  ArSessionState _state = ArSessionState.uninitialized;
  ArSessionState get state => _state;

  TrackingState _trackingState = TrackingState.notAvailable;
  TrackingState get trackingState => _trackingState;

  // ── Tattoo Texture ─────────────────────────────────
  ui.Image? _tattooImage;
  ui.Image? get tattooImage => _tattooImage;
  bool get hasTattoo => _tattooImage != null;

  // ── Gesture State ──────────────────────────────────
  Vector2 _translation = Vector2.zero();
  double _scale = 1.0;
  double _rotation = 0.0;

  Vector2 get translation => _translation;
  double get scale => _scale;
  double get rotation => _rotation;

  // ── Rendering Parameters ───────────────────────────
  double _opacity = 0.85;
  double get opacity => _opacity;

  double _edgeSoftness = 1.0;
  double get edgeSoftness => _edgeSoftness;

  // ── Cylindrical Mapping ────────────────────────────
  CylindricalMapping? get activeMapping => _surfaceTracker.activeMapping;

  // ── UV Transform Matrix (fed to shader) ────────────
  Matrix3 get uvTransformMatrix {
    final mapping = activeMapping;
    if (mapping == null) {
      // Fallback: flat projection with gesture transforms
      return _buildFlatUvTransform();
    }
    return _mapper.buildUvTransformMatrix(
      cylinder: mapping,
      gestureTranslation: _translation,
      gestureScale: _scale,
      gestureRotation: _rotation,
    );
  }

  StreamSubscription? _trackingEventSub;
  StreamSubscription? _trackingStateSub;

  ArSessionController({required ArPlatformBridge bridge}) : _bridge = bridge {
    _surfaceTracker = SurfaceTracker(bridge: _bridge, mapper: _mapper);
  }

  // ── Lifecycle ──────────────────────────────────────

  /// Initialize and start the AR session.
  Future<void> initialize() async {
    if (_state != ArSessionState.uninitialized) return;

    _state = ArSessionState.initializing;
    notifyListeners();

    final supported = await _bridge.isSupported();
    if (!supported) {
      _state = ArSessionState.unsupported;
      notifyListeners();
      return;
    }

    final hasLiDAR = await _bridge.hasLiDAR();

    await _bridge.initialize(
      enableMeshReconstruction: hasLiDAR,
      enableBodyTracking: true,
    );

    await _surfaceTracker.initialize();

    _trackingEventSub = _surfaceTracker.events.listen(_onSurfaceEvent);
    _trackingStateSub = _bridge.trackingState.listen((state) {
      _trackingState = state;
      notifyListeners();
    });

    final started = await _bridge.startSession();
    _state = started ? ArSessionState.running : ArSessionState.error;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_state == ArSessionState.running) {
      await _bridge.pauseSession();
      _state = ArSessionState.paused;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_state == ArSessionState.paused) {
      await _bridge.resumeSession();
      _state = ArSessionState.running;
      notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    await _trackingEventSub?.cancel();
    await _trackingStateSub?.cancel();
    await _surfaceTracker.dispose();
    await _bridge.dispose();
    _tattooImage?.dispose();
    _tattooImage = null;
    super.dispose();
  }

  // ── Surface Selection ──────────────────────────────

  /// User taps to select the body surface for tattoo placement.
  Future<void> selectSurface(ui.Offset screenPoint, {
    BodyPart bodyPart = BodyPart.forearm,
  }) async {
    await _surfaceTracker.selectSurface(screenPoint, bodyPart: bodyPart);
  }

  void setBodyPart(BodyPart part) => _surfaceTracker.setBodyPart(part);

  // ── Tattoo Texture ─────────────────────────────────

  /// Load a tattoo PNG from raw bytes into a GPU-ready [ui.Image].
  ///
  /// SECURITY: The source [Uint8List] is zeroed after decoding to prevent
  /// the raw high-res image from remaining in process memory.
  Future<void> loadTattooFromBytes(Uint8List pngBytes) async {
    // Decode PNG → ui.Image (GPU texture)
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    _tattooImage?.dispose();
    _tattooImage = frame.image;

    // SECURITY: Zero out the source bytes immediately
    for (var i = 0; i < pngBytes.length; i++) {
      pngBytes[i] = 0;
    }

    // Reset gesture state for new design
    _translation = Vector2.zero();
    _scale = 1.0;
    _rotation = 0.0;

    notifyListeners();
  }

  /// Remove the loaded tattoo.
  void clearTattoo() {
    _tattooImage?.dispose();
    _tattooImage = null;
    notifyListeners();
  }

  // ── Gesture Handlers ───────────────────────────────

  void onPanUpdate(ui.Offset delta) {
    _translation += Vector2(delta.dx / 500.0, delta.dy / 500.0);
    notifyListeners();
  }

  void onScaleUpdate(double scaleFactor) {
    _scale = (_scale * scaleFactor).clamp(0.1, 5.0);
    notifyListeners();
  }

  void onRotationUpdate(double angleDelta) {
    _rotation += angleDelta;
    notifyListeners();
  }

  // ── Rendering Parameters ───────────────────────────

  void setOpacity(double value) {
    _opacity = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEdgeSoftness(double value) {
    _edgeSoftness = value.clamp(0.2, 3.0);
    notifyListeners();
  }

  // ── Private ────────────────────────────────────────

  Matrix3 _buildFlatUvTransform() {
    final translate = Matrix3.identity()
      ..setEntry(0, 2, _translation.x)
      ..setEntry(1, 2, _translation.y);

    final cos = _rotation == 0 ? 1.0 : math.cos(_rotation);
    final sin = _rotation == 0 ? 0.0 : math.sin(_rotation);
    final rotate = Matrix3.identity()
      ..setEntry(0, 0, cos)
      ..setEntry(0, 1, -sin)
      ..setEntry(1, 0, sin)
      ..setEntry(1, 1, cos);

    final scaleM = Matrix3.identity()
      ..setEntry(0, 0, 1.0 / _scale)
      ..setEntry(1, 1, 1.0 / _scale);

    return translate * rotate * scaleM;
  }

  void _onSurfaceEvent(SurfaceTrackingEvent event) {
    // Forward relevant events to trigger UI rebuild
    notifyListeners();
  }
}

/// AR session lifecycle states.
enum ArSessionState {
  uninitialized,
  initializing,
  running,
  paused,
  error,
  unsupported,
}
