import 'package:cinematch_ai/models/movie_recommendation.dart';
import 'package:cinematch_ai/services/poster_service.dart';

Future<void> main() async {
  const movie = MovieRecommendation(
    title: 'Shutter Island',
    year: 2010,
    reason: 'test',
    moodTags: [],
    moodColors: [],
  );
  final result = await PosterService().enrichWithPosters(
    RecommendationResult(summary: '', movies: [movie]),
  );
  final m = result.movies.first;
  // ignore: avoid_print
  print('Poster: ${m.posterUrl ?? "žiadny"}');
}
