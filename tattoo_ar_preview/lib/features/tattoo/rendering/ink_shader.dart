import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../../core/constants/app_constants.dart';
import '../domain/tattoo_transform.dart';

class InkShaderComposer {
  const InkShaderComposer({required this.program});

  static const double baseSizeFraction = AppConstants.inkBaseSizeFraction;

  final ui.FragmentProgram program;

  ui.FragmentShader createShader({
    required ui.Image image,
    required ui.Size viewportSize,
    required TattooTransform transform,
    required double opacity,
  }) {
    final ui.Size tattooSize = baseSizeFor(image, viewportSize);
    final ui.FragmentShader shader = program.fragmentShader();
    shader
        .getUniformFloat('uCenter', 0)
        .set(viewportSize.width * (0.5 + transform.translation.dx));
    shader
        .getUniformFloat('uCenter', 1)
        .set(viewportSize.height * (0.5 + transform.translation.dy));
    shader
        .getUniformFloat('uTattooSize', 0)
        .set(math.max(tattooSize.width, 1).toDouble());
    shader
        .getUniformFloat('uTattooSize', 1)
        .set(math.max(tattooSize.height, 1).toDouble());
    shader.getUniformFloat('uScale').set(transform.scale);
    shader.getUniformFloat('uRotation').set(transform.rotation);
    shader.getUniformFloat('uOpacity').set(opacity.clamp(0.0, 1.0).toDouble());
    shader.getImageSampler('uTexture').set(image);
    return shader;
  }

  void paintInk({
    required ui.Canvas canvas,
    required ui.Size size,
    required ui.Image image,
    required TattooTransform transform,
    required double opacity,
  }) {
    if (size.isEmpty || opacity <= 0) {
      return;
    }
    final ui.FragmentShader shader = createShader(
      image: image,
      viewportSize: size,
      transform: transform,
      opacity: opacity,
    );
    final ui.Paint paint = ui.Paint()
      ..shader = shader
      ..blendMode = ui.BlendMode.multiply
      ..isAntiAlias = true;
    canvas.drawRect(ui.Offset.zero & size, paint);
  }

  static ui.Size baseSizeFor(ui.Image image, ui.Size viewportSize) {
    if (viewportSize.isEmpty || image.width == 0 || image.height == 0) {
      return ui.Size.zero;
    }
    final double reference =
        math.min(viewportSize.width, viewportSize.height) * baseSizeFraction;
    final double imageAspect = image.width / image.height;
    if (imageAspect >= 1) {
      return ui.Size(reference, reference / imageAspect);
    }
    return ui.Size(reference * imageAspect, reference);
  }
}
