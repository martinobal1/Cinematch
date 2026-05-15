import 'dart:convert';

class MovieRecommendation {
  const MovieRecommendation({
    required this.title,
    required this.year,
    required this.reason,
    required this.moodTags,
    required this.moodColors,
    this.trailerQuery,
    this.personalReview,
    this.posterUrl,
  });

  final String title;
  final int year;
  final String reason;
  final List<String> moodTags;
  final List<int> moodColors;
  final String? trailerQuery;
  final String? personalReview;
  final String? posterUrl;

  MovieRecommendation copyWith({String? posterUrl}) {
    return MovieRecommendation(
      title: title,
      year: year,
      reason: reason,
      moodTags: moodTags,
      moodColors: moodColors,
      trailerQuery: trailerQuery,
      personalReview: personalReview,
      posterUrl: posterUrl ?? this.posterUrl,
    );
  }

  factory MovieRecommendation.fromJson(Map<String, dynamic> json) {
    return MovieRecommendation(
      title: json['title'] as String? ?? 'Neznámy film',
      year: (json['year'] is int)
          ? json['year'] as int
          : int.tryParse('${json['year']}') ?? 0,
      reason: json['reason'] as String? ?? '',
      moodTags: (json['moodTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      moodColors: _parseColors(json['moodColors']),
      trailerQuery: json['trailerQuery'] as String?,
      personalReview: json['personalReview'] as String?,
    );
  }

  static List<int> _parseColors(dynamic raw) {
    if (raw is! List) return [0xFF1a1a2e, 0xFF16213e, 0xFF0f3460];
    return raw.map((c) {
      if (c is int) return c;
      final s = c.toString().replaceFirst('#', '');
      return int.tryParse(s, radix: 16) ?? 0xFF333333;
    }).toList();
  }
}

class RecommendationResult {
  const RecommendationResult({
    required this.movies,
    required this.summary,
  });

  final List<MovieRecommendation> movies;
  final String summary;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final moviesJson = json['movies'] as List<dynamic>? ?? [];
    return RecommendationResult(
      summary: json['summary'] as String? ?? '',
      movies: moviesJson
          .map((m) => MovieRecommendation.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  static RecommendationResult? tryParse(String raw) {
    try {
      final cleaned = _extractJson(raw);
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return RecommendationResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}
