import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/domain/tattoo_transform.dart';

void main() {
  group('TattooTransform', () {
    test('normalizes scale and translation into safe bounds', () {
      const TattooTransform transform = TattooTransform(
        translation: Offset(9, -9),
        scale: 99,
        rotation: 0,
      );

      final TattooTransform normalized = transform.normalized();

      expect(
        normalized.translation,
        const Offset(
          TattooTransform.maxTranslation,
          -TattooTransform.maxTranslation,
        ),
      );
      expect(normalized.scale, TattooTransform.maxScale);
    });

    test('wraps rotation into the negative pi to pi range', () {
      final TattooTransform normalized = const TattooTransform(
        rotation: math.pi * 2 + 0.25,
      ).normalized();

      expect(normalized.rotation, closeTo(0.25, 1e-9));
    });

    test('compares by value', () {
      const TattooTransform a = TattooTransform(scale: 2);
      const TattooTransform b = TattooTransform(scale: 2);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('sanitizes non-finite values', () {
      final TattooTransform normalized = const TattooTransform(
        translation: Offset(double.nan, double.infinity),
        scale: double.nan,
        rotation: double.nan,
      ).normalized();

      expect(normalized.translation.dx, 0);
      expect(normalized.translation.dy, TattooTransform.maxTranslation);
      expect(normalized.scale, 1);
      expect(normalized.rotation, 0);

      final TattooTransform saturated = const TattooTransform(
        translation: Offset(double.infinity, 0),
        scale: double.infinity,
        rotation: double.infinity,
      ).normalized();

      expect(saturated.translation.dx, TattooTransform.maxTranslation);
      expect(saturated.scale, TattooTransform.maxScale);
      expect(saturated.rotation, 0);
    });
  });
}
