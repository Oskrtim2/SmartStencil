import 'dart:typed_data';

class BorderAnalysis {
  const BorderAnalysis({
    required this.dominantColorArgb,
    required this.coverage,
    required this.isDark,
  });

  static const double uniformCoverageThreshold = 0.62;

  final int dominantColorArgb;
  final double coverage;
  final bool isDark;

  bool get isUniform => coverage >= uniformCoverageThreshold;

  static BorderAnalysis analyze(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      return const BorderAnalysis(
        dominantColorArgb: 0xFFFFFFFF,
        coverage: 0,
        isDark: false,
      );
    }

    final Map<int, _ColorBucket> buckets = <int, _ColorBucket>{};
    int total = 0;

    void sample(int x, int y) {
      final int index = (y * width + x) * 4;
      if (rgba[index + 3] < 128) {
        return;
      }
      final int r = rgba[index];
      final int g = rgba[index + 1];
      final int b = rgba[index + 2];
      final int key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      final _ColorBucket bucket = buckets.putIfAbsent(
        key,
        () => _ColorBucket(),
      );
      bucket.count++;
      bucket.red += r;
      bucket.green += g;
      bucket.blue += b;
      total++;
    }

    for (int x = 0; x < width; x++) {
      sample(x, 0);
      if (height > 1) {
        sample(x, height - 1);
      }
    }
    for (int y = 1; y < height - 1; y++) {
      sample(0, y);
      if (width > 1) {
        sample(width - 1, y);
      }
    }

    if (total == 0) {
      return const BorderAnalysis(
        dominantColorArgb: 0xFFFFFFFF,
        coverage: 0,
        isDark: false,
      );
    }

    _ColorBucket? dominant;
    for (final _ColorBucket bucket in buckets.values) {
      if (dominant == null || bucket.count > dominant.count) {
        dominant = bucket;
      }
    }

    final _ColorBucket winner = dominant!;
    final int r = (winner.red / winner.count).round();
    final int g = (winner.green / winner.count).round();
    final int b = (winner.blue / winner.count).round();
    final double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    return BorderAnalysis(
      dominantColorArgb: 0xFF000000 | (r << 16) | (g << 8) | b,
      coverage: winner.count / total,
      isDark: luminance < 0.35,
    );
  }
}

class _ColorBucket {
  int count = 0;
  int red = 0;
  int green = 0;
  int blue = 0;
}
