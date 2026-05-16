import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/movie_recommendation.dart';

/// Doplní IMDb (OMDb) a ČSFD hodnotenia k odporúčaniam.
class RatingService {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/json',
    'Accept-Language': 'sk-SK,sk;q=0.9,en;q=0.8',
  };

  Future<RecommendationResult> enrichWithRatings(
    RecommendationResult result,
  ) async {
    final movies = await Future.wait(
      result.movies.map(_enrichMovie),
    );
    return RecommendationResult(summary: result.summary, movies: movies);
  }

  Future<MovieRecommendation> _enrichMovie(MovieRecommendation movie) async {
    var imdb = movie.imdbRating;
    var csfd = movie.csfdRating;

    final omdbImdb = await _fetchOmdbImdb(movie);
    if (omdbImdb != null) imdb = omdbImdb;

    final csfdData = await _fetchCsfd(movie);
    if (csfdData.$1 != null) csfd = csfdData.$1;
    if (csfdData.$2 != null && imdb == null) imdb = csfdData.$2;

    if (imdb == movie.imdbRating && csfd == movie.csfdRating) {
      return movie;
    }
    return movie.copyWith(imdbRating: imdb, csfdRating: csfd);
  }

  Future<double?> _fetchOmdbImdb(MovieRecommendation movie) async {
    if (!AppConfig.hasOmdb) return null;

    final title = movie.englishTitle ?? movie.title;
    final params = <String, String>{
      'apikey': AppConfig.effectiveOmdbKey,
      't': title,
      'type': 'movie',
      'r': 'json',
    };
    if (movie.year > 0) params['y'] = '${movie.year}';

    final uri = Uri.https('www.omdbapi.com', '/', params);
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['Response'] != 'True') return null;
      return _parseImdbValue(data['imdbRating']);
    } catch (_) {
      return null;
    }
  }

  /// Vráti (csfdPercent, imdbFromCsfdPage).
  Future<(int?, double?)> _fetchCsfd(MovieRecommendation movie) async {
    final filmId = await _csfdSearchFilmId(movie);
    if (filmId == null) return (null, null);
    return _csfdFilmRatings(filmId);
  }

  Future<int?> _csfdSearchFilmId(MovieRecommendation movie) async {
    for (final query in _csfdQueries(movie)) {
      final id = await _csfdSearchFilmIdForQuery(query, movie.year);
      if (id != null) return id;
    }
    return null;
  }

  List<String> _csfdQueries(MovieRecommendation movie) {
    final ordered = <String>[];
    final seen = <String>{};

    void add(String? value) {
      if (value == null) return;
      final t = value.trim();
      if (t.length < 2 || !seen.add(t)) return;
      ordered.add(t);
    }

    add(movie.title);
    add(movie.englishTitle);
    if (movie.englishTitle != null && movie.year > 0) {
      add('${movie.englishTitle} ${movie.year}');
    }
    if (movie.year > 0) add('${movie.title} ${movie.year}');
    return ordered;
  }

  Future<int?> _csfdSearchFilmIdForQuery(String query, int year) async {
    final uri = Uri.https(
      'www.csfd.cz',
      '/sk/hledat/',
      {'q': query},
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final html = response.body;
      if (_isBotChallenge(html)) return null;

      final candidates = _parseCsfdSearchCandidates(html);
      if (candidates.isEmpty) return null;

      if (year > 0) {
        final exact = candidates.where((c) => c.year == year).toList();
        if (exact.isNotEmpty) return exact.first.id;
        final close = candidates
            .where((c) => c.year != null && (c.year! - year).abs() <= 1)
            .toList();
        if (close.isNotEmpty) return close.first.id;
      }
      return candidates.first.id;
    } catch (_) {
      return null;
    }
  }

  bool _isBotChallenge(String html) {
    final lower = html.toLowerCase();
    return lower.contains('not a bot') ||
        lower.contains('anubis') ||
        lower.contains('botstopper');
  }

  List<_CsfdCandidate> _parseCsfdSearchCandidates(String html) {
    final results = <_CsfdCandidate>[];
    final articleRe = RegExp(
      r'<article\b[^>]*>([\s\S]*?)</article>',
      caseSensitive: false,
    );

    for (final match in articleRe.allMatches(html)) {
      final block = match.group(1)!;
      if (!block.contains('film-title-name')) continue;

      final linkMatch = RegExp(
        r'class="film-title-name"[^>]*href="/film/(\d+)-',
        caseSensitive: false,
      ).firstMatch(block);
      if (linkMatch == null) continue;

      final id = int.tryParse(linkMatch.group(1)!);
      if (id == null) continue;

      final yearMatch = RegExp(
        r'class="info"[^>]*>\s*\((\d{4})\)',
        caseSensitive: false,
      ).firstMatch(block);

      results.add(
        _CsfdCandidate(
          id: id,
          year: yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null,
        ),
      );
    }
    return results;
  }

  Future<(int?, double?)> _csfdFilmRatings(int filmId) async {
    final uri = Uri.parse('https://www.csfd.cz/sk/film/$filmId/prehled/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return (null, null);

      final html = response.body;
      if (_isBotChallenge(html)) return (null, null);

      final csfd = _parseCsfdPercent(html);
      final imdb = _parseImdbFromCsfdPage(html);
      return (csfd, imdb);
    } catch (_) {
      return (null, null);
    }
  }

  int? _parseCsfdPercent(String html) {
    final match = RegExp(
      r'class="film-rating-average"[^>]*>\s*(\d+)\s*%',
      caseSensitive: false,
    ).firstMatch(html);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  double? _parseImdbFromCsfdPage(String html) {
    final patterns = [
      RegExp(r'IMDb[^0-9]{0,40}([\d.]+)\s*/\s*10', caseSensitive: false),
      RegExp(r'imdb[^0-9]{0,40}([\d.]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final value = _parseImdbValue(match.group(1));
        if (value != null) return value;
      }
    }
    return null;
  }

  double? _parseImdbValue(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty || text == 'N/A') return null;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 10) return null;
    return value;
  }
}

class _CsfdCandidate {
  const _CsfdCandidate({required this.id, this.year});
  final int id;
  final int? year;
}
