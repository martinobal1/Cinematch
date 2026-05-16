import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_config.dart';
import '../models/movie_recommendation.dart';

class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = apiKey ?? AppConfig.effectiveGeminiKey;

  final String _apiKey;

  static const _fallbackModels = [
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
  ];

  Future<RecommendationResult> recommendMovies(String userMood) async {
    if (_apiKey.isEmpty) {
      throw GeminiException(
        'Chýba GEMINI_API_KEY. Spusti: flutter run --dart-define=GEMINI_API_KEY=tvoj_kluc',
      );
    }

    final modelsToTry = <String>{
      if (AppConfig.geminiModel.isNotEmpty) AppConfig.geminiModel,
      ..._fallbackModels,
    }.toList();

    Object? lastError;
    for (final modelName in modelsToTry) {
      try {
        return await _callModel(modelName, userMood);
      } catch (e) {
        lastError = e;
        final msg = e.toString();
        if (msg.contains('not found') || msg.contains('not supported')) {
          continue;
        }
        if (msg.contains('quota') || msg.contains('Quota')) {
          continue;
        }
        rethrow;
      }
    }
    final last = lastError.toString();
    if (last.contains('quota') || last.contains('Quota')) {
      throw GeminiException(
        'Vyčerpaná bezplatná kvóta Gemini. Počkaj ~1 minútu a skús znova, '
        'alebo zapni billing v Google AI Studio / Cloud Console.',
      );
    }
    throw GeminiException(
      'Žiadny Gemini model nie je dostupný. Posledná chyba: $lastError',
    );
  }

  Future<RecommendationResult> _callModel(
    String modelName,
    String userMood,
  ) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        responseMimeType: 'application/json',
      ),
    );

    final prompt = '''
Si filmový expert CineMatch. Používateľ opísal náladu/situáciu:
"$userMood"

Odpovedz VÝHRADNE platným JSON (bez markdown) v tomto tvare:
{
  "summary": "jedna veta o celkovej nálade odporúčaní",
  "movies": [
    {
      "title": "slovenský názov filmu pre používateľa",
      "englishTitle": "The Movie Title in English",
      "year": 2010,
      "reason": "2-3 vety prečo sedí k popisu",
      "moodTags": ["tag1", "tag2", "tag3"],
      "moodColors": ["1a1a2e", "16213e", "0f3460"],
      "trailerQuery": "názov filmu rok official trailer",
      "personalReview": "krátka recenzia šitá na mieru používateľovi",
      "imdbRating": 8.8,
      "csfdRating": 87
    }
  ]
}

Pravidlá:
- Presne 3 až 5 filmov v poli movies (ak používateľ chce top 10, daj 5 najlepších)
- englishTitle: vždy oficiálny anglický názov filmu (pre plagáty)
- imdbRating: priemerné hodnotenie z IMDb (0–10), len ak ho poznáš; inak vynechaj pole
- csfdRating: hodnotenie z ČSFD v percentách (0–100), len ak ho poznáš; inak vynechaj pole
- moodColors: 3 hex farby bez # (náladová paleta)
- Odpovedaj v slovenčine (title, reason, tagy); englishTitle vždy po anglicky
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw GeminiException('Gemini nevrátilo žiadnu odpoveď.');
    }

    final parsed = RecommendationResult.tryParse(text);
    if (parsed != null && parsed.movies.isNotEmpty) {
      return parsed;
    }

    throw GeminiException(
      'Nepodarilo sa spracovať JSON odpoveď: ${text.substring(0, text.length.clamp(0, 200))}',
    );
  }
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}
