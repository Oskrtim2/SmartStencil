import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/processing/background_analysis.dart';

void main() {
  group('BorderAnalysis', () {
    test('detects a uniform white background', () {
      final Uint8List rgba = _borderImage(
        20,
        20,
        (int x, int y) => x == 10 ? 0xFF000000 : 0xFFFFFFFF,
      );

      final BorderAnalysis analysis = BorderAnalysis.analyze(rgba, 20, 20);

      expect(analysis.isUniform, isTrue);
      expect(analysis.isDark, isFalse);
      expect(analysis.dominantColorArgb, 0xFFFFFFFF);
      expect(analysis.coverage, greaterThan(0.8));
    });

    test('detects a uniform black background', () {
      final Uint8List rgba = _borderImage(
        20,
        20,
        (int x, int y) => x == 10 ? 0xFFFFFFFF : 0xFF000000,
      );

      final BorderAnalysis analysis = BorderAnalysis.analyze(rgba, 20, 20);

      expect(analysis.isUniform, isTrue);
      expect(analysis.isDark, isTrue);
      expect(analysis.dominantColorArgb, 0xFF000000);
    });

    test('rejects a varied gradient border', () {
      final Uint8List rgba = _borderImage(20, 20, (int x, int y) {
        final int value = (x * 13 + y * 7) & 0xFF;
        return 0xFF000000 | (value << 16) | (value << 8) | value;
      });

      final BorderAnalysis analysis = BorderAnalysis.analyze(rgba, 20, 20);

      expect(analysis.isUniform, isFalse);
    });

    test('handles empty and transparent images safely', () {
      expect(BorderAnalysis.analyze(Uint8List(0), 0, 0).isUniform, isFalse);
      expect(
        BorderAnalysis.analyze(Uint8List(20 * 20 * 4), 20, 20).coverage,
        0,
      );
    });
  });
}

Uint8List _borderImage(
  int width,
  int height,
  int Function(int x, int y) colorAt,
) {
  final Uint8List rgba = Uint8List(width * height * 4);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int argb = colorAt(x, y);
      final int index = (y * width + x) * 4;
      rgba[index] = (argb >> 16) & 0xFF;
      rgba[index + 1] = (argb >> 8) & 0xFF;
      rgba[index + 2] = argb & 0xFF;
      rgba[index + 3] = (argb >> 24) & 0xFF;
    }
  }
  return rgba;
}
