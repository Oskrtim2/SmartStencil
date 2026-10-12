import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

/// Represents a tracked surface point in 3D world space.
class SurfaceAnchor {
  final String id;
  final Matrix4 transform;
  final Vector3 center;
  final Vector3 normal;
  final double estimatedRadius; // For cylindrical approximation (meters)
  final SurfaceType type;

  const SurfaceAnchor({
    required this.id,
    required this.transform,
    required this.center,
    required this.normal,
    required this.estimatedRadius,
    required this.type,
  });
}

enum SurfaceType {
  flat,        // Standard plane anchor
  cylindrical, // Estimated or mesh-derived curved surface
  mesh,        // LiDAR mesh reconstruction
}

/// AR tracking state reported by the native engine.
enum TrackingState {
  notAvailable,
  limited,
  normal,
}

/// Reason for limited tracking.
enum TrackingLimitedReason {
  none,
  initializing,
  excessiveMotion,
  insufficientFeatures,
  relocalizing,
}

/// Abstract bridge over ARKit (iOS) and ARCore (Android).
///
/// Each platform implements this via platform channels or direct plugin calls.
/// The bridge exposes a unified surface-tracking + rendering API.
abstract class ArPlatformBridge {
  /// Initialize the AR session with body/surface tracking.
  Future<void> initialize({
    required bool enableMeshReconstruction, // LiDAR only
    required bool enableBodyTracking,
  });

  /// Start the AR session. Returns false if AR is not supported.
  Future<bool> startSession();

  /// Pause the AR session (e.g., when app backgrounded).
  Future<void> pauseSession();

  /// Resume a paused session.
  Future<void> resumeSession();

  /// Destroy the session and release all native resources.
  Future<void> dispose();

  /// Stream of detected/updated surface anchors.
  Stream<List<SurfaceAnchor>> get surfaceAnchors;

  /// Stream of tracking state changes.
  Stream<TrackingState> get trackingState;

  /// Stream of camera frames as raw RGBA data for shader input.
  /// Each frame includes the image bytes and the camera projection matrix.
  Stream<CameraFrame> get cameraFrames;

  /// Perform a hit-test from screen coordinates into the AR world.
  /// Returns the nearest [SurfaceAnchor] and the 3D hit point.
  Future<HitTestResult?> hitTest(ui.Offset screenPoint);

  /// Place a virtual anchor at the given world transform.
  Future<SurfaceAnchor> placeAnchor(Matrix4 transform);

  /// Remove a previously placed anchor.
  Future<void> removeAnchor(String anchorId);

  /// Check if device supports AR.
  Future<bool> isSupported();

  /// Check if device has LiDAR (mesh reconstruction capable).
  Future<bool> hasLiDAR();
}

/// A single camera frame delivered from the AR engine.
@immutable
class CameraFrame {
  /// Raw RGBA pixel data.
  final Uint8List rgbaBytes;

  /// Frame dimensions.
  final int width;
  final int height;

  /// Camera intrinsics (projection matrix).
  final Matrix4 projectionMatrix;

  /// Camera extrinsics (view matrix — world-to-camera transform).
  final Matrix4 viewMatrix;

  /// Timestamp in microseconds.
  final int timestampUs;

  const CameraFrame({
    required this.rgbaBytes,
    required this.width,
    required this.height,
    required this.projectionMatrix,
    required this.viewMatrix,
    required this.timestampUs,
  });
}

/// Result of an AR hit-test.
@immutable
class HitTestResult {
  final Vector3 worldPosition;
  final Vector3 worldNormal;
  final SurfaceAnchor? anchor;
  final double distance;

  const HitTestResult({
    required this.worldPosition,
    required this.worldNormal,
    this.anchor,
    required this.distance,
  });
}
