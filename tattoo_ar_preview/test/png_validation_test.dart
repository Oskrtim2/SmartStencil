import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/data/tattoo_repository.dart';

void main() {
  group('TattooRepository.hasPngSignature', () {
    test('accepts a valid PNG signature', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0,
        0,
      ]);

      expect(TattooRepository.hasPngSignature(bytes), isTrue);
    });

    test('rejects JPEG data', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
      ]);

      expect(TattooRepository.hasPngSignature(bytes), isFalse);
    });

    test('rejects truncated data', () {
      expect(
        TattooRepository.hasPngSignature(
          Uint8List.fromList(<int>[0x89, 0x50, 0x4E]),
        ),
        isFalse,
      );
    });
  });
}
