import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_background_remover/image_background_remover.dart';

class BackgroundCutout {
  const BackgroundCutout({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba;
  final int width;
  final int height;
}

abstract interface class BackgroundRemovalEngine {
  Future<BackgroundCutout?> removeBackground(Uint8List imageBytes);
}

class OnnxBackgroundRemovalEngine implements BackgroundRemovalEngine {
  OnnxBackgroundRemovalEngine();

  final BackgroundRemover _remover = BackgroundRemover.instance;
  Future<void>? _initializationFuture;

  Future<void> _ensureInitialized() async {
    final Future<void>? existing = _initializationFuture;
    if (existing != null) {
      await existing;
      return;
    }
    final Future<void> future = _remover.initializeOrt();
    _initializationFuture = future;
    try {
      await future;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  @override
  Future<BackgroundCutout?> removeBackground(Uint8List imageBytes) async {
    try {
      await _ensureInitialized();
      final ui.Image image = await _remover.removeBg(
        imageBytes,
        threshold: 0.5,
        smoothMask: true,
        enhanceEdges: true,
      );
      try {
        final ByteData? data = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (data == null) {
          return null;
        }
        return BackgroundCutout(
          rgba: Uint8List.fromList(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
          width: image.width,
          height: image.height,
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      debugPrint('SmartStencil: AI background removal unavailable: $error');
      return null;
    }
  }
}
