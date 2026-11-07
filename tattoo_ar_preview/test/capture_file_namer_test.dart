import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/core/constants/app_constants.dart';
import 'package:tattoo_ar_preview/features/capture/domain/capture_file_namer.dart';

void main() {
  group('CaptureFileNamer', () {
    test('produces unique names even within the same microsecond', () {
      final CaptureFileNamer namer = CaptureFileNamer(
        clock: () => DateTime.fromMicrosecondsSinceEpoch(123456789),
      );

      final String first = namer.next();
      final String second = namer.next();

      expect(first, isNot(second));
      expect(first, startsWith(AppConstants.capturesFilePrefix));
      expect(first, endsWith('.png'));
      expect(second, endsWith('_1.png'));
    });

    test('includes the timestamp supplied by the clock', () {
      final CaptureFileNamer namer = CaptureFileNamer(
        clock: () => DateTime.fromMicrosecondsSinceEpoch(42),
      );

      expect(namer.next(), '${AppConstants.capturesFilePrefix}42_0.png');
    });
  });
}
