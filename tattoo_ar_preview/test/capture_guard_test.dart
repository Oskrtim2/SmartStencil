import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/core/errors/app_failure.dart';
import 'package:tattoo_ar_preview/features/capture/domain/capture_guard.dart';

void main() {
  group('CaptureGuard', () {
    test('rejects a second capture while the first is running', () async {
      final CaptureGuard guard = CaptureGuard();
      final Completer<int> completer = Completer<int>();
      final Future<int> first = guard.run(() => completer.future);

      expect(guard.isBusy, isTrue);
      await expectLater(
        guard.run<int>(() async => 2),
        throwsA(isA<CaptureFailure>()),
      );

      completer.complete(1);
      expect(await first, 1);
      expect(guard.isBusy, isFalse);
      expect(await guard.run<int>(() async => 3), 3);
    });

    test('clears the busy flag after a synchronous failure', () async {
      final CaptureGuard guard = CaptureGuard();

      await expectLater(
        guard.run<int>(() => throw StateError('boom')),
        throwsStateError,
      );

      expect(guard.isBusy, isFalse);
    });
  });
}
