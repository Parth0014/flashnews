class AppConfig {
  static const String localNewsApiKey = 'c8fe804302da48a980bcf55b8f4f8961';

  static const String _newsApiKeyFromEnv = String.fromEnvironment(
    'NEWS_API_KEY',
  );

  static String get newsApiKey =>
      _newsApiKeyFromEnv.isNotEmpty ? _newsApiKeyFromEnv : localNewsApiKey;

  static bool get hasNewsApiKey => newsApiKey.isNotEmpty;
}
