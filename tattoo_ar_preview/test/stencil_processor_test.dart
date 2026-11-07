import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/processing/stencil_processor.dart';

void main() {
  group('StencilProcessor flat backgrounds', () {
    test('removes a white background and keeps black ink', () {
      final Uint8List rgba = _image(20, 20, (int x, int y) {
        return x == 10 ? 0xFF000000 : 0xFFFFFFFF;
      });

      final StencilResult result = _process(
        rgba,
        20,
        20,
        mode: StencilMode.flat,
      );

      expect(result.isEmpty, isFalse);
      expect(_alphaAt(result, 2, 10), 255);
      expect(result.rgba[((10 * result.width) + 2) * 4], 0);
      expect(result.rgba[((10 * result.width) + 2) * 4 + 1], 0);
      expect(result.rgba[((10 * result.width) + 2) * 4 + 2], 0);
      expect(_alphaAt(result, 0, 0), 0);
      expect(result.width, 5);
      expect(result.height, 20);
    });

    test('turns a saturated color stroke into opaque black ink', () {
      final Uint8List rgba = _image(20, 20, (int x, int y) {
        return x == 10 ? 0xFFFF0000 : 0xFFFFFFFF;
      });

      final StencilResult result = _process(
        rgba,
        20,
        20,
        mode: StencilMode.flat,
      );

      expect(result.isEmpty, isFalse);
      expect(_alphaAt(result, 2, 10), greaterThan(200));
      expect(result.rgba[((10 * result.width) + 2) * 4], 0);
    });

    test('keeps light ink on a dark background', () {
      final Uint8List rgba = _image(20, 20, (int x, int y) {
        return x == 10 ? 0xFFFFFFFF : 0xFF000000;
      });

      final StencilResult result = _process(
        rgba,
        20,
        20,
        mode: StencilMode.flat,
        backgroundArgb: 0xFF000000,
        backgroundIsDark: true,
      );

      expect(result.isEmpty, isFalse);
      expect(_alphaAt(result, 2, 10), 255);
      expect(_alphaAt(result, 0, 0), 0);
    });
  });

  group('StencilProcessor transparency and cleanup', () {
    test('turns a colored transparent design into black ink', () {
      final Uint8List rgba = _image(10, 10, (int x, int y) {
        if (x >= 3 && x < 7 && y >= 3 && y < 7) {
          return 0xFFFF0000;
        }
        return 0x00000000;
      });

      final StencilResult result = _process(
        rgba,
        10,
        10,
        mode: StencilMode.transparent,
      );

      expect(result.isEmpty, isFalse);
      expect(result.width, 8);
      expect(result.height, 8);
      expect(_alphaAt(result, 4, 4), 255);
      expect(result.rgba[(4 * result.width + 4) * 4], 0);
    });

    test('removes isolated noise pixels', () {
      final Uint8List rgba = _image(20, 20, (int x, int y) {
        return x == 10 && y == 10 ? 0xFF000000 : 0xFFFFFFFF;
      });

      final StencilResult result = _process(
        rgba,
        20,
        20,
        mode: StencilMode.flat,
      );

      expect(result.isEmpty, isTrue);
      expect(result.removedComponents, 1);
    });

    test('keeps components larger than the noise threshold', () {
      final Uint8List rgba = _image(20, 20, (int x, int y) {
        return x >= 8 && x < 12 && y >= 8 && y < 12 ? 0xFF000000 : 0xFFFFFFFF;
      });

      final StencilResult result = _process(
        rgba,
        20,
        20,
        mode: StencilMode.flat,
      );

      expect(result.isEmpty, isFalse);
      expect(result.width, 8);
      expect(result.height, 8);
    });

    test('uses edges to avoid filling smooth AI subject interiors', () {
      final Uint8List rgba = _image(30, 30, (int x, int y) {
        if (x >= 5 && x < 25 && y >= 5 && y < 25) {
          final bool border = x < 7 || x >= 23 || y < 7 || y >= 23;
          return border ? 0xFF000000 : 0xFF808080;
        }
        return 0x00000000;
      });

      final StencilResult result = _process(rgba, 30, 30, mode: StencilMode.ai);

      expect(result.isEmpty, isFalse);
      expect(_alphaAt(result, 10, 10), 0);
      expect(_alphaAt(result, 2, 10), greaterThan(0));
    });
  });
}

StencilResult _process(
  Uint8List rgba,
  int width,
  int height, {
  required StencilMode mode,
  int backgroundArgb = 0xFFFFFFFF,
  bool backgroundIsDark = false,
}) {
  return StencilProcessor.process(
    StencilRequest(
      rgba: rgba,
      width: width,
      height: height,
      mode: mode,
      backgroundArgb: backgroundArgb,
      backgroundIsDark: backgroundIsDark,
    ),
  );
}

int _alphaAt(StencilResult result, int x, int y) {
  return result.rgba[(y * result.width + x) * 4 + 3];
}

Uint8List _image(int width, int height, int Function(int x, int y) colorAt) {
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
