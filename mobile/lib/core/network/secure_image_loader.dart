import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Securely loads tattoo design images from presigned S3 URLs.
///
/// Security guarantees:
/// - Image bytes are streamed directly into memory — never written to disk.
/// - The returned [Uint8List] should be immediately passed to
///   [ArSessionController.loadTattooFromBytes], which decodes it to a GPU
///   texture and then zeroes the byte array.
/// - Response caching is explicitly disabled.
/// - Certificate pinning should be configured on the [Dio] instance.
class SecureImageLoader {
  final Dio _dio;

  SecureImageLoader({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.bytes,
          // Disable response caching
          headers: {
            'Cache-Control': 'no-store, no-cache',
            'Pragma': 'no-cache',
          },
        ));

  /// Download a tattoo PNG from a presigned S3 URL into memory.
  ///
  /// Returns the raw PNG bytes. These MUST be zeroed after GPU upload.
  /// Throws [SecureImageLoadException] on failure.
  Future<Uint8List> loadFromPresignedUrl(
    String presignedUrl, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        presignedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          // Prevent Dio from caching the response
          extra: {'no-cache': true},
        ),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode != 200) {
        throw SecureImageLoadException(
          'HTTP ${response.statusCode}: Failed to load design',
          statusCode: response.statusCode,
        );
      }

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const SecureImageLoadException('Empty response body');
      }

      // Validate PNG magic bytes
      final pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      if (bytes.length < 8 || !_matchesSignature(bytes, pngMagic)) {
        throw const SecureImageLoadException(
          'Invalid file format: expected PNG',
        );
      }

      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const SecureImageLoadException(
          'Access denied: presigned URL may have expired',
          statusCode: 403,
        );
      }
      if (e.response?.statusCode == 410) {
        throw const SecureImageLoadException(
          'Design link has been revoked or exhausted',
          statusCode: 410,
        );
      }
      throw SecureImageLoadException(
        'Network error: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  bool _matchesSignature(List<int> data, List<int> signature) {
    for (var i = 0; i < signature.length; i++) {
      if (data[i] != signature[i]) return false;
    }
    return true;
  }
}

/// Exception thrown when secure image loading fails.
@immutable
class SecureImageLoadException implements Exception {
  final String message;
  final int? statusCode;

  const SecureImageLoadException(this.message, {this.statusCode});

  @override
  String toString() => 'SecureImageLoadException($statusCode): $message';
}
