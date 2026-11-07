import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/features/tattoo/rendering/ink_shader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InkShaderComposer.baseSizeFor', () {
    test('fits wide designs by width', () async {
      final ui.Image image = await _createImage(200, 100);
      final ui.Size size = InkShaderComposer.baseSizeFor(
        image,
        const ui.Size(100, 100),
      );

      expect(size.width, closeTo(62, 1e-9));
      expect(size.height, closeTo(31, 1e-9));
      expect(size.width / size.height, closeTo(2, 1e-9));
      image.dispose();
    });

    test('fits tall designs by height', () async {
      final ui.Image image = await _createImage(100, 200);
      final ui.Size size = InkShaderComposer.baseSizeFor(
        image,
        const ui.Size(100, 100),
      );

      expect(size.width, closeTo(31, 1e-9));
      expect(size.height, closeTo(62, 1e-9));
      image.dispose();
    });

    test('returns zero for an empty viewport', () async {
      final ui.Image image = await _createImage(10, 10);

      expect(InkShaderComposer.baseSizeFor(image, ui.Size.zero), ui.Size.zero);
      image.dispose();
    });
  });
}

Future<ui.Image> _createImage(int width, int height) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  final ui.Picture picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}
