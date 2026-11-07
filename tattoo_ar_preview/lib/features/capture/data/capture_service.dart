import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_failure.dart';
import '../../tattoo/domain/tattoo_transform.dart';
import '../../tattoo/rendering/ink_shader.dart';
import '../domain/capture_geometry.dart';

enum CaptureSource { cameraStill, previewBoundary }

class CaptureResult {
  const CaptureResult({
    required this.filePath,
    required this.shareResult,
    required this.source,
  });

  final String filePath;
  final ShareResult shareResult;
  final CaptureSource source;
}

class CaptureService {
  CaptureService({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  static const double maxOutputLongSide = 2560;
  static const int _maxCachedCaptures = 5;

  final SharePlus _sharePlus;

  Future<CaptureResult> captureAndShare({
    required CameraController? camera,
    required GlobalKey previewKey,
    required ui.Image tattooImage,
    required TattooTransform transform,
    required double opacity,
    required ui.Size viewportSize,
    required InkShaderComposer composer,
    required double devicePixelRatio,
    required ui.Rect sharePositionOrigin,
  }) async {
    Uint8List? pngBytes;
    CaptureSource source = CaptureSource.cameraStill;

    if (camera != null &&
        camera.value.isInitialized &&
        !camera.value.isTakingPicture) {
      ui.Image? photoImage;
      try {
        final XFile picture = await camera.takePicture();
        final Uint8List photoBytes = await picture.readAsBytes();
        photoImage = await _decodeImage(photoBytes);
        final ui.Size target = CaptureGeometry.outputSizeFor(
          ui.Size(photoImage.width.toDouble(), photoImage.height.toDouble()),
          viewportSize,
          maxLongSide: maxOutputLongSide,
        );
        if (target.isEmpty) {
          throw const CaptureFailure('La cámara devolvió una imagen vacía.');
        }
        pngBytes = await _renderComposite(
          photo: photoImage,
          target: target,
          tattooImage: tattooImage,
          transform: transform,
          opacity: opacity,
          composer: composer,
        );
      } catch (error) {
        debugPrint('SmartStencil: camera still capture failed: $error');
      } finally {
        photoImage?.dispose();
      }
    }

    if (pngBytes == null) {
      source = CaptureSource.previewBoundary;
      pngBytes = await _captureBoundary(previewKey, devicePixelRatio);
    }

    final File output = await _writeCapture(pngBytes);
    final ShareResult shareResult;
    try {
      shareResult = await _sharePlus.share(
        ShareParams(
          files: <XFile>[XFile(output.path, mimeType: 'image/png')],
          text: 'Tatuaje probado con SmartStencil',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (error) {
      throw CaptureFailure(
        'La captura se guardó en caché, pero no se pudo abrir el menú de '
        'compartir ($error).',
      );
    }

    return CaptureResult(
      filePath: output.path,
      shareResult: shareResult,
      source: source,
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  Future<Uint8List> _renderComposite({
    required ui.Image photo,
    required ui.Size target,
    required ui.Image tattooImage,
    required TattooTransform transform,
    required double opacity,
    required InkShaderComposer composer,
  }) async {
    final int width = target.width.round().clamp(1, 4096);
    final int height = target.height.round().clamp(1, 4096);
    final ui.Size canvasSize = ui.Size(width.toDouble(), height.toDouble());
    final ui.Rect destination = ui.Offset.zero & canvasSize;
    final ui.Rect source = CaptureGeometry.coverSourceRect(
      ui.Size(photo.width.toDouble(), photo.height.toDouble()),
      width / height,
    );

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder, destination);
    canvas.drawImageRect(
      photo,
      source,
      destination,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.high
        ..isAntiAlias = true,
    );
    composer.paintInk(
      canvas: canvas,
      size: canvasSize,
      image: tattooImage,
      transform: transform,
      opacity: opacity,
    );

    final ui.Picture picture = recorder.endRecording();
    try {
      final ui.Image composed = await picture.toImage(width, height);
      try {
        final ByteData? data = await composed.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) {
          throw const CaptureFailure(
            'No se pudo generar el PNG de la captura.',
          );
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        composed.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  Future<Uint8List> _captureBoundary(
    GlobalKey previewKey,
    double devicePixelRatio,
  ) async {
    final RenderObject? object = previewKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw const CaptureFailure(
        'No se pudo acceder a la vista previa para capturarla.',
      );
    }

    final double pixelRatio = devicePixelRatio.clamp(1.5, 3.5).toDouble();
    ui.Image? image;
    try {
      image = await object.toImage(pixelRatio: pixelRatio);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (data == null) {
        throw const CaptureFailure(
          'No se pudo generar la captura de la vista previa.',
        );
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on CaptureFailure {
      rethrow;
    } catch (_) {
      throw const CaptureFailure(
        'No se pudo generar la captura de la vista previa.',
      );
    } finally {
      image?.dispose();
    }
  }

  Future<File> _writeCapture(Uint8List bytes) async {
    try {
      final Directory temporary = await getTemporaryDirectory();
      final Directory folder = Directory(
        '${temporary.path}${Platform.pathSeparator}smartstencil_captures',
      );
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final File file = File(
        '${folder.path}${Platform.pathSeparator}'
        'smartstencil_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      unawaited(_pruneCaptures(folder));
      return file;
    } catch (error) {
      if (error is CaptureFailure) {
        rethrow;
      }
      throw const CaptureFailure(
        'No se pudo guardar la captura en el dispositivo.',
      );
    }
  }

  Future<void> _pruneCaptures(Directory folder) async {
    try {
      final List<FileSystemEntity> entries = await folder.list().toList();
      final List<File> files =
          entries
              .whereType<File>()
              .where((File file) => file.path.endsWith('.png'))
              .toList()
            ..sort(
              (File a, File b) =>
                  b.lastModifiedSync().compareTo(a.lastModifiedSync()),
            );
      for (int index = _maxCachedCaptures; index < files.length; index++) {
        try {
          await files[index].delete();
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      return;
    }
  }
}
