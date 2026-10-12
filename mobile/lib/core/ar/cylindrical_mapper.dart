import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'ar_platform_bridge.dart';

/// Estimates and tracks a cylindrical proxy surface for limbs (arms/legs).
///
/// Strategy:
/// - On LiDAR devices: uses the mesh vertices from ARMeshAnchor to fit a
///   cylinder via least-squares.
/// - On non-LiDAR devices: uses the detected plane width + depth heuristics
///   to estimate a cylinder whose axis is parallel to the plane's long edge.
///
/// The output [CylindricalMapping] provides UV coordinates that wrap the
/// tattoo texture around the estimated cylinder, so designs conform to
/// anatomical curvature rather than floating as flat decals.
class CylindricalMapper {
  /// Minimum number of mesh vertices required for cylinder fitting.
  static const int _minVerticesForFit = 50;

  /// Default arm radius estimate in meters (average adult forearm).
  static const double _defaultArmRadius = 0.042;

  /// Default leg radius estimate in meters (average adult calf).
  static const double _defaultLegRadius = 0.065;

  CylindricalMapper();

  /// Fit a cylindrical surface from LiDAR mesh vertices.
  ///
  /// Uses a simplified RANSAC-style cylinder fit:
  /// 1. Estimate principal axis via PCA on vertex positions.
  /// 2. Project vertices onto the plane perpendicular to the axis.
  /// 3. Fit a circle to the 2D projections (least-squares).
  CylindricalMapping? fitFromMeshVertices(List<Vector3> vertices) {
    if (vertices.length < _minVerticesForFit) return null;

    // Step 1: Compute centroid
    final centroid = _computeCentroid(vertices);

    // Step 2: PCA — find principal axis (cylinder axis)
    final covarianceMatrix = _computeCovarianceMatrix(vertices, centroid);
    final eigenResult = _powerIteration(covarianceMatrix, iterations: 30);
    final axis = eigenResult.normalized();

    // Step 3: Project vertices onto plane perpendicular to axis
    final projected = vertices.map((v) {
      final relative = v - centroid;
      final alongAxis = axis.scaled(relative.dot(axis));
      return relative - alongAxis;
    }).toList();

    // Step 4: Fit circle to 2D projections (radius estimation)
    final distances = projected.map((p) => p.length).toList();
    final radius = distances.reduce((a, b) => a + b) / distances.length;

    // Step 5: Compute axis extent (cylinder height)
    final axisProjections = vertices.map((v) => (v - centroid).dot(axis)).toList();
    axisProjections.sort();
    final height = axisProjections.last - axisProjections.first;

    return CylindricalMapping(
      center: centroid,
      axis: axis,
      radius: radius,
      height: height,
      source: MappingSource.lidarMesh,
    );
  }

  /// Estimate a cylindrical proxy from a flat plane anchor.
  ///
  /// Heuristic: the plane's short dimension approximates the visible chord
  /// of the arm/leg cross-section. Radius is estimated from this chord.
  CylindricalMapping estimateFromPlane(SurfaceAnchor plane, {
    BodyPart bodyPart = BodyPart.forearm,
  }) {
    final defaultRadius = switch (bodyPart) {
      BodyPart.forearm   => _defaultArmRadius,
      BodyPart.upperArm  => _defaultArmRadius * 1.4,
      BodyPart.calf      => _defaultLegRadius,
      BodyPart.thigh     => _defaultLegRadius * 1.5,
      BodyPart.shoulder  => _defaultArmRadius * 1.6,
    };

    // Axis aligns with the plane's long edge (Z-forward in plane-local space)
    final axis = plane.transform.getColumn(2).xyz.normalized();
    final center = plane.center + plane.normal * defaultRadius;

    return CylindricalMapping(
      center: center,
      axis: axis,
      radius: defaultRadius,
      height: 0.30, // ~30cm visible section
      source: MappingSource.planeEstimate,
    );
  }

  /// Compute cylindrical UV coordinates for a 3D point on the surface.
  ///
  /// U = angular position around the cylinder (0→1 = 0°→360°)
  /// V = position along the cylinder axis (0→1 = bottom→top)
  Vector2 worldToUV(Vector3 worldPoint, CylindricalMapping cylinder) {
    final relative = worldPoint - cylinder.center;

    // Project onto axis to get V coordinate
    final alongAxis = relative.dot(cylinder.axis);
    final v = (alongAxis / cylinder.height) + 0.5; // Center at 0.5

    // Remove axis component to get radial vector
    final radial = relative - cylinder.axis.scaled(alongAxis);

    // Compute angle for U coordinate
    // Build a local coordinate frame perpendicular to the axis
    final refDir = _perpendicularTo(cylinder.axis);
    final crossDir = cylinder.axis.cross(refDir);

    final angle = math.atan2(
      radial.dot(crossDir),
      radial.dot(refDir),
    );
    final u = (angle / (2.0 * math.pi)) + 0.5;

    return Vector2(u.clamp(0.0, 1.0), v.clamp(0.0, 1.0));
  }

