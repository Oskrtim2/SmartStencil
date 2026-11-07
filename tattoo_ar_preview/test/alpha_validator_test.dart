import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/domain/alpha_validator.dart';

void main() {
  group('AlphaValidator', () {
    test('detects fully transparent pixels', () {
      final Uint8List rgba = Uint8List.fromList(<int>[
        10,
        20,
        30,
        255,
        10,
        20,
        30,
        0,
      ]);

      expect(AlphaValidator.hasTransparentPixel(rgba), isTrue);
    });

    test('detects semi-transparent pixels below the threshold', () {
      final Uint8List rgba = Uint8List.fromList(<int>[10, 20, 30, 120]);

      expect(AlphaValidator.hasTransparentPixel(rgba), isTrue);
    });

    test('rejects fully opaque pixel buffers', () {
      final Uint8List rgba = Uint8List.fromList(<int>[
        10,
        20,
        30,
        255,
        40,
        50,
        60,
        250,
      ]);

      expect(AlphaValidator.hasTransparentPixel(rgba), isFalse);
    });

    test('handles empty buffers safely', () {
      expect(AlphaValidator.hasTransparentPixel(Uint8List(0)), isFalse);
    });
  });
}
