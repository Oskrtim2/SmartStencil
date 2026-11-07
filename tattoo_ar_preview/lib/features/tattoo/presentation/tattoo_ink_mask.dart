import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/tattoo_gesture_controller.dart';
import '../rendering/ink_shader.dart';

class TattooInkMask extends StatelessWidget {
  const TattooInkMask({
    super.key,
    required this.composer,
    required this.image,
    required this.gestures,
    required this.opacity,
    required this.child,
  });

  final InkShaderComposer composer;
  final ui.Image image;
  final TattooGestureController gestures;
  final ValueListenable<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[gestures, opacity]),
      child: child,
      builder: (BuildContext context, Widget? camera) {
        return ShaderMask(
          blendMode: BlendMode.multiply,
          shaderCallback: (Rect bounds) {
            return composer.createShader(
              image: image,
              viewportSize: bounds.size,
              transform: gestures.transform,
              opacity: opacity.value,
            );
          },
          child: camera,
        );
      },
    );
  }
}
