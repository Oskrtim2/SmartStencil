import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

enum StencilMode { transparent, flat, ai, full }

class StencilOptions {
  const StencilOptions({
    this.backgroundTolerance = 46,
    this.backgroundSoftness = 18,
    this.inkThreshold = 0.16,
    this.photoInkThreshold = 0.34,
    this.inkSoftness = 0.07,
    this.edgeBoost = 1.8,
    this.minComponentPixels = 8,
    this.cropPadding = 2,
    this.alphaCutoff = 8,
  });

  final double backgroundTolerance;
  final double backgroundSoftness;
  final double inkThreshold;
  final double photoInkThreshold;
  final double inkSoftness;
  final double edgeBoost;
  final int minComponentPixels;
  final int cropPadding;
  final int alphaCutoff;
}

class StencilRequest {
  const StencilRequest({
    required this.rgba,
    required this.width,
    required this.height,
    required this.mode,
    this.backgroundArgb = 0xFFFFFFFF,
    this.backgroundIsDark = false,
    this.options = const StencilOptions(),
  });

  final Uint8List rgba;
  final int width;
  final int height;
  final StencilMode mode;
  final int backgroundArgb;
  final bool backgroundIsDark;
  final StencilOptions options;
}

class StencilResult {
  const StencilResult({
    required this.rgba,
    required this.width,
    required this.height,
    required this.removedComponents,
    required this.isEmpty,
  });

  final Uint8List rgba;
  final int width;
  final int height;
  final int removedComponents;
  final bool isEmpty;
}

StencilResult processStencilInIsolate(StencilRequest request) {
  return StencilProcessor.process(request);
}

abstract final class StencilProcessor {
  static StencilResult process(StencilRequest request) {
    final int width = request.width;
    final int height = request.height;
    final Uint8List source = request.rgba;
    if (width <= 0 || height <= 0 || source.length < width * height * 4) {
      throw ArgumentError('RGBA buffer does not match the image dimensions.');
    }

    final Uint8List output = Uint8List(width * height * 4);
    switch (request.mode) {
      case StencilMode.transparent:
        _applyTransparent(source, output, width, height, request.options);
      case StencilMode.flat:
        _applyFlat(source, output, width, height, request);
      case StencilMode.ai:
        _applyPhoto(
          source,
          output,
          width,
          height,
          request.options,
          useAlpha: true,
        );
      case StencilMode.full:
        _applyPhoto(
          source,
          output,
          width,
          height,
          request.options,
          useAlpha: false,
        );
    }

    final int removed = _removeSmallComponents(
      output,
      width,
      height,
      request.options,
    );
    final StencilResult cropped = _crop(
      output,
      width,
      height,
      request.options.cropPadding,
      removed,
    );
    return cropped;
  }

  static void _applyTransparent(
    Uint8List source,
    Uint8List output,
    int width,
    int height,
    StencilOptions options,
  ) {
    final int pixels = width * height;
    for (int index = 0; index < pixels; index++) {
      final int sourceOffset = index * 4;
      final int alpha = source[sourceOffset + 3];
      if (alpha >= options.alphaCutoff) {
        output[sourceOffset + 3] = alpha;
      }
    }
  }

  static void _applyFlat(
    Uint8List source,
    Uint8List output,
    int width,
    int height,
    StencilRequest request,
  ) {
    final StencilOptions options = request.options;
    final int backgroundR = (request.backgroundArgb >> 16) & 0xFF;
    final int backgroundG = (request.backgroundArgb >> 8) & 0xFF;
    final int backgroundB = request.backgroundArgb & 0xFF;
    final double tolerance = options.backgroundTolerance;
    final double softness = options.backgroundSoftness;
    final int pixels = width * height;

    for (int index = 0; index < pixels; index++) {
      final int offset = index * 4;
      final int alpha = source[offset + 3];
      if (alpha < options.alphaCutoff) {
        continue;
      }

      final int r = source[offset];
      final int g = source[offset + 1];
      final int b = source[offset + 2];
      final double dr = (r - backgroundR).toDouble();
      final double dg = (g - backgroundG).toDouble();
      final double db = (b - backgroundB).toDouble();
      final double distance = math.sqrt(dr * dr + dg * dg + db * db);
      final double backgroundFactor = _smoothstep(
        tolerance - softness,
        tolerance + softness,
        distance,
      );

      final double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
      final int maxChannel = math.max(r, math.max(g, b));
      final int minChannel = math.min(r, math.min(g, b));
      final double chroma = (maxChannel - minChannel) / 255;
      final double density = request.backgroundIsDark
          ? math.max(luminance, chroma * 0.92)
          : math.max(1 - luminance, chroma * 0.92);
      final double inkFactor = _smoothstep(
        options.inkThreshold - options.inkSoftness,
        options.inkThreshold + options.inkSoftness,
        density,
      );
      final int resultAlpha =
          (backgroundFactor * inkFactor * (alpha / 255) * 255).round().clamp(
            0,
            255,
          );
      output[offset + 3] = resultAlpha;
    }
  }

