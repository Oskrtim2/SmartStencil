import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
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
  CameraSession(
    this._permissionService, {
    this.initializationTimeout = AppConstants.cameraInitializationTimeout,
  });

  final PermissionGateway _permissionService;
  final Duration initializationTimeout;

  CameraController? _controller;
  CameraStatus _status = CameraStatus.idle;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;
  Future<void>? _initializationFuture;

  CameraController? get controller => _controller;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isReady =>
      _status == CameraStatus.ready &&
      (_controller?.value.isInitialized ?? false);

  Future<void> initialize() {
    final Future<void>? existing = _initializationFuture;
    if (existing != null) {
      return existing;
    }
    final Future<void> future = _initialize();
    _initializationFuture = future;
    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initialize() async {
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
          .requestCameraAccess()
          .timeout(initializationTimeout);
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

      final List<CameraDescription> cameras = await availableCameras().timeout(
        initializationTimeout,
      );
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
      await pending.initialize().timeout(initializationTimeout);
      if (generation != _generation) {
        await pending.dispose();
        return;
      }

      await _configure(pending).timeout(initializationTimeout);
      if (generation != _generation) {
        await pending.dispose();
        return;
      }

      _controller = pending;
      pending.addListener(_onControllerChanged);
      if (pending.value.hasError) {
        _onControllerChanged();
        return;
      }
      _finish(CameraStatus.ready);
    } on TimeoutException {
      await _disposePending(pending);
      if (generation != _generation) {
        return;
      }
      _controller = null;
      _finish(
        CameraStatus.failure,
        'La cámara tardó demasiado en responder. Cierra otras apps que '
        'puedan estar usándola y vuelve a intentarlo.',
      );
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

  void _onControllerChanged() {
    final CameraController? controller = _controller;
    if (_disposed || controller == null || !controller.value.hasError) {
      return;
    }
    _generation++;
    _controller = null;
    _status = CameraStatus.failure;
    _errorMessage =
        controller.value.errorDescription ??
        'La cámara dejó de responder. Inténtalo de nuevo.';
    _notify();
    unawaited(_disposeController(controller));
  }

  Future<void> _disposeController(CameraController controller) async {
    controller.removeListener(_onControllerChanged);
    try {
      await controller.dispose();
    } catch (_) {
      return;
    }
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
    _initializationFuture = null;
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
        await _disposeController(controller);
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
    await _disposeController(controller);
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
    _initializationFuture = null;
    _generation++;
    final CameraController? controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_disposeController(controller));
    }
    super.dispose();
  }
}
