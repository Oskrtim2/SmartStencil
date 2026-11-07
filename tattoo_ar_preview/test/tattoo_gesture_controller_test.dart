import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/domain/tattoo_gesture_controller.dart';

void main() {
  group('TattooGestureController', () {
    test('translates the tattoo in normalized viewport units', () {
      final TattooGestureController controller = TattooGestureController()
        ..updateViewport(const Size(200, 400));

      controller.onScaleStart(
        ScaleStartDetails(localFocalPoint: const Offset(100, 200)),
      );
      controller.onScaleUpdate(
        ScaleUpdateDetails(
          localFocalPoint: const Offset(150, 100),
          scale: 1,
          rotation: 0,
        ),
      );

      expect(controller.transform.translation.dx, closeTo(0.25, 1e-9));
      expect(controller.transform.translation.dy, closeTo(-0.25, 1e-9));
      expect(controller.transform.scale, 1);
      controller.dispose();
    });

    test('applies pinch scale and two-finger twist', () {
      final TattooGestureController controller = TattooGestureController()
        ..updateViewport(const Size(100, 100));

      controller.onScaleStart(
        ScaleStartDetails(localFocalPoint: const Offset(50, 50)),
      );
      controller.onScaleUpdate(
        ScaleUpdateDetails(
          localFocalPoint: const Offset(50, 50),
          scale: 2.5,
          rotation: 0.4,
        ),
      );

      expect(controller.transform.scale, closeTo(2.5, 1e-9));
      expect(controller.transform.rotation, closeTo(0.4, 1e-9));
      expect(controller.transform.translation, Offset.zero);
      controller.dispose();
    });

    test('reset returns to the identity transform', () {
      final TattooGestureController controller = TattooGestureController()
        ..updateViewport(const Size(100, 100));

      controller.onScaleStart(
        ScaleStartDetails(localFocalPoint: const Offset(50, 50)),
      );
      controller.onScaleUpdate(
        ScaleUpdateDetails(
          localFocalPoint: const Offset(80, 60),
          scale: 2,
          rotation: 0.5,
        ),
      );
      controller.reset();

      expect(controller.transform.translation, Offset.zero);
      expect(controller.transform.scale, 1);
      expect(controller.transform.rotation, 0);
      controller.dispose();
    });
  });
}
