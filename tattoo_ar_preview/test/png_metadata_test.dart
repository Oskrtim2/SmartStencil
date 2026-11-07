import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/domain/png_metadata.dart';

void main() {
  group('PngMetadata', () {
    test('parses IHDR dimensions and color type', () {
      final PngMetadata? metadata = PngMetadata.tryParse(
        buildPng(width: 640, height: 480, colorType: 6),
      );

      expect(metadata, isNotNull);
      expect(metadata!.width, 640);
      expect(metadata.height, 480);
      expect(metadata.colorType, 6);
      expect(metadata.hasAlphaChannel, isTrue);
      expect(metadata.pixelCount, 640 * 480);
    });

    test('detects a tRNS chunk before IDAT', () {
      final PngMetadata? metadata = PngMetadata.tryParse(
        buildPng(colorType: 2, transparencyChunk: true),
      );

      expect(metadata, isNotNull);
      expect(metadata!.hasAlphaChannel, isFalse);
      expect(metadata.hasTransparencyChunk, isTrue);
      expect(metadata.canContainTransparency, isTrue);
    });

    test('ignores a tRNS chunk after IDAT', () {
      final PngMetadata? metadata = PngMetadata.tryParse(
        buildPng(colorType: 2, transparencyChunk: false),
      );

      expect(metadata, isNotNull);
      expect(metadata!.canContainTransparency, isFalse);
    });

    test('rejects malformed signatures and zero dimensions', () {
      expect(PngMetadata.tryParse(Uint8List.fromList(<int>[1, 2, 3])), isNull);
      expect(PngMetadata.tryParse(buildPng(width: 0, height: 10)), isNull);
    });

    test('rejects chunks whose declared length exceeds the file', () {
      final Uint8List bytes = buildPng();
      final ByteData view = ByteData.sublistView(bytes);
      view.setUint32(8, 100000, Endian.big);

      expect(PngMetadata.tryParse(bytes), isNull);
    });
  });
}

Uint8List buildPng({
  int width = 100,
  int height = 100,
  int colorType = 6,
  bool transparencyChunk = false,
}) {
  final BytesBuilder builder = BytesBuilder();
  builder.add(PngMetadata.signatureBytes);
  _appendChunk(builder, 'IHDR', <int>[
    ..._uint32(width),
    ..._uint32(height),
    8,
    colorType,
    0,
    0,
    0,
  ]);
  if (transparencyChunk) {
    _appendChunk(builder, 'tRNS', <int>[0]);
  }
  _appendChunk(builder, 'IDAT', <int>[0]);
  _appendChunk(builder, 'IEND', const <int>[]);
  return builder.takeBytes();
}

void _appendChunk(BytesBuilder builder, String type, List<int> data) {
  builder.add(_uint32(data.length));
  builder.add(type.codeUnits);
  builder.add(data);
  builder.add(const <int>[0, 0, 0, 0]);
}

List<int> _uint32(int value) {
  return <int>[
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}
