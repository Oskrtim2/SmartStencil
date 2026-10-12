import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'ar_platform_bridge.dart';

/// Simulated AR bridge for emulators, desktop tests, and development mode.
/// Generates realistic synthetic tracking data and a test camera stream.
class MockArBridge implements ArPlatformBridge {
  final _anchorsController = StreamController<List<SurfaceAnchor>>.broadcast();
  final _trackingStateController = StreamController<TrackingState>.broadcast();
  final _cameraFramesController = StreamController<CameraFrame>.broadcast();

  Timer? _frameTimer;
  final List<SurfaceAnchor> _activeAnchors = [];
  bool _isRunning = false;

  @override
  Stream<List<SurfaceAnchor>> get surfaceAnchors => _anchorsController.stream;

  @override
  Stream<TrackingState> get trackingState => _trackingStateController.stream;

  @override
  Stream<CameraFrame> get cameraFrames => _cameraFramesController.stream;

  @override
  Future<void> initialize({
    required bool enableMeshReconstruction,
    required bool enableBodyTracking,
  }) async {
    debugPrint('[MockArBridge] Initialized (Simulation Mode)');
  }

  @override
  Future<bool> startSession() async {
    _isRunning = true;
    _trackingStateController.add(TrackingState.normal);

    // Provide an initial detected forearm surface anchor
    final defaultAnchor = SurfaceAnchor(
      id: 'mock_forearm_anchor_01',
      transform: Matrix4.identity()..translate(0.0, 0.0, -0.4),
      center: Vector3(0.0, -0.05, -0.4),
      normal: Vector3(0.0, 0.0, 1.0),
      estimatedRadius: 0.045, // 4.5cm forearm radius
      type: SurfaceType.cylindrical,
    );
    _activeAnchors.add(defaultAnchor);
    _anchorsController.add(List.unmodifiable(_activeAnchors));

    // Emit 30 FPS mock camera frames (subtle dark gradient for previewing shader)
    _frameTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_isRunning) return;
      _emitSyntheticFrame();
    });

    return true;
  }

  void _emitSyntheticFrame() {
    const width = 64;
    const height = 64;
    final bytes = Uint8List(width * height * 4);
    for (int i = 0; i < bytes.length; i += 4) {
      bytes[i] = 40;     // R
      bytes[i + 1] = 42; // G
      bytes[i + 2] = 54; // B
      bytes[i + 3] = 255;// A
    }

    _cameraFramesController.add(CameraFrame(
      rgbaBytes: bytes,
      width: width,
      height: height,
      projectionMatrix: Matrix4.identity(),
      viewMatrix: Matrix4.identity(),
      timestampUs: DateTime.now().microsecondsSinceEpoch,
    ));
  }

  @override
  Future<void> pauseSession() async {
    _isRunning = false;
    _frameTimer?.cancel();
  }

  @override
  Future<void> resumeSession() async {
    _isRunning = true;
  }

  @override
  Future<void> dispose() async {
    _isRunning = false;
    _frameTimer?.cancel();
    await _anchorsController.close();
    await _trackingStateController.close();
    await _cameraFramesController.close();
  }

  @override
  Future<HitTestResult?> hitTest(ui.Offset screenPoint) async {
    return HitTestResult(
      worldPosition: Vector3(0.0, 0.0, -0.4),
      worldNormal: Vector3(0.0, 0.0, 1.0),
      anchor: _activeAnchors.isNotEmpty ? _activeAnchors.first : null,
      distance: 0.4,
    );
  }

  @override
  Future<SurfaceAnchor> placeAnchor(Matrix4 transform) async {
    final anchor = SurfaceAnchor(
      id: 'custom_anchor_${DateTime.now().millisecondsSinceEpoch}',
      transform: transform,
      center: transform.getTranslation(),
      normal: Vector3(0, 0, 1),
      estimatedRadius: 0.045,
      type: SurfaceType.cylindrical,
    );
    _activeAnchors.add(anchor);
    _anchorsController.add(List.unmodifiable(_activeAnchors));
    return anchor;
  }

  @override
  Future<void> removeAnchor(String anchorId) async {
    _activeAnchors.removeWhere((a) => a.id == anchorId);
    _anchorsController.add(List.unmodifiable(_activeAnchors));
  }

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> hasLiDAR() async => false;
}
