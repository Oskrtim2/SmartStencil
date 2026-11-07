import 'dart:typed_data';

abstract final class AlphaValidator {
  static const int transparentThreshold = 250;

  static bool hasTransparentPixel(Uint8List rgbaBytes) {
    for (int index = 3; index < rgbaBytes.length; index += 4) {
      if (rgbaBytes[index] < transparentThreshold) {
        return true;
      }
    }
    return false;
  }
}
