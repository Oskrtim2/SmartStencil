import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/ar/ar_session_controller.dart';

/// The AR viewport widget that renders the camera feed composited with
/// the tattoo design using the multiply-blend fragment shader.
///
/// This widget is rebuilt on every [ArSessionController] notification
/// (i.e., every gesture update or tracking refinement).
///
/// The actual compositing is done by [_TattooShaderPainter] using
/// Flutter's [FragmentProgram] API to run the GLSL shader.
class ArViewport extends StatefulWidget {
  final ArSessionController controller;

  const ArViewport({
    super.key,
    required this.controller,
  });

  @override
  State<ArViewport> createState() => _ArViewportState();
}

class _ArViewportState extends State<ArViewport> {
  ui.FragmentProgram? _shaderProgram;
  ui.FragmentShader? _shader;
  bool _shaderLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _shaderProgram = await ui.FragmentProgram.fromAsset(
        'shaders/multiply_blend.frag',
      );
      _shader = _shaderProgram!.fragmentShader();
      if (mounted) {
        setState(() => _shaderLoaded = true);
      }
    } catch (e) {
      debugPrint('Failed to load fragment shader: $e');
      // Fallback: render without shader (basic opacity overlay)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ClipRect(
        child: CustomPaint(
          painter: _TattooShaderPainter(
            controller: widget.controller,
            shader: _shader,
            shaderLoaded: _shaderLoaded,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }
}

/// Custom painter that composites the tattoo overlay onto the camera feed.
///
/// When the fragment shader is available:
///   Uses the multiply-blend GLSL shader with all uniforms set from the
///   session controller state (opacity, UV transform, textures).
///
/// Fallback (shader unavailable):
///   Uses [BlendMode.multiply] via Canvas paint, which is less accurate
///   but functional on devices without shader support.
class _TattooShaderPainter extends CustomPainter {
  final ArSessionController controller;
  final ui.FragmentShader? shader;
  final bool shaderLoaded;

  _TattooShaderPainter({
    required this.controller,
    required this.shader,
    required this.shaderLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.hasTattoo) return;

    final tattooImage = controller.tattooImage!;

    if (shaderLoaded && shader != null) {
      _paintWithShader(canvas, size, tattooImage);
    } else {
      _paintFallback(canvas, size, tattooImage);
    }
  }

  void _paintWithShader(Canvas canvas, Size size, ui.Image tattoo) {
    final s = shader!;

    // Set uniforms matching the GLSL declarations
    // uniform vec2 uResolution (index 0, 1)
    s.setFloat(0, size.width);
    s.setFloat(1, size.height);

    // uniform float uOpacity (index 2)
    s.setFloat(2, controller.opacity);

    // uniform mat3 uUvTransform (index 3..11 — 9 floats row-major)
    final uvMatrix = controller.uvTransformMatrix;
    for (var i = 0; i < 9; i++) {
      s.setFloat(3 + i, uvMatrix.storage[i]);
    }

    // uniform vec2 uTattooSize (index 12, 13)
    s.setFloat(12, tattoo.width.toDouble());
    s.setFloat(13, tattoo.height.toDouble());

    // uniform float uEdgeSoftness (index 14)
    s.setFloat(14, controller.edgeSoftness);

    // uniform sampler2D uTattooTex (sampler index 0)
    s.setImageSampler(0, tattoo);

    // Draw full-screen quad with the shader
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = s,
    );
  }

  /// Fallback: basic multiply blend without custom shader.
  void _paintFallback(Canvas canvas, Size size, ui.Image tattoo) {
    final scale = controller.scale;
    final rotation = controller.rotation;
    final translation = controller.translation;

    // Calculate destination rect centered on screen + gesture transform
    final tattooAspect = tattoo.width / tattoo.height;
    final displayHeight = size.height * 0.4 * scale;
    final displayWidth = displayHeight * tattooAspect;

    canvas.save();

    // Translate to center + gesture offset
    canvas.translate(
      size.width / 2 + translation.x * size.width,
      size.height / 2 + translation.y * size.height,
    );

    // Rotate
    canvas.rotate(rotation);

    // Source and destination rectangles
    final src = Rect.fromLTWH(
      0, 0,
      tattoo.width.toDouble(),
      tattoo.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: displayWidth,
      height: displayHeight,
    );

    // Draw with multiply blend mode and opacity
    final paint = Paint()
      ..blendMode = BlendMode.multiply
      ..color = Color.fromRGBO(255, 255, 255, controller.opacity)
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(tattoo, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TattooShaderPainter oldDelegate) {
    // Repaint on any controller state change
    return true;
  }
}
