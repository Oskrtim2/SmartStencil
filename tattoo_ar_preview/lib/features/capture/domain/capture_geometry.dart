import 'dart:math' as math;
import 'dart:ui';

abstract final class CaptureGeometry {
  static Rect coverSourceRect(Size source, double targetAspect) {
    if (source.isEmpty || targetAspect <= 0 || !targetAspect.isFinite) {
      return Rect.zero;
    }
    final double sourceAspect = source.width / source.height;
    if (sourceAspect > targetAspect) {
      final double width = source.height * targetAspect;
      return Rect.fromLTWH((source.width - width) / 2, 0, width, source.height);
    }
    final double height = source.width / targetAspect;
    return Rect.fromLTWH(0, (source.height - height) / 2, source.width, height);
  }

  static Size outputSizeFor(
    Size photo,
    Size viewport, {
    double maxLongSide = 2560,
  }) {
    if (photo.isEmpty || viewport.isEmpty) {
      return Size.zero;
    }
    final Rect crop = coverSourceRect(photo, viewport.width / viewport.height);
    if (crop.isEmpty) {
      return Size.zero;
    }
    final double longestSide = math.max(crop.width, crop.height);
    if (longestSide <= 0) {
      return Size.zero;
    }
    final double scale = math.min(1, maxLongSide / longestSide);
    return Size(crop.width * scale, crop.height * scale);
  }
}
