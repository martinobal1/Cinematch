import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/movie_recommendation.dart';

/// Plagáty: TMDB (najlepšia kvalita) → Wikipédia REST → bez obrázka placeholder.
class PosterService {
  Future<RecommendationResult> enrichWithPosters(
    RecommendationResult result,
  ) async {
    final movies = await Future.wait(
      result.movies.map(_fetchPoster),
    );
    return RecommendationResult(summary: result.summary, movies: movies);
  }

  Future<MovieRecommendation> _fetchPoster(MovieRecommendation movie) async {
    final url =
        await _tmdbPoster(movie) ?? await _wikipediaPoster(movie);
    if (url == null) return movie;
    return movie.copyWith(posterUrl: url);
  }

  Future<String?> _tmdbPoster(MovieRecommendation movie) async {
    final key = AppConfig.effectiveTmdbKey;
    if (key.isEmpty) return null;

    final uri = Uri.https('api.themoviedb.org', '/3/search/movie', {
      'api_key': key,
      'query': movie.title,
      if (movie.year > 0) 'year': '${movie.year}',
      'language': 'en-US',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final posterPath = results.first['poster_path'] as String?;
      if (posterPath == null || posterPath.isEmpty) return null;

      return 'https://image.tmdb.org/t/p/w500$posterPath';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _wikipediaPoster(MovieRecommendation movie) async {
    try {
      final title = await _wikipediaPageTitle(movie);
      if (title == null) return null;

      final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final summaryUri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );

      final response =
          await http.get(summaryUri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final thumb = data['thumbnail'] as Map<String, dynamic>?;
      var url = thumb?['source'] as String?;
      if (url == null) return null;

      // Vyššie rozlíšenie (Wikipedia často dá 320px thumb).
      url = url.replaceAll(RegExp(r'/\d+px-'), '/500px-');
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _wikipediaPageTitle(MovieRecommendation movie) async {
    final query = movie.year > 0
        ? '${movie.title} ${movie.year} film'
        : '${movie.title} film';

    final searchUri = Uri.https(
      'en.wikipedia.org',
      '/w/rest.php/v1/search/title',
      {'q': query, 'limit': '3'},
    );

    final response =
        await http.get(searchUri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = data['pages'] as List<dynamic>?;
    if (pages == null || pages.isEmpty) return null;

    for (final page in pages) {
      final title = (page as Map<String, dynamic>)['title'] as String?;
      if (title != null && title.isNotEmpty) return title;
    }
    return null;
  }
}
