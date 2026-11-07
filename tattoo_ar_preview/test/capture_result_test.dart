import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tattoo_ar_preview/features/capture/data/capture_service.dart';

void main() {
  group('CaptureResult', () {
    CaptureResult resultFor(ShareResultStatus status) {
      return CaptureResult(
        filePath: 'capture.png',
        shareResult: ShareResult('raw', status),
        source: CaptureSource.cameraStill,
      );
    }

    test('describes a successful share', () {
      expect(
        resultFor(ShareResultStatus.success).userMessage,
        'Captura compartida.',
      );
    });

    test('describes a dismissed share sheet', () {
      expect(
        resultFor(ShareResultStatus.dismissed).userMessage,
        'Captura creada, pero no se compartió.',
      );
    });

    test('describes an unavailable share result', () {
      expect(
        resultFor(ShareResultStatus.unavailable).userMessage,
        'Captura creada en la caché de SmartStencil.',
      );
    });
  });
}
