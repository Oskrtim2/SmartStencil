import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/permissions/permission_service.dart';

enum CameraStatus {
  idle,
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  failure,
}

class CameraSession extends ChangeNotifier {
  CameraSession(this._permissionService);

  final PermissionGateway _permissionService;

  CameraController? _controller;
  CameraStatus _status = CameraStatus.idle;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  CameraController? get controller => _controller;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isReady =>
      _status == CameraStatus.ready &&
      (_controller?.value.isInitialized ?? false);

  Future<void> initialize() async {
    if (_disposed ||
        _status == CameraStatus.initializing ||
        (_status == CameraStatus.ready && isReady)) {
      return;
    }

    final int generation = ++_generation;
    _status = CameraStatus.initializing;
    _errorMessage = null;
    _notify();

    CameraController? pending;
    try {
      final PermissionDecision decision = await _permissionService
          .requestCameraAccess();
      if (generation != _generation) {
        return;
      }
      if (decision == PermissionDecision.denied) {
        _finish(CameraStatus.permissionDenied);
        return;
      }
      if (decision == PermissionDecision.permanentlyDenied) {
        _finish(CameraStatus.permissionPermanentlyDenied);
        return;
      }

      final List<CameraDescription> cameras = await availableCameras();
      if (generation != _generation) {
        return;
      }
      if (cameras.isEmpty) {
        _finish(
          CameraStatus.unavailable,
          'No se encontró ninguna cámara disponible en este dispositivo.',
        );
        return;
      }

      final CameraDescription description = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      pending = CameraController(
        description,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await pending.initialize();
      if (generation != _generation) {
        await pending.dispose();
        return;
      }

      await _configure(pending);
      if (generation != _generation) {
        await pending.dispose();
        return;
      }

      _controller = pending;
      _finish(CameraStatus.ready);
    } on CameraException catch (error) {
      await _disposePending(pending);
      if (generation != _generation) {
        return;
      }
      _controller = null;
      _finish(CameraStatus.failure, _cameraErrorMessage(error));
    } catch (_) {
      await _disposePending(pending);
      if (generation != _generation) {
        return;
      }
      _controller = null;
      _finish(
        CameraStatus.failure,
        'No se pudo iniciar la cámara. Comprueba que no esté en uso por '
        'otra aplicación.',
      );
    }
  }

  Future<void> _configure(CameraController controller) async {
    await _trySetting(() => controller.setFocusMode(FocusMode.auto));
    await _trySetting(() => controller.setExposureMode(ExposureMode.auto));
    await _trySetting(() => controller.setFlashMode(FlashMode.off));
    await _trySetting(() async {
      if (await controller.isZeroShutterLagSupported()) {
        await controller.setZeroShutterLagEnabled(true);
      }
    });
  }

  Future<void> _trySetting(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      return;
    }
  }

  Future<void> suspend() async {
    _generation++;
    final CameraController? controller = _controller;
    _controller = null;
    if (_status == CameraStatus.ready ||
        _status == CameraStatus.initializing ||
        _status == CameraStatus.idle) {
      _status = CameraStatus.idle;
      _errorMessage = null;
    }
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        _controller = null;
      }
    }
    _notify();
  }

  Future<bool> openSettings() => _permissionService.openSettings();

  void _finish(CameraStatus status, [String? message]) {
    if (_disposed) {
      return;
    }
    _status = status;
    _errorMessage = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _disposePending(CameraController? controller) async {
    if (controller == null || identical(controller, _controller)) {
      return;
    }
    try {
      await controller.dispose();
    } catch (_) {
      return;
    }
  }

  String _cameraErrorMessage(CameraException error) {
    final String code = error.code.toLowerCase();
    final String message = (error.description ?? '').toLowerCase();
    if (code.contains('permission')) {
      return 'La cámara necesita permiso para funcionar.';
    }
    if (code.contains('inuse') || message.contains('in use')) {
      return 'La cámara está siendo usada por otra aplicación.';
    }
    return 'No se pudo iniciar la cámara (${error.code}).';
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    final CameraController? controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }
}
