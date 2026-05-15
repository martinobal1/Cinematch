import 'api_secrets.dart';

/// Gemini kľúč: --dart-define má prednosť, inak lib/config/api_secrets.dart
class AppConfig {
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash-lite',
  );

  static String get effectiveGeminiKey =>
      geminiApiKey.isNotEmpty ? geminiApiKey : localGeminiApiKey;

  static bool get hasGeminiKey => effectiveGeminiKey.isNotEmpty;

  static const tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  static String get effectiveTmdbKey =>
      tmdbApiKey.isNotEmpty ? tmdbApiKey : localTmdbApiKey;
}
