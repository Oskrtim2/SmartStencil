import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/png_metadata.dart';
import '../processing/background_analysis.dart';
import '../processing/background_removal_engine.dart';
import '../processing/stencil_processor.dart';

class TattooDesign {
  TattooDesign({
    required this.image,
    required this.fileName,
    required this.byteSize,
    required this.generatedWithAi,
    required this.processingNote,
  });

  final ui.Image image;
  final String fileName;
  final int byteSize;
  final bool generatedWithAi;
  final String processingNote;

  int get width => image.width;
  int get height => image.height;

  void dispose() {
    image.dispose();
  }
}

class TattooRepository {
  TattooRepository({
    ImagePicker? picker,
    BackgroundRemovalEngine? backgroundRemoval,
  }) : _picker = picker ?? ImagePicker(),
       _backgroundRemoval = backgroundRemoval ?? OnnxBackgroundRemovalEngine();

  static const int maxFileBytes = AppConstants.maxSourceImageBytes;
  static const int maxTextureDimension = AppConstants.maxTattooTextureDimension;

  final ImagePicker _picker;
  final BackgroundRemovalEngine _backgroundRemoval;

  Future<TattooDesign?> pickAndConvertDesign({
    ValueChanged<String>? onStage,
  }) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } on PlatformException catch (error) {
      throw TattooImportFailure(
        _pickerMessage(error),
        canOpenSettings: _isPermissionError(error),
      );
    }

    if (file == null) {
      return null;
    }
    return _designFromFile(file, onStage: onStage);
  }

  Future<TattooDesign?> retrieveLostDesign({
    ValueChanged<String>? onStage,
  }) async {
    final LostDataResponse response;
    try {
      response = await _picker.retrieveLostData();
    } on UnimplementedError {
      return null;
    } on PlatformException catch (error) {
      throw TattooImportFailure(
        _pickerMessage(error),
        canOpenSettings: _isPermissionError(error),
      );
    }

    if (response.isEmpty) {
      return null;
    }
    if (response.exception != null) {
      throw const TattooImportFailure(
        'No se pudo recuperar la imagen seleccionada. Inténtalo de nuevo.',
      );
    }
    final List<XFile>? files = response.files;
    final XFile? file =
        response.file ??
        (files != null && files.isNotEmpty ? files.first : null);
    if (file == null) {
      return null;
    }
    return _designFromFile(file, onStage: onStage);
  }

  Future<TattooDesign> _designFromFile(
    XFile file, {
    ValueChanged<String>? onStage,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const TattooImportFailure(
        'No se pudo leer la imagen seleccionada.',
      );
    }

    if (bytes.isEmpty) {
      throw const TattooImportFailure('La imagen seleccionada está vacía.');
    }
    if (bytes.length > maxFileBytes) {
      throw const TattooImportFailure(
        'La imagen supera el límite de 40 MB. Elige un archivo más ligero.',
      );
    }

    onStage?.call('Leyendo imagen…');
    final _DecodedImage decoded = await _decodeImage(bytes);

    try {
      final bool transparent = _hasMeaningfulTransparency(decoded.rgba);
      StencilMode mode;
      int backgroundArgb = 0xFFFFFFFF;
      bool backgroundIsDark = false;
      bool generatedWithAi = false;
      Uint8List workingRgba = decoded.rgba;
      int workingWidth = decoded.width;
      int workingHeight = decoded.height;
      String processingNote;

      if (transparent) {
        mode = StencilMode.transparent;
        processingNote = 'Diseño transparente convertido a tinta negra.';
      } else {
        final BorderAnalysis analysis = BorderAnalysis.analyze(
          decoded.rgba,
          decoded.width,
          decoded.height,
        );
        if (analysis.isUniform) {
          mode = StencilMode.flat;
          backgroundArgb = analysis.dominantColorArgb;
          backgroundIsDark = analysis.isDark;
          processingNote = 'Fondo eliminado automáticamente.';
        } else {
          onStage?.call('Eliminando fondo con IA…');
          await Future<void>.delayed(const Duration(milliseconds: 40));
          final Uint8List pngBytes = await _encodePng(decoded.image);
          final BackgroundCutout? cutout = await _backgroundRemoval
              .removeBackground(pngBytes);
          if (cutout != null) {
            mode = StencilMode.ai;
            generatedWithAi = true;
            workingRgba = cutout.rgba;
            workingWidth = cutout.width;
            workingHeight = cutout.height;
            processingNote = 'Fondo eliminado con IA.';
          } else {
            mode = StencilMode.full;
            processingNote =
                'Stencil generado; la IA no estaba disponible en este '
                'dispositivo.';
          }
        }
      }

      onStage?.call('Generando stencil transparente…');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final StencilResult result = await compute(
        processStencilInIsolate,
        StencilRequest(
          rgba: workingRgba,
          width: workingWidth,
          height: workingHeight,
          mode: mode,
          backgroundArgb: backgroundArgb,
          backgroundIsDark: backgroundIsDark,
        ),
      );

      if (result.isEmpty) {
        throw const TattooImportFailure(
          'No se detectó tinta en la imagen. Prueba con otro diseño.',
        );
      }

      final ui.Image stencil = await _rgbaToImage(
        result.rgba,
        result.width,
        result.height,
      );

      return TattooDesign(
        image: stencil,
        fileName: file.name,
        byteSize: bytes.length,
        generatedWithAi: generatedWithAi,
        processingNote: processingNote,
      );
    } on TattooImportFailure {
      rethrow;
    } catch (error) {
      debugPrint('SmartStencil: stencil conversion failed: $error');
      throw const TattooImportFailure(
        'No se pudo convertir la imagen a un stencil transparente.',
      );
    } finally {
      decoded.image.dispose();
    }
  }

  static bool hasPngSignature(Uint8List bytes) {
    return PngMetadata.hasPngSignature(bytes);
  }

  Future<_DecodedImage> _decodeImage(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      int? targetWidth;
      int? targetHeight;
      final int longestSide = math.max(descriptor.width, descriptor.height);
      if (longestSide > maxTextureDimension) {
        if (descriptor.width >= descriptor.height) {
          targetWidth = maxTextureDimension;
        } else {
          targetHeight = maxTextureDimension;
        }
      }

      codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (data == null) {
        image.dispose();
        throw const TattooImportFailure(
          'No se pudo leer los píxeles de la imagen.',
        );
      }
      final Uint8List rgba = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return _DecodedImage(
        image: image,
        rgba: rgba,
        width: image.width,
        height: image.height,
      );
    } on TattooImportFailure {
      rethrow;
    } catch (error) {
      debugPrint('SmartStencil: image decode failed: $error');
      throw const TattooImportFailure(
        'No se pudo decodificar la imagen. Prueba con JPG, PNG, WebP o HEIC.',
      );
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (data == null) {
      throw const TattooImportFailure(
        'No se pudo preparar la imagen para la IA.',
      );
    }
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<ui.Image> _rgbaToImage(Uint8List rgba, int width, int height) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    try {
      ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (
        ui.Image image,
      ) {
        if (!completer.isCompleted) {
          completer.complete(image);
        }
      });
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
    return completer.future;
  }

  bool _hasMeaningfulTransparency(Uint8List rgba) {
    final int pixels = rgba.length ~/ 4;
    final int minimum = math.max(50, pixels ~/ 500);
    int transparent = 0;
    for (int index = 3; index < rgba.length; index += 4) {
      if (rgba[index] < 250) {
        transparent++;
        if (transparent >= minimum) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isPermissionError(PlatformException error) {
    final String code = error.code.toLowerCase();
    final String message = (error.message ?? '').toLowerCase();
    return code.contains('permission') ||
        code.contains('access_denied') ||
        message.contains('permission');
  }

  String _pickerMessage(PlatformException error) {
    if (_isPermissionError(error)) {
      return 'No hay permiso para acceder a la galería. Actívalo en los '
          'ajustes del sistema.';
    }
    if (error.code == 'already_active') {
      return 'El selector de fotos ya está abierto.';
    }
    return 'No se pudo abrir la galería. Inténtalo de nuevo.';
  }
}

class _DecodedImage {
  const _DecodedImage({
    required this.image,
    required this.rgba,
    required this.width,
    required this.height,
  });

  final ui.Image image;
  final Uint8List rgba;
  final int width;
  final int height;
}
