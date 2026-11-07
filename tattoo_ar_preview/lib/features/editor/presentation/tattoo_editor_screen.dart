import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../camera/data/camera_session.dart';
import '../../camera/presentation/camera_status_view.dart';
import '../../camera/presentation/camera_viewfinder.dart';
import '../../capture/data/capture_service.dart';
import '../../tattoo/data/tattoo_repository.dart';
import '../../tattoo/domain/tattoo_gesture_controller.dart';
import '../../tattoo/presentation/tattoo_ink_mask.dart';
import '../../tattoo/rendering/ink_shader.dart';
import 'widgets/editor_top_bar.dart';
import 'widgets/ink_controls.dart';

class TattooEditorScreen extends StatefulWidget {
  const TattooEditorScreen({super.key, required this.inkProgram});

  final ui.FragmentProgram inkProgram;

  @override
  State<TattooEditorScreen> createState() => _TattooEditorScreenState();
}

class _TattooEditorScreenState extends State<TattooEditorScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final PermissionService _permissionService;
  late final CameraSession _cameraSession;
  late final TattooRepository _tattooRepository;
  late final CaptureService _captureService;
  late final InkShaderComposer _inkComposer;
  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;
  late final AnimationController _focusController;
  late final Animation<double> _focusScale;
  late final Animation<double> _focusFade;

  final TattooGestureController _gestures = TattooGestureController();
  final ValueNotifier<double> _opacity = ValueNotifier<double>(0.82);
  final GlobalKey _previewKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();

  TattooDesign? _design;
  bool _isPicking = false;
  bool _isCapturing = false;
  Size _viewportSize = Size.zero;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    _permissionService = const PermissionService();
    _cameraSession = CameraSession(_permissionService);
    _tattooRepository = TattooRepository();
    _captureService = CaptureService();
    _inkComposer = InkShaderComposer(program: widget.inkProgram);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _flashAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.9,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 3,
      ),
    ]).animate(_flashController);

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _focusScale = Tween<double>(begin: 1.5, end: 1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );
    _focusFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _focusController,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_cameraSession.initialize());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_cameraSession.initialize());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_cameraSession.suspend());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSession.dispose();
    _design?.dispose();
    _opacity.dispose();
    _gestures.dispose();
    _flashController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: !_isCapturing,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ListenableBuilder(
                listenable: _cameraSession,
                builder: (BuildContext context, Widget? child) => _buildStage(),
              ),
              AnimatedOpacity(
                opacity: _isCapturing ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: _isCapturing,
                  child: _buildChrome(),
                ),
              ),
              if (_isCapturing) const _CaptureProgressOverlay(),
              IgnorePointer(
                child: FadeTransition(
                  opacity: _flashAnimation,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        _viewportSize = size;
        _gestures.updateViewport(size);

        final CameraController? controller = _cameraSession.controller;
        if (!_cameraSession.isReady || controller == null) {
          return CameraStatusView(
            session: _cameraSession,
            onRetry: () => unawaited(_cameraSession.initialize()),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          onTapUp: _handleTapFocus,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              RepaintBoundary(
                key: _previewKey,
                child: _buildCompositePreview(controller),
              ),
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 34,
                  top: _focusPoint!.dy - 34,
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _focusFade,
                      child: ScaleTransition(
                        scale: _focusScale,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompositePreview(CameraController controller) {
    final Widget camera = CameraViewfinder(controller: controller);
    final TattooDesign? design = _design;
    if (design == null) {
      return camera;
    }
    return TattooInkMask(
      composer: _inkComposer,
      image: design.image,
      gestures: _gestures,
      opacity: _opacity,
      child: camera,
    );
  }

  Widget _buildChrome() {
    final bool ready = _cameraSession.isReady;
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: EditorTopBar(
            canReset: _design != null,
            onReset: _resetTransform,
          ),
        ),
        if (ready)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: InkControls(
              opacity: _opacity,
              hasDesign: _design != null,
              isPicking: _isPicking,
              isCapturing: _isCapturing,
              canCapture: ready && _design != null,
              onOpacityChanged: (double value) => _opacity.value = value,
              onPick: _importDesign,
              onCapture: _capture,
            ),
          ),
      ],
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isCapturing) {
      return;
    }
    _gestures.onScaleStart(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isCapturing) {
      return;
    }
    _gestures.onScaleUpdate(details);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isCapturing) {
      return;
    }
  }

  Future<void> _handleTapFocus(TapUpDetails details) async {
    if (_isCapturing || _design == null) {
      return;
    }
    final CameraController? controller = _cameraSession.controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final Size viewport = _viewportSize;
    if (viewport.isEmpty) {
      return;
    }

    final double x = (details.localPosition.dx / viewport.width).clamp(
      0.0,
      1.0,
    );
    final double y = (details.localPosition.dy / viewport.height).clamp(
      0.0,
      1.0,
    );
    setState(() => _focusPoint = details.localPosition);
    _focusController.forward(from: 0);

    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(Offset(x, y));
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(Offset(x, y));
      }
    } catch (_) {
      return;
    }
  }

  void _resetTransform() {
    _gestures.reset();
    HapticFeedback.selectionClick();
  }

  Future<void> _importDesign() async {
    if (_isPicking || _isCapturing) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      await _permissionService.requestGalleryAccessIfNeeded();
      final TattooDesign? design = await _tattooRepository.pickTransparentPng();
      if (!mounted) {
        design?.dispose();
        return;
      }
      if (design == null) {
        return;
      }

      final TattooDesign? previous = _design;
      setState(() => _design = design);
      _gestures.reset();
      HapticFeedback.selectionClick();
      _showMessage('Diseño importado correctamente.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous?.dispose();
      });
    } on TattooImportFailure catch (failure) {
      if (!mounted) {
        return;
      }
      _showMessage(
        failure.message,
        action: failure.canOpenSettings
            ? SnackBarAction(
                label: 'Ajustes',
                onPressed: () {
                  unawaited(_permissionService.openSettings());
                },
              )
            : null,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('No se pudo importar el diseño. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _capture() async {
    final TattooDesign? design = _design;
    final CameraController? controller = _cameraSession.controller;
    if (_isCapturing ||
        design == null ||
        controller == null ||
        !_cameraSession.isReady) {
      return;
    }

    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final Rect shareOrigin = _shareOrigin();

    HapticFeedback.mediumImpact();
    _focusController.reset();
    setState(() {
      _isCapturing = true;
      _focusPoint = null;
    });
    _flashController.forward(from: 0);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final CaptureResult result = await _captureService.captureAndShare(
        camera: controller,
        previewKey: _previewKey,
        tattooImage: design.image,
        transform: _gestures.transform,
        opacity: _opacity.value,
        viewportSize: _viewportSize,
        composer: _inkComposer,
        devicePixelRatio: devicePixelRatio,
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted) {
        return;
      }
      _showMessage(result.userMessage);
    } on CaptureFailure catch (failure) {
      if (!mounted) {
        return;
      }
      _showMessage(
        failure.message,
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () {
            unawaited(_capture());
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        'Ocurrió un error inesperado al capturar. Inténtalo de nuevo.',
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () {
            unawaited(_capture());
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Rect _shareOrigin() {
    final RenderObject? renderObject = _scaffoldKey.currentContext
        ?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    final Size screen = MediaQuery.sizeOf(context);
    return Rect.fromLTWH(0, 0, screen.width, screen.height);
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}

class _CaptureProgressOverlay extends StatelessWidget {
  const _CaptureProgressOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 14),
              Text(
                'Preparando captura…',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
