import '../../../core/errors/app_failure.dart';

class CaptureGuard {
  bool _busy = false;

  bool get isBusy => _busy;

  Future<T> run<T>(Future<T> Function() action) {
    if (_busy) {
      return Future<T>.error(
        const CaptureFailure('Ya hay una captura en curso.'),
      );
    }
    _busy = true;
    try {
      return action().whenComplete(() => _busy = false);
    } catch (error, stackTrace) {
      _busy = false;
      return Future<T>.error(error, stackTrace);
    }
  }
}
