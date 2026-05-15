// Rýchly test Gemini API: dart run tool/test_gemini.dart
import 'package:cinematch_ai/config/app_config.dart';
import 'package:cinematch_ai/services/gemini_service.dart';

Future<void> main() async {
  print('Kľúč: ${AppConfig.effectiveGeminiKey.isNotEmpty ? "OK" : "CHÝBA"}');
  final service = GeminiService();
  final result = await service.recommendMovies(
    'Chcem niečo mysteriózne, nie horor, jesenná atmosféra.',
  );
  print('Filmy: ${result.movies.length}');
  for (final m in result.movies) {
    print('- ${m.title} (${m.year})');
  }
}
