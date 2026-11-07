import 'dart:math' as math;
import 'dart:ui';

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
  });
}