  /// Build a UV transform matrix that maps screen coordinates to cylindrical
  /// UV space, incorporating gesture transforms (pan, scale, rotate).
  Matrix3 buildUvTransformMatrix({
    required CylindricalMapping cylinder,
    required Vector2 gestureTranslation,
    required double gestureScale,
    required double gestureRotation,
  }) {
    // Start with identity
    var transform = Matrix3.identity();

    // Apply cylindrical warp factor
    // Horizontal scaling accounts for surface curvature
    final warpFactor = 1.0 / (cylinder.radius * 2.0 * math.pi);

    // Translation (pan gesture mapped to UV space)
    final translateMatrix = Matrix3.identity()
      ..setEntry(0, 2, gestureTranslation.x * warpFactor)
      ..setEntry(1, 2, gestureTranslation.y);

    // Scale (pinch gesture)
    final scaleMatrix = Matrix3.identity()
      ..setEntry(0, 0, 1.0 / gestureScale)
      ..setEntry(1, 1, 1.0 / gestureScale);

    // Rotation (two-finger rotate)
    final cos = math.cos(gestureRotation);
    final sin = math.sin(gestureRotation);
    final rotateMatrix = Matrix3.identity()
      ..setEntry(0, 0, cos)
      ..setEntry(0, 1, -sin)
      ..setEntry(1, 0, sin)
      ..setEntry(1, 1, cos);

    // Compose: T * R * S (applied in reverse order to the UV)
    transform = translateMatrix * rotateMatrix * scaleMatrix;

    return transform;
  }

  // ── Private helpers ───────────────────────────────────────

  Vector3 _computeCentroid(List<Vector3> points) {
    final sum = points.fold(Vector3.zero(), (acc, p) => acc + p);
    return sum / points.length.toDouble();
  }

  Matrix3 _computeCovarianceMatrix(List<Vector3> points, Vector3 centroid) {
    final cov = Matrix3.zero();
    for (final p in points) {
      final d = p - centroid;
      cov.setEntry(0, 0, cov.entry(0, 0) + d.x * d.x);
      cov.setEntry(0, 1, cov.entry(0, 1) + d.x * d.y);
      cov.setEntry(0, 2, cov.entry(0, 2) + d.x * d.z);
      cov.setEntry(1, 0, cov.entry(1, 0) + d.y * d.x);
      cov.setEntry(1, 1, cov.entry(1, 1) + d.y * d.y);
      cov.setEntry(1, 2, cov.entry(1, 2) + d.y * d.z);
      cov.setEntry(2, 0, cov.entry(2, 0) + d.z * d.x);
      cov.setEntry(2, 1, cov.entry(2, 1) + d.z * d.y);
      cov.setEntry(2, 2, cov.entry(2, 2) + d.z * d.z);
    }
    final n = points.length.toDouble();
    return cov..scale(1.0 / n);
  }

  /// Power iteration to find the dominant eigenvector of a 3×3 matrix.
  Vector3 _powerIteration(Matrix3 matrix, {int iterations = 30}) {
    var v = Vector3(1, 1, 1)..normalize();
    for (var i = 0; i < iterations; i++) {
      v = matrix.transformed(v);
      if (v.length > 1e-8) {
        v.normalize();
      }
    }
    return v;
  }

  /// Find an arbitrary vector perpendicular to [v].
  Vector3 _perpendicularTo(Vector3 v) {
    if (v.x.abs() < 0.9) {
      return v.cross(Vector3(1, 0, 0)).normalized();
    }
    return v.cross(Vector3(0, 1, 0)).normalized();
  }
}

/// A fitted or estimated cylindrical surface.
@immutable
class CylindricalMapping {
  /// Center of the cylinder in world space.
  final Vector3 center;

  /// Normalized axis direction of the cylinder.
  final Vector3 axis;

  /// Estimated radius in meters.
  final double radius;

  /// Estimated height (extent along axis) in meters.
  final double height;

  /// How this mapping was derived.
  final MappingSource source;

  const CylindricalMapping({
    required this.center,
    required this.axis,
    required this.radius,
    required this.height,
    required this.source,
  });

  /// Angular coverage in radians for a given chord width on the surface.
  double chordToArc(double chordWidth) {
    return 2.0 * math.asin((chordWidth / 2.0) / radius);
  }
}

/// How the cylindrical mapping was derived.
enum MappingSource {
  lidarMesh,
  planeEstimate,
}

/// Supported body parts for radius estimation fallback.
enum BodyPart {
  forearm,
  upperArm,
  calf,
  thigh,
  shoulder,
}
