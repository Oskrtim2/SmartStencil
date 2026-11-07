sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;

  @override
  String toString() => '$runtimeType: $message';
}

final class TattooImportFailure extends AppFailure {
  const TattooImportFailure(super.message, {super.canOpenSettings});
}

final class CaptureFailure extends AppFailure {
  const CaptureFailure(super.message);
}

final class StencilExportFailure extends AppFailure {
  const StencilExportFailure(super.message);
}
