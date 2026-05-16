import 'movie_recommendation.dart';

/// Film zoradený podľa priemeru IMDb + ČSFD (škála 0–100).
class RankedMovie {
  const RankedMovie({
    required this.title,
    required this.year,
    required this.combinedAverage,
    this.posterUrl,
    this.englishTitle,
    this.imdbRating,
    this.csfdRating,
    this.userStars,
    this.tmdbVote,
  });

  final String title;
  final int year;
  final String? posterUrl;
  final String? englishTitle;
  final double? imdbRating;
  final int? csfdRating;
  final int? userStars;
  /// TMDB vote_average (záloha zoradenia).
  final double? tmdbVote;
  /// Priemer IMDb (×10) a ČSFD (%) na škále 0–100.
  final double combinedAverage;

  double get sortScore {
    final external = computeCombinedAverage(
      imdbRating: imdbRating,
      csfdRating: csfdRating,
    );
    if (external != null) return external;
    if (tmdbVote != null && tmdbVote! > 0) return tmdbVote! * 10;
    return combinedAverage;
  }

  /// IMDb prepočítané na percentá (8.2 → 82).
  double? get imdbPercent =>
      imdbRating != null ? (imdbRating! * 10).clamp(0, 100) : null;

  static double? computeCombinedAverage({
    double? imdbRating,
    int? csfdRating,
  }) {
    final parts = <double>[];
    if (imdbRating != null) parts.add((imdbRating * 10).clamp(0, 100));
    if (csfdRating != null) parts.add(csfdRating.clamp(0, 100).toDouble());
    if (parts.isEmpty) return null;
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  static String movieKey(String title, int year) =>
      '${title.trim().toLowerCase()}_$year';

  factory RankedMovie.fromRecommendation(
    MovieRecommendation movie, {
    int? userStars,
    double? tmdbVote,
  }) {
    final avg = computeCombinedAverage(
      imdbRating: movie.imdbRating,
      csfdRating: movie.csfdRating,
    );
    return RankedMovie(
      title: movie.title,
      year: movie.year,
      posterUrl: movie.posterUrl,
      englishTitle: movie.englishTitle,
      imdbRating: movie.imdbRating,
      csfdRating: movie.csfdRating,
      userStars: userStars,
      tmdbVote: tmdbVote,
      combinedAverage: avg ?? (tmdbVote != null ? tmdbVote * 10 : 0),
    );
  }

  factory RankedMovie.fromTmdb({
    required MovieRecommendation movie,
    required double tmdbVote,
    int? userStars,
  }) {
    return RankedMovie(
      title: movie.title,
      year: movie.year,
      posterUrl: movie.posterUrl,
      englishTitle: movie.englishTitle,
      imdbRating: movie.imdbRating,
      csfdRating: movie.csfdRating,
      userStars: userStars,
      tmdbVote: tmdbVote,
      combinedAverage: tmdbVote * 10,
    );
  }

  bool get hasExternalRatings => imdbRating != null || csfdRating != null;

  MovieRecommendation toRecommendation() {
    final trailer = englishTitle ?? title;
    return MovieRecommendation(
      title: title,
      year: year,
      englishTitle: englishTitle,
      reason:
          'Globálny rebríček TOP 100 — zoradené podľa priemeru hodnotení IMDb a ČSFD.',
      moodTags: const [],
      moodColors: const [0xFF1a1a2e, 0xFF533483, 0xFFe94560],
      posterUrl: posterUrl,
      imdbRating: imdbRating,
      csfdRating: csfdRating,
      trailerQuery: '$trailer $year official trailer',
    );
  }
}
