import 'dart:typed_data';

class PngMetadata {
  const PngMetadata({
    required this.width,
    required this.height,
    required this.colorType,
    required this.hasTransparencyChunk,
    required this.byteLength,
  });

  static const List<int> signatureBytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  final int width;
  final int height;
  final int colorType;
  final bool hasTransparencyChunk;
  final int byteLength;

  int get pixelCount => width * height;

  bool exceedsPixelBudget(int maxPixels) => pixelCount > maxPixels;

  bool get hasAlphaChannel => colorType == 4 || colorType == 6;

  bool get canContainTransparency => hasAlphaChannel || hasTransparencyChunk;

  static bool hasPngSignature(Uint8List bytes) {
    if (bytes.length < signatureBytes.length) {
      return false;
    }
    for (int index = 0; index < signatureBytes.length; index++) {
      if (bytes[index] != signatureBytes[index]) {
        return false;
      }
    }
    return true;
  }

  static PngMetadata? tryParse(Uint8List bytes) {
    if (bytes.length < 33 || !hasPngSignature(bytes)) {
      return null;
    }
    final ByteData data = ByteData.sublistView(bytes);
    if (data.getUint32(8, Endian.big) != 13) {
      return null;
    }
    if (String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
      return null;
    }
    final int width = data.getUint32(16, Endian.big);
    final int height = data.getUint32(20, Endian.big);
    if (width == 0 || height == 0) {
      return null;
    }
    return PngMetadata(
      width: width,
      height: height,
      colorType: bytes[25],
      hasTransparencyChunk: _hasTransparencyChunk(bytes),
      byteLength: bytes.length,
    );
  }

  static bool _hasTransparencyChunk(Uint8List bytes) {
    if (bytes.length < 8) {
      return false;
    }
    final ByteData data = ByteData.sublistView(bytes);
    int offset = 8;
    while (offset + 12 <= bytes.length) {
      final int remaining = bytes.length - offset - 12;
      final int chunkLength = data.getUint32(offset, Endian.big);
      if (chunkLength > remaining) {
        return false;
      }
      final int typeOffset = offset + 4;
      final String type = String.fromCharCodes(
        bytes.sublist(typeOffset, typeOffset + 4),
      );
      if (type == 'tRNS') {
        return true;
      }
      if (type == 'IDAT') {
        return false;
      }
      offset += 12 + chunkLength;
    }
    return false;
  }
}
