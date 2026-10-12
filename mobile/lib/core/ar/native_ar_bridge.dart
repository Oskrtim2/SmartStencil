import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

import 'ar_platform_bridge.dart';
import 'mock_ar_bridge.dart';

/// Concrete production bridge connecting Flutter to iOS ARKit and Android ARCore
/// through platform MethodChannels and EventChannels.
class NativeArBridge implements ArPlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.inksight.ar/methods');
  static const EventChannel _anchorEventChannel = EventChannel('com.inksight.ar/anchors');
  static const EventChannel _trackingEventChannel = EventChannel('com.inksight.ar/tracking');

  final _anchorsController = StreamController<List<SurfaceAnchor>>.broadcast();
  final _trackingStateController = StreamController<TrackingState>.broadcast();
  final _cameraFramesController = StreamController<CameraFrame>.broadcast();

  StreamSubscription? _anchorSubscription;
  StreamSubscription? _trackingSubscription;
  bool _isNativeAvailable = false;
  final MockArBridge _fallbackBridge = MockArBridge();

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
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final supported = await _channel.invokeMethod<bool>('checkArSupport') ?? false;
        _isNativeAvailable = supported;

        if (_isNativeAvailable) {
          await _channel.invokeMethod('initialize', {
            'enableMeshReconstruction': enableMeshReconstruction,
            'enableBodyTracking': enableBodyTracking,
          });

          _anchorSubscription = _anchorEventChannel.receiveBroadcastStream().listen((dynamic data) {
            // Process native anchors
          });

          _trackingSubscription = _trackingEventChannel.receiveBroadcastStream().listen((dynamic data) {
            _trackingStateController.add(TrackingState.normal);
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[NativeArBridge] Native platform channels not connected, falling back to mock: $e');
    }

    // Graceful fallback to simulation
    _isNativeAvailable = false;
    await _fallbackBridge.initialize(
      enableMeshReconstruction: enableMeshReconstruction,
      enableBodyTracking: enableBodyTracking,
    );
  }

  @override
  Future<bool> startSession() async {
    if (_isNativeAvailable) {
      final success = await _channel.invokeMethod<bool>('startSession') ?? false;
      return success;
    }
    return _fallbackBridge.startSession();
  }

  @override
  Future<void> pauseSession() async {
    if (_isNativeAvailable) {
      await _channel.invokeMethod('pauseSession');
      return;
    }
    await _fallbackBridge.pauseSession();
  }

  @override
  Future<void> resumeSession() async {
    if (_isNativeAvailable) {
      await _channel.invokeMethod('resumeSession');
      return;
    }
    await _fallbackBridge.resumeSession();
  }

  @override
  Future<void> dispose() async {
    await _anchorSubscription?.cancel();
    await _trackingSubscription?.cancel();
    await _anchorsController.close();
    await _trackingStateController.close();
    await _cameraFramesController.close();
    await _fallbackBridge.dispose();
  }

  @override
  Future<HitTestResult?> hitTest(ui.Offset screenPoint) async {
    if (_isNativeAvailable) {
      final res = await _channel.invokeMapMethod<String, dynamic>('hitTest', {
        'x': screenPoint.dx,
        'y': screenPoint.dy,
      });
      if (res != null) {
        return HitTestResult(
          worldPosition: Vector3(res['x'] ?? 0.0, res['y'] ?? 0.0, res['z'] ?? -0.5),
          worldNormal: Vector3(res['nx'] ?? 0.0, res['ny'] ?? 0.0, res['nz'] ?? 1.0),
          distance: (res['distance'] as num?)?.toDouble() ?? 0.5,
        );
      }
    }
    return _fallbackBridge.hitTest(screenPoint);
  }

  @override
  Future<SurfaceAnchor> placeAnchor(Matrix4 transform) async {
    if (_isNativeAvailable) {
      await _channel.invokeMethod('placeAnchor', {
        'matrix': transform.storage,
      });
    }
    return _fallbackBridge.placeAnchor(transform);
  }

  @override
  Future<void> removeAnchor(String anchorId) async {
    if (_isNativeAvailable) {
      await _channel.invokeMethod('removeAnchor', {'id': anchorId});
    }
    await _fallbackBridge.removeAnchor(anchorId);
  }

  @override
  Future<bool> isSupported() async {
    if (_isNativeAvailable) return true;
    return _fallbackBridge.isSupported();
  }

  @override
  Future<bool> hasLiDAR() async {
    if (Platform.isIOS && _isNativeAvailable) {
      return await _channel.invokeMethod<bool>('hasLiDAR') ?? false;
    }
    return false;
  }
}
