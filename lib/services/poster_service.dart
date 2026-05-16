import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/movie_recommendation.dart';

/// Plagáty: TMDB → Wikidata → Wikipédia (viac jazykov / viac pokusov).
class PosterService {
  static const _baseHeaders = {
    'User-Agent': 'CineMatchAI/1.0 (Flutter school project)',
    'Accept': 'application/json',
  };

  Map<String, String> get _tmdbHeaders {
    final token = AppConfig.effectiveTmdbToken;
    if (token.isNotEmpty) {
      return {..._baseHeaders, 'Authorization': 'Bearer $token'};
    }
    return _baseHeaders;
  }

  Future<MovieRecommendation> enrichMoviePoster(MovieRecommendation movie) =>
      _fetchPoster(movie);

  Future<RecommendationResult> enrichWithPosters(
    RecommendationResult result,
  ) async {
    final movies = await Future.wait(
      result.movies.map(_fetchPoster),
    );
    return RecommendationResult(summary: result.summary, movies: movies);
  }

  Future<MovieRecommendation> _fetchPoster(MovieRecommendation movie) async {
    for (final query in _searchQueries(movie)) {
      final url = _pickBest([
        await _tmdbPoster(query, movie.year),
        await _wikipediaPoster(query, language: 'en'),
        await _wikipediaPoster(query, language: 'sk'),
        await _wikidataPoster(query),
      ]);
      if (url != null) {
        return movie.copyWith(posterUrl: url);
      }
    }
    return movie;
  }

  String? _pickBest(List<String?> urls) {
    for (final url in urls) {
      if (url == null || url.isEmpty) continue;
      if (_isBadPosterUrl(url)) continue;
      return url;
    }
    return null;
  }

  bool _isBadPosterUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.svg') || lower.contains('logo.svg');
  }

  List<String> _searchQueries(MovieRecommendation movie) {
    final ordered = <String>[];
    final seen = <String>{};

    void add(String? value) {
      if (value == null) return;
      final t = value.trim();
      if (t.length < 2 || !seen.add(t)) return;
      ordered.add(t);
    }

    // Anglický názov vždy prvý — najspoľahlivejší pre plagáty.
    add(movie.englishTitle);
    if (movie.englishTitle != null && movie.year > 0) {
      add('${movie.englishTitle} ${movie.year}');
    }

    if (movie.trailerQuery != null) {
      add(
        movie.trailerQuery!
            .replaceAll(RegExp(r'official trailer', caseSensitive: false), '')
            .trim(),
      );
    }

    final latin = RegExp(r'[A-Za-z]{3,}').allMatches(movie.title);
    if (latin.isNotEmpty) {
      add(latin.map((m) => m.group(0)).join(' '));
    }

    add(movie.title);
    if (movie.year > 0) add('${movie.title} ${movie.year}');

    return ordered;
  }

  Future<String?> _tmdbPoster(String query, int year) async {
    if (!AppConfig.hasTmdb) return null;

    final params = <String, String>{
      'query': query,
      if (year > 0) 'year': '$year',
      'language': 'en-US',
    };
    final key = AppConfig.effectiveTmdbKey;
    if (key.isNotEmpty && AppConfig.effectiveTmdbToken.isEmpty) {
      params['api_key'] = key;
    }

    final uri = Uri.https('api.themoviedb.org', '/3/search/movie', params);

    try {
      final response = await http
          .get(uri, headers: _tmdbHeaders)
          .timeout(const Duration(seconds: 10));
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

  Future<String?> _wikidataPoster(String query) async {
    try {
      final entityId = await _wikidataSearch(query, language: 'en') ??
          await _wikidataSearch(query, language: 'sk');
      if (entityId == null) return null;
      return _wikidataImage(entityId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _wikidataSearch(String query, {required String language}) async {
    final uri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbsearchentities',
      'search': query,
      'language': language,
      'format': 'json',
      'origin': '*',
      'type': 'item',
      'limit': '5',
    });

    final response = await http
          .get(uri, headers: _baseHeaders)
          .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final search = data['search'] as List<dynamic>?;
    if (search == null || search.isEmpty) return null;

    for (final item in search) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String?;
      final desc = (map['description'] as String?)?.toLowerCase() ?? '';
      if (id == null) continue;
      if (desc.contains('film') ||
          desc.contains('movie') ||
          desc.contains('film') ||
          desc.contains('drama') ||
          desc.contains('horror') ||
          desc.contains('comedy') ||
          desc.isEmpty) {
        return id;
      }
    }
    return (search.first as Map<String, dynamic>)['id'] as String?;
  }

  Future<String?> _wikidataImage(String entityId) async {
    final uri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbgetentities',
      'ids': entityId,
      'props': 'claims',
      'format': 'json',
      'origin': '*',
    });

    final response = await http
        .get(uri, headers: _baseHeaders)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entities = data['entities'] as Map<String, dynamic>?;
    final entity = entities?[entityId] as Map<String, dynamic>?;
    final claims = entity?['claims'] as Map<String, dynamic>?;
    final p18 = claims?['P18'] as List<dynamic>?;
    if (p18 == null || p18.isEmpty) return null;

    final filename = _claimString(p18.first as Map<String, dynamic>);
    if (filename == null) return null;

    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded?width=500';
  }

  String? _claimString(Map<String, dynamic> claim) {
    final snak = claim['mainsnak'] as Map<String, dynamic>?;
    final datavalue = snak?['datavalue'] as Map<String, dynamic>?;
    return datavalue?['value'] as String?;
  }

  Future<String?> _wikipediaPoster(String query, {required String language}) async {
    try {
      final host = language == 'sk' ? 'sk.wikipedia.org' : 'en.wikipedia.org';
      final title = await _wikipediaPageTitle(query, host: host);
      if (title == null) return null;

      final pathTitle = title.replaceAll(' ', '_');
      final summaryUri = Uri.https(
        host,
        '/api/rest_v1/page/summary/$pathTitle',
      );

      final response = await http
          .get(summaryUri, headers: _baseHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final thumb = data['thumbnail'] as Map<String, dynamic>?;
      var url = thumb?['source'] as String?;
      if (url == null) return null;

      // Odstrániť UTM parametre — na webe môžu spôsobiť problémy.
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: {}).toString();

      if (url.contains('/thumb/') && url.contains('px-')) {
        url = url.replaceAll(RegExp(r'/\d+px-'), '/500px-');
      }
      return _isBadPosterUrl(url) ? null : url;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _wikipediaPageTitle(String query, {required String host}) async {
    final searchUri = Uri.https(
      host,
      '/w/rest.php/v1/search/title',
      {'q': '$query film', 'limit': '5'},
    );

    final response = await http
        .get(searchUri, headers: _baseHeaders)
        .timeout(const Duration(seconds: 10));
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