  static void _applyPhoto(
    Uint8List source,
    Uint8List output,
    int width,
    int height,
    StencilOptions options, {
    required bool useAlpha,
  }) {
    final int pixels = width * height;
    final Uint8List gray = Uint8List(pixels);
    for (int index = 0; index < pixels; index++) {
      final int offset = index * 4;
      final int r = source[offset];
      final int g = source[offset + 1];
      final int b = source[offset + 2];
      gray[index] = ((0.299 * r + 0.587 * g + 0.114 * b)).round();
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int index = y * width + x;
        final int offset = index * 4;
        final int alpha = useAlpha ? source[offset + 3] : 255;
        if (alpha < options.alphaCutoff) {
          continue;
        }

        final int r = source[offset];
        final int g = source[offset + 1];
        final int b = source[offset + 2];
        final double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        final int maxChannel = math.max(r, math.max(g, b));
        final int minChannel = math.min(r, math.min(g, b));
        final double chroma = (maxChannel - minChannel) / 255;
        final double density = math.max(1 - luminance, chroma * 0.92);
        final double edge = _edgeStrength(gray, width, height, x, y);
        final double ink = math.min(
          1,
          math.max(density, edge * options.edgeBoost),
        );
        final double inkFactor = _smoothstep(
          options.photoInkThreshold - options.inkSoftness,
          options.photoInkThreshold + options.inkSoftness,
          ink,
        );
        final int resultAlpha = (inkFactor * (alpha / 255) * 255).round().clamp(
          0,
          255,
        );
        output[offset + 3] = resultAlpha;
      }
    }
  }

  static double _edgeStrength(
    Uint8List gray,
    int width,
    int height,
    int x,
    int y,
  ) {
    if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
      return 0;
    }
    final int topLeft = gray[(y - 1) * width + x - 1];
    final int top = gray[(y - 1) * width + x];
    final int topRight = gray[(y - 1) * width + x + 1];
    final int left = gray[y * width + x - 1];
    final int right = gray[y * width + x + 1];
    final int bottomLeft = gray[(y + 1) * width + x - 1];
    final int bottom = gray[(y + 1) * width + x];
    final int bottomRight = gray[(y + 1) * width + x + 1];

    final int gradientX =
        -topLeft - 2 * left - bottomLeft + topRight + 2 * right + bottomRight;
    final int gradientY =
        -topLeft - 2 * top - topRight + bottomLeft + 2 * bottom + bottomRight;
    final double magnitude =
        math.sqrt(gradientX * gradientX + gradientY * gradientY) / 1020;
    return magnitude.clamp(0.0, 1.0);
  }

  static int _removeSmallComponents(
    Uint8List rgba,
    int width,
    int height,
    StencilOptions options,
  ) {
    final int pixels = width * height;
    final int minPixels = math.max(
      options.minComponentPixels,
      (pixels / 350000).round(),
    );
    final Uint8List visited = Uint8List(pixels);
    int removed = 0;

    for (int start = 0; start < pixels; start++) {
      if (visited[start] != 0 || rgba[start * 4 + 3] < options.alphaCutoff) {
        continue;
      }

      final ListQueue<int> queue = ListQueue<int>()..add(start);
      visited[start] = 1;
      final List<int> component = <int>[];
      int area = 0;
      bool keep = false;

      while (queue.isNotEmpty) {
        final int current = queue.removeFirst();
        area++;
        if (!keep) {
          component.add(current);
          if (area > minPixels) {
            keep = true;
            component.clear();
          }
        }

        final int x = current % width;
        final int y = current ~/ width;
        for (int dy = -1; dy <= 1; dy++) {
          final int nextY = y + dy;
          if (nextY < 0 || nextY >= height) {
            continue;
          }
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
              continue;
            }
            final int nextX = x + dx;
            if (nextX < 0 || nextX >= width) {
              continue;
            }
            final int next = nextY * width + nextX;
            if (visited[next] != 0 ||
                rgba[next * 4 + 3] < options.alphaCutoff) {
              continue;
            }
            visited[next] = 1;
            queue.add(next);
          }
        }
      }

      if (!keep) {
        for (final int index in component) {
          rgba[index * 4 + 3] = 0;
        }
        removed++;
      }
    }
    return removed;
  }

  static StencilResult _crop(
    Uint8List rgba,
    int width,
    int height,
    int padding,
    int removedComponents,
  ) {
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (rgba[(y * width + x) * 4 + 3] == 0) {
          continue;
        }
        if (x < minX) {
          minX = x;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return StencilResult(
        rgba: Uint8List(0),
        width: 0,
        height: 0,
        removedComponents: removedComponents,
        isEmpty: true,
      );
    }

    final int left = math.max(0, minX - padding);
    final int top = math.max(0, minY - padding);
    final int right = math.min(width - 1, maxX + padding);
    final int bottom = math.min(height - 1, maxY + padding);
    final int croppedWidth = right - left + 1;
    final int croppedHeight = bottom - top + 1;
    final Uint8List cropped = Uint8List(croppedWidth * croppedHeight * 4);
    final int rowBytes = croppedWidth * 4;

    for (int row = 0; row < croppedHeight; row++) {
      final int sourceStart = ((top + row) * width + left) * 4;
      final int destinationStart = row * rowBytes;
      cropped.setRange(
        destinationStart,
        destinationStart + rowBytes,
        rgba,
        sourceStart,
      );
    }

    return StencilResult(
      rgba: cropped,
      width: croppedWidth,
      height: croppedHeight,
      removedComponents: removedComponents,
      isEmpty: false,
    );
  }

  static double _smoothstep(double edge0, double edge1, double value) {
    if (edge1 <= edge0) {
      return value >= edge1 ? 1 : 0;
    }
    final double t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
