import 'package:cinematch_ai/models/movie_recommendation.dart';
import 'package:cinematch_ai/services/poster_service.dart';

Future<void> main() async {
  final movies = [
    const MovieRecommendation(
      title: 'Vykúpenie z väznice Shawshank',
      englishTitle: 'The Shawshank Redemption',
      year: 1994,
      reason: 'test',
      moodTags: [],
      moodColors: [],
    ),
    const MovieRecommendation(
      title: 'Krstný otec',
      englishTitle: 'The Godfather',
      year: 1972,
      reason: 'test',
      moodTags: [],
      moodColors: [],
    ),
  ];

  final result = await PosterService().enrichWithPosters(
    RecommendationResult(summary: '', movies: movies),
  );

  for (final m in result.movies) {
    // ignore: avoid_print
    print('${m.title} → ${m.posterUrl?.contains('tmdb') == true ? "TMDB OK" : m.posterUrl ?? "žiadny"}');
  }
}
