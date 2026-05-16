import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/movie_recommendation.dart';
import '../models/ranked_movie.dart';
import 'poster_service.dart';
import 'rating_service.dart';

typedef Top100Progress = void Function(int done, int total, List<RankedMovie> current);

/// Globálny TOP 100 — TMDB Top Rated + hodnotenia IMDb a ČSFD.
class Top100Service {
  Top100Service({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _ratings = RatingService();
  final _posters = PosterService();

  static const maxCount = 100;
  static const _batchSize = 5;

  static List<RankedMovie>? _cache;

  static const _tmdbHeaders = {
    'User-Agent': 'CineMatchAI/1.0 (Flutter school project)',
    'Accept': 'application/json',
  };

  Map<String, String> get _authTmdbHeaders {
    final token = AppConfig.effectiveTmdbToken;
    if (token.isNotEmpty) {
      return {..._tmdbHeaders, 'Authorization': 'Bearer $token'};
    }
    return _tmdbHeaders;
  }

  Future<List<RankedMovie>> loadTop100({Top100Progress? onProgress}) async {
    if (_cache != null && _cache!.isNotEmpty) {
      onProgress?.call(_cache!.length, _cache!.length, _cache!);
      return _cache!;
    }

    if (!AppConfig.hasTmdb) {
      throw Top100Exception(
        'Pre TOP 100 je potrebný TMDB API kľúč (plagáty + zoznam filmov).',
      );
    }

    final candidates = await _fetchTmdbTopRated();
    final userStars = await _loadUserStarsMap();

    var ranked = candidates
        .map(
          (c) => RankedMovie.fromTmdb(
            movie: c.movie,
            tmdbVote: c.voteAverage,
            userStars: userStars[RankedMovie.movieKey(c.movie.title, c.movie.year)],
          ),
        )
        .toList()
      ..sort((a, b) => b.sortScore.compareTo(a.sortScore));

    onProgress?.call(0, candidates.length, ranked.take(maxCount).toList());

    for (var i = 0; i < candidates.length; i += _batchSize) {
      final batch = candidates.skip(i).take(_batchSize).toList();
      final enriched = await Future.wait(
        batch.map((c) => _enrichCandidate(c, userStars)),
      );

      for (var j = 0; j < enriched.length; j++) {
        final key = RankedMovie.movieKey(
          batch[j].movie.title,
          batch[j].movie.year,
        );
        final index = ranked.indexWhere(
          (m) => RankedMovie.movieKey(m.title, m.year) == key,
        );
        if (index >= 0) {
          ranked[index] = enriched[j];
        }
      }

      ranked.sort((a, b) => b.sortScore.compareTo(a.sortScore));
      onProgress?.call(
        (i + batch.length).clamp(0, candidates.length),
        candidates.length,
        ranked.take(maxCount).toList(),
      );
    }

    final result = ranked.take(maxCount).toList();
    _cache = result;
    return result;
  }

  void clearCache() => _cache = null;

  Future<RankedMovie> _enrichCandidate(
    _TmdbCandidate candidate,
    Map<String, int> userStars,
  ) async {
    var movie = candidate.movie;
    if (movie.posterUrl == null || movie.posterUrl!.isEmpty) {
      movie = await _posters.enrichMoviePoster(movie);
    }

    movie = await _ratings.enrichMovieRatings(
      movie,
      tmdbId: candidate.tmdbId,
    );

    return RankedMovie.fromRecommendation(
      movie,
      tmdbVote: candidate.voteAverage,
      userStars: userStars[RankedMovie.movieKey(movie.title, movie.year)],
    );
  }

  Future<List<_TmdbCandidate>> _fetchTmdbTopRated() async {
    final movies = <_TmdbCandidate>[];

    for (var page = 1; page <= 5; page++) {
      final params = <String, String>{
        'language': 'sk-SK',
        'page': '$page',
      };
      final key = AppConfig.effectiveTmdbKey;
      if (key.isNotEmpty && AppConfig.effectiveTmdbToken.isEmpty) {
        params['api_key'] = key;
      }

      final uri = Uri.https('api.themoviedb.org', '/3/movie/top_rated', params);
      final response = await http
          .get(uri, headers: _authTmdbHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Top100Exception('TMDB top rated zlyhalo (${response.statusCode}).');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      for (final raw in results) {
        if (raw is! Map<String, dynamic>) continue;
        final candidate = _candidateFromTmdb(raw);
        if (candidate != null) movies.add(candidate);
      }
    }

    return movies.take(maxCount).toList();
  }

  _TmdbCandidate? _candidateFromTmdb(Map<String, dynamic> raw) {
    final title =
        (raw['title'] as String?)?.trim() ??
        (raw['original_title'] as String?)?.trim();
    final tmdbId = (raw['id'] as num?)?.toInt();
    if (title == null || title.isEmpty || tmdbId == null) return null;

    final english = raw['original_title'] as String?;
    final date = raw['release_date'] as String? ?? '';
    final year = int.tryParse(date.split('-').first) ?? 0;
    final posterPath = raw['poster_path'] as String?;
    final overview = raw['overview'] as String? ?? '';
    final vote = (raw['vote_average'] as num?)?.toDouble() ?? 0;

    final movie = MovieRecommendation(
      title: title,
      year: year,
      englishTitle: english,
      reason: overview.isNotEmpty ? overview : title,
      moodTags: const [],
      moodColors: const [0xFF1a1a2e, 0xFF533483, 0xFFe94560],
      posterUrl: posterPath != null && posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : null,
    );

    return _TmdbCandidate(
      tmdbId: tmdbId,
      movie: movie,
      voteAverage: vote,
    );
  }

  Future<Map<String, int>> _loadUserStarsMap() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final snap = await _db
        .collection('user_ratings')
        .where('userId', isEqualTo: uid)
        .get();

    final map = <String, int>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final title = d['title'] as String? ?? '';
      final year = (d['year'] as num?)?.toInt() ?? 0;
      final stars = (d['stars'] as num?)?.toInt();
      if (title.isNotEmpty && year > 0 && stars != null) {
        map[RankedMovie.movieKey(title, year)] = stars;
      }
    }
    return map;
  }
}

class _TmdbCandidate {
  const _TmdbCandidate({
    required this.tmdbId,
    required this.movie,
    required this.voteAverage,
  });

  final int tmdbId;
  final MovieRecommendation movie;
  final double voteAverage;
}

class Top100Exception implements Exception {
  Top100Exception(this.message);
  final String message;

  @override
  String toString() => message;
}
