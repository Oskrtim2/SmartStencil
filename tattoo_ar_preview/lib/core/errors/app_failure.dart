sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;

  @override
  String toString() => '$runtimeType: $message';
}

final class CameraPermissionFailure extends AppFailure {
  const CameraPermissionFailure(
    String message, {
    bool canOpenSettings = false,
  }) : super(message, canOpenSettings: canOpenSettings);
}

final class TattooImportFailure extends AppFailure {
  const TattooImportFailure(
    String message, {
    bool canOpenSettings = false,
  }) : super(message, canOpenSettings: canOpenSettings);
}

final class CaptureFailure extends AppFailure {
  const CaptureFailure(String message) : super(message);
}
