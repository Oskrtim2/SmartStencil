import 'dart:math' as math;
import 'dart:ui' as ui;

import '../domain/tattoo_transform.dart';

class InkShaderComposer {
  const InkShaderComposer({required this.program});

  static const double baseSizeFraction = 0.62;

  final ui.FragmentProgram program;

  ui.FragmentShader createShader({
    required ui.Image image,
    required ui.Size viewportSize,
    required TattooTransform transform,
    required double opacity,
  }) {
    final ui.Size tattooSize = baseSizeFor(image, viewportSize);
    final ui.FragmentShader shader = program.fragmentShader();
    shader.setFloat(0, viewportSize.width * (0.5 + transform.translation.dx));
    shader.setFloat(1, viewportSize.height * (0.5 + transform.translation.dy));
    shader.setFloat(2, math.max(tattooSize.width, 1));
    shader.setFloat(3, math.max(tattooSize.height, 1));
    shader.setFloat(4, transform.scale);
    shader.setFloat(5, transform.rotation);
    shader.setFloat(6, opacity.clamp(0.0, 1.0));
    shader.setImageSampler(0, image);
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
