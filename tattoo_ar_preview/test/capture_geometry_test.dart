import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/capture/domain/capture_geometry.dart';

void main() {
  group('CaptureGeometry', () {
    test('centers the cover crop of a wide photo in a portrait viewport', () {
      final Rect crop = CaptureGeometry.coverSourceRect(
        const Size(1920, 1080),
        9 / 16,
      );

      expect(crop.width, closeTo(607.5, 1e-9));
      expect(crop.height, 1080);
      expect(crop.left, closeTo((1920 - 607.5) / 2, 1e-9));
      expect(crop.top, 0);
    });

    test('keeps the viewport aspect ratio and caps the long side', () {
      final Size output = CaptureGeometry.outputSizeFor(
        const Size(4000, 3000),
        const Size(1080, 1920),
        maxLongSide: 2560,
      );

      expect(output.width / output.height, closeTo(1080 / 1920, 1e-9));
      expect(math.max(output.width, output.height), closeTo(2560, 1e-6));
    });

    test('does not upscale small photos', () {
      final Size output = CaptureGeometry.outputSizeFor(
        const Size(640, 480),
        const Size(360, 640),
        maxLongSide: 2560,
      );

      expect(math.max(output.width, output.height), lessThanOrEqualTo(480));
    });

    test('returns zero for empty inputs', () {
      expect(
        CaptureGeometry.outputSizeFor(Size.zero, const Size(100, 100)),
        Size.zero,
      );
      expect(
        CaptureGeometry.coverSourceRect(const Size(100, 100), 0),
        Rect.zero,
      );
    });

    test('clamps the fallback pixel ratio to a safe range', () {
      expect(CaptureGeometry.fallbackPixelRatio(1), 1.5);
      expect(CaptureGeometry.fallbackPixelRatio(2), 2);
      expect(CaptureGeometry.fallbackPixelRatio(4), 3);
      expect(CaptureGeometry.fallbackPixelRatio(double.nan), 1.5);
    });

    test('returns zero for invalid maximum dimensions', () {
      const Size photo = Size(640, 480);
      const Size viewport = Size(360, 640);

      expect(
        CaptureGeometry.outputSizeFor(photo, viewport, maxLongSide: 0),
        Size.zero,
      );
      expect(
        CaptureGeometry.outputSizeFor(photo, viewport, maxLongSide: -10),
        Size.zero,
      );
      expect(
        CaptureGeometry.outputSizeFor(
          photo,
          viewport,
          maxLongSide: double.infinity,
        ),
        Size.zero,
      );
      expect(
        CaptureGeometry.outputSizeFor(photo, viewport, maxLongSide: double.nan),
        Size.zero,
      );
    });
  });
}
