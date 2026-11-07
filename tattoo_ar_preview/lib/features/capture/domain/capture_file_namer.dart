import '../../../core/constants/app_constants.dart';

class CaptureFileNamer {
  CaptureFileNamer({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  int _sequence = 0;

  String next() {
    final int timestamp = _clock().microsecondsSinceEpoch;
    final int sequence = _sequence++;
    return '${AppConstants.capturesFilePrefix}${timestamp}_$sequence.png';
  }
}
