import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/png_metadata.dart';

class TattooDesign {
  TattooDesign({
    required this.image,
    required this.fileName,
    required this.byteSize,
  });

  final ui.Image image;
  final String fileName;
  final int byteSize;

  int get width => image.width;
  int get height => image.height;

  void dispose() {
    image.dispose();
  }
}

class TattooRepository {
  TattooRepository({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int maxFileBytes = AppConstants.maxPngFileBytes;
  static const int maxTextureDimension = AppConstants.maxTattooTextureDimension;
  static const int _maxSourceDimension = AppConstants.maxPngSourceDimension;

  final ImagePicker _picker;

  Future<TattooDesign?> pickTransparentPng() async {
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

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const TattooImportFailure(
        'No se pudo leer el archivo seleccionado.',
      );
    }

    if (bytes.isEmpty) {
      throw const TattooImportFailure('El archivo seleccionado está vacío.');
    }
    if (bytes.length > maxFileBytes) {
      throw const TattooImportFailure(
        'El PNG supera el límite de 25 MB. Elige un diseño más ligero.',
      );
    }
    if (!PngMetadata.hasPngSignature(bytes)) {
      throw const TattooImportFailure(
        'El diseño debe ser un archivo PNG con fondo transparente.',
      );
    }

    final PngMetadata? metadata = PngMetadata.tryParse(bytes);
    if (metadata == null) {
      throw const TattooImportFailure('El PNG está dañado o no es válido.');
    }
    if (metadata.width > _maxSourceDimension ||
        metadata.height > _maxSourceDimension) {
      throw const TattooImportFailure(
        'Las dimensiones del PNG no son compatibles.',
      );
    }
    if (metadata.exceedsPixelBudget(AppConstants.maxPngPixels)) {
      throw const TattooImportFailure(
        'El PNG es demasiado grande para procesarlo con seguridad. '
        'Usa una imagen de hasta 40 megapíxeles.',
      );
    }
    if (!metadata.canContainTransparency) {
      throw const TattooImportFailure(
        'El PNG no incluye canal alfa. Usa un diseño con el fondo '
        'transparente.',
      );
    }

    await _ensureTransparentPixels(bytes);
    final ui.Image image = await _decodeDesign(bytes, metadata);

    return TattooDesign(
      image: image,
      fileName: file.name,
      byteSize: bytes.length,
    );
  }

  static bool hasPngSignature(Uint8List bytes) {
    return PngMetadata.hasPngSignature(bytes);
  }

  Future<void> _ensureTransparentPixels(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 160,
        allowUpscaling: false,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      image = frame.image;
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (data == null) {
        return;
      }
      final Uint8List pixels = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      bool hasTransparency = false;
      for (int index = 3; index < pixels.length; index += 4) {
        if (pixels[index] < 250) {
          hasTransparency = true;
          break;
        }
      }
      if (!hasTransparency) {
        throw const TattooImportFailure(
          'El PNG no contiene zonas transparentes. Usa un diseño con el '
          'fondo transparente.',
        );
      }
    } on TattooImportFailure {
      rethrow;
    } catch (_) {
      throw const TattooImportFailure(
        'No se pudo verificar la transparencia del PNG.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<ui.Image> _decodeDesign(Uint8List bytes, PngMetadata metadata) async {
    int? targetWidth;
    int? targetHeight;
    final int longestSide = math.max(metadata.width, metadata.height);
    if (longestSide > maxTextureDimension) {
      if (metadata.width >= metadata.height) {
        targetWidth = maxTextureDimension;
      } else {
        targetHeight = maxTextureDimension;
      }
    }

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: false,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      throw const TattooImportFailure(
        'No se pudo decodificar el PNG seleccionado.',
      );
    } finally {
      codec?.dispose();
    }
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
