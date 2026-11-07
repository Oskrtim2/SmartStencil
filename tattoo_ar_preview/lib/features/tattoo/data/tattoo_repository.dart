import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';

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
    if (!hasPngSignature(bytes)) {
      throw const TattooImportFailure(
        'El diseño debe ser un archivo PNG con fondo transparente.',
      );
    }

    final _PngHeader? header = _PngHeader.tryParse(bytes);
    if (header == null) {
      throw const TattooImportFailure('El PNG está dañado o no es válido.');
    }
    if (header.width <= 0 ||
        header.height <= 0 ||
        header.width > _maxSourceDimension ||
        header.height > _maxSourceDimension) {
      throw const TattooImportFailure(
        'Las dimensiones del PNG no son compatibles.',
      );
    }
    if (!header.hasAlpha && !_hasTransparencyChunk(bytes)) {
      throw const TattooImportFailure(
        'El PNG no incluye canal alfa. Usa un diseño con el fondo '
        'transparente.',
      );
    }

    await _ensureTransparentPixels(bytes);
    final ui.Image image = await _decodeDesign(bytes, header);

    return TattooDesign(
      image: image,
      fileName: file.name,
      byteSize: bytes.length,
    );
  }

  static bool hasPngSignature(Uint8List bytes) {
    const List<int> signature = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ];
    if (bytes.length < signature.length) {
      return false;
    }
    for (int index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        return false;
      }
    }
    return true;
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

  Future<ui.Image> _decodeDesign(Uint8List bytes, _PngHeader header) async {
    int? targetWidth;
    int? targetHeight;
    final int longestSide = math.max(header.width, header.height);
    if (longestSide > maxTextureDimension) {
      if (header.width >= header.height) {
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

  bool _hasTransparencyChunk(Uint8List bytes) {
    if (bytes.length < 8) {
      return false;
    }
    final ByteData data = ByteData.sublistView(bytes);
    int offset = 8;
    while (offset + 12 <= bytes.length) {
      final int chunkLength = data.getUint32(offset, Endian.big);
      if (offset + 12 + chunkLength > bytes.length) {
        return false;
      }
      final String chunkType = String.fromCharCodes(
        bytes.sublist(offset + 4, offset + 8),
      );
      if (chunkType == 'tRNS') {
        return true;
      }
      if (chunkType == 'IDAT') {
        return false;
      }
      offset += 12 + chunkLength;
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

class _PngHeader {
  const _PngHeader({
    required this.width,
    required this.height,
    required this.colorType,
  });

  final int width;
  final int height;
  final int colorType;

  bool get hasAlpha => colorType == 4 || colorType == 6;

  static _PngHeader? tryParse(Uint8List bytes) {
    if (bytes.length < 33 || !TattooRepository.hasPngSignature(bytes)) {
      return null;
    }
    final ByteData data = ByteData.sublistView(bytes);
    if (data.getUint32(8, Endian.big) != 13) {
      return null;
    }
    if (String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
      return null;
    }
    final int width = data.getUint32(16, Endian.big);
    final int height = data.getUint32(20, Endian.big);
    final int colorType = bytes[25];
    if (width == 0 || height == 0) {
      return null;
    }
    return _PngHeader(width: width, height: height, colorType: colorType);
  }
}
