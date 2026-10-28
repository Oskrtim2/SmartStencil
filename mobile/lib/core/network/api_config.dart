/// Global API configuration for InkSight mobile app.
///
/// Supports runtime override via --dart-define=API_URL=https://...
/// or fallback to cloud / local server.
class ApiConfig {
  /// Default production cloud URL or local development server.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://inksight-api.onrender.com',
  );

  /// Helper to get current configured base URL
  static String get baseUrl => defaultBaseUrl;
}
