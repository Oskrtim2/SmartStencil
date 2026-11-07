import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';

class StencilExportService {
  StencilExportService({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  static const int _maxCachedStencils = 5;

  final SharePlus _sharePlus;

  Future<ShareResult> shareStencil({
    required ui.Image image,
    required String sourceName,
    required ui.Rect sharePositionOrigin,
  }) async {
    final String path = await exportPng(image, sourceName: sourceName);
    try {
      return await _sharePlus.share(
        ShareParams(
          files: <XFile>[XFile(path, mimeType: 'image/png')],
          text: 'Stencil generado con SmartStencil',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (error) {
      debugPrint('SmartStencil: stencil share failed: $error');
      throw const StencilExportFailure(
        'El stencil se guardó, pero no se pudo abrir el menú de compartir.',
      );
    }
  }

  Future<String> exportPng(ui.Image image, {required String sourceName}) async {
    try {
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (data == null) {
        throw const StencilExportFailure(
          'No se pudo generar el PNG del stencil.',
        );
      }
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final Directory temporary = await getTemporaryDirectory();
      final Directory folder = Directory(
        '${temporary.path}${Platform.pathSeparator}'
        '${AppConstants.stencilsFolderName}',
      );
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final String safeName = _sanitize(sourceName);
      final File file = File(
        '${folder.path}${Platform.pathSeparator}'
        '${AppConstants.stencilsFilePrefix}'
        '${DateTime.now().microsecondsSinceEpoch}_$safeName.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      final int written = await file.length();
      if (written != bytes.length) {
        await _deleteQuietly(file);
        throw const StencilExportFailure(
          'El PNG del stencil se guardó incompleto. Comprueba el '
          'almacenamiento del dispositivo.',
        );
      }
      unawaited(_prune(folder));
      return file.path;
    } on StencilExportFailure {
      rethrow;
    } on FileSystemException {
      throw const StencilExportFailure(
        'No hay espacio suficiente para guardar el stencil.',
      );
    } catch (error) {
      debugPrint('SmartStencil: stencil export failed: $error');
      throw const StencilExportFailure(
        'No se pudo guardar el stencil como PNG.',
      );
    }
  }

  Future<void> _prune(Directory folder) async {
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
      for (int index = _maxCachedStencils; index < files.length; index++) {
        await _deleteQuietly(files[index]);
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {
      return;
    }
  }

  String _sanitize(String value) {
    final String base = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) {
      return 'stencil';
    }
    return base.length > 40 ? base.substring(0, 40) : base;
  }
}
