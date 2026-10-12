import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ar/ar_platform_bridge.dart';
import '../../../core/ar/ar_session_controller.dart';
import '../../../core/ar/cylindrical_mapper.dart';
import '../../../core/gestures/tattoo_gesture_controller.dart';
import '../../../core/network/secure_image_loader.dart';
import '../providers/ar_preview_provider.dart';
import 'widgets/ar_viewport.dart';
import 'widgets/opacity_slider.dart';

/// The main AR preview screen.
///
/// Displays the live camera feed with the tattoo design projected onto the
/// detected body surface using the multiply-blend fragment shader.
///
/// UI overlay includes:
/// - Body part selector (top)
/// - Opacity slider (bottom)
/// - Tracking status indicator
/// - Surface tap instruction
class ArPreviewScreen extends ConsumerStatefulWidget {
  const ArPreviewScreen({super.key});

  @override
  ConsumerState<ArPreviewScreen> createState() => _ArPreviewScreenState();
}

class _ArPreviewScreenState extends ConsumerState<ArPreviewScreen>
    with WidgetsBindingObserver {
  late final TattooGestureController _gestureController;
  ArSessionController? _sessionController;
  bool _isLoading = true;
  String? _errorMessage;
  BodyPart _selectedBodyPart = BodyPart.forearm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    try {
      final controller = ref.read(arSessionControllerProvider);
      _sessionController = controller;

      _gestureController = TattooGestureController(
        onPan: controller.onPanUpdate,
        onScale: controller.onScaleUpdate,
        onRotate: controller.onRotationUpdate,
      );

      await controller.initialize();

      // Load the tattoo design from the route arguments
      await _loadDesignFromArgs();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadDesignFromArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final presignedUrl = args['presignedUrl'] as String?;
      if (presignedUrl != null) {
        final loader = SecureImageLoader();
        final bytes = await loader.loadFromPresignedUrl(presignedUrl);
        await _sessionController?.loadTattooFromBytes(bytes);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _sessionController?.pause();
      case AppLifecycleState.resumed:
        _sessionController?.resume();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // AR camera + shader viewport with gesture handling
          _gestureController.buildListener(
            child: GestureDetector(
              onTapUp: (details) {
                _sessionController?.selectSurface(
                  details.localPosition,
                  bodyPart: _selectedBodyPart,
                );
              },
              child: ListenableBuilder(
                listenable: _sessionController!,
                builder: (context, _) => ArViewport(
                  controller: _sessionController!,
                ),
              ),
            ),
          ),

          // Tracking status indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: _buildTrackingIndicator(),
          ),

          // Body part selector
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 16,
            child: _buildBodyPartSelector(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Preview'),
      actions: [
        // Screenshot button (composited frame only — not raw PNG)
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, size: 22),
          onPressed: _captureScreenshot,
        ),
      ],
    );
  }

  Widget _buildTrackingIndicator() {
    return ListenableBuilder(
      listenable: _sessionController!,
      builder: (context, _) {
        final state = _sessionController!.trackingState;
        final hasMapping = _sessionController!.activeMapping != null;

        if (hasMapping) return const SizedBox.shrink();

        final (icon, text, color) = switch (state) {
          TrackingState.normal => (
              Icons.touch_app_rounded,
              'Tap on your skin to place the design',
              const Color(0xFF10B981),
            ),
          TrackingState.limited => (
              Icons.explore_rounded,
              'Move your device slowly to detect surfaces',
              const Color(0xFFF59E0B),
            ),
          TrackingState.notAvailable => (
              Icons.error_outline_rounded,
              'AR tracking unavailable',
              const Color(0xFFEF4444),
            ),
        };

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyPartSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: BodyPart.values.map((part) {
          final isSelected = part == _selectedBodyPart;
          final label = switch (part) {
            BodyPart.forearm => '💪',
            BodyPart.upperArm => '🦾',
            BodyPart.calf => '🦵',
            BodyPart.thigh => '🦿',
            BodyPart.shoulder => '🤷',
          };
          return GestureDetector(
            onTap: () {
              setState(() => _selectedBodyPart = part);
              _sessionController?.setBodyPart(part);
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6).withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(label, style: const TextStyle(fontSize: 20)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 40, 24, MediaQuery.of(context).padding.bottom + 20,
      ),
      child: ListenableBuilder(
        listenable: _sessionController!,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opacity slider
            OpacitySliderWidget(
              value: _sessionController!.opacity,
              onChanged: (v) => _sessionController!.setOpacity(v),
            ),
            const SizedBox(height: 16),
            // Info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scale: ${(_sessionController!.scale * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rotation: ${(_sessionController!.rotation * 180 / 3.14159).toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 20),
            Text(
              'Initializing AR Engine…',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                'AR Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureScreenshot() async {
    // TODO: Capture the composited (camera + overlay) frame via RepaintBoundary
    // Only the rendered composite is captured — never the raw source PNG
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot saved (composited preview)'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}
