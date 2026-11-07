abstract final class AppConstants {
  static const String appName = 'SmartStencil';
  static const String shaderAsset = 'shaders/ink_blend.frag';

  static const double defaultInkOpacity = 0.82;
  static const double inkBaseSizeFraction = 0.62;
  static const double minTattooScale = 0.22;
  static const double maxTattooScale = 6;
  static const double maxTattooTranslation = 1.1;

  static const int maxPngFileBytes = 25 * 1024 * 1024;
  static const int maxSourceImageBytes = 40 * 1024 * 1024;
  static const int maxPngSourceDimension = 12000;
  static const int maxPngPixels = 40 * 1000 * 1000;
  static const int maxTattooTextureDimension = 2048;

  static const double maxCaptureLongSide = 2560;
  static const int maxCaptureDimension = 4096;
  static const int maxCachedCaptures = 5;
  static const double fallbackCapturePixelRatio = 3;
  static const double minFallbackCapturePixelRatio = 1.5;
  static const String capturesFolderName = 'smartstencil_captures';
  static const String capturesFilePrefix = 'smartstencil_';
  static const String stencilsFolderName = 'smartstencil_stencils';
  static const String stencilsFilePrefix = 'smartstencil_stencil_';

  static const double minTouchTarget = 48;
  static const Duration chromeFadeDuration = Duration(milliseconds: 180);
  static const Duration shutterFlashDuration = Duration(milliseconds: 420);
  static const Duration cameraInitializationTimeout = Duration(seconds: 20);
  static const Duration shaderLoadTimeout = Duration(seconds: 15);
}
