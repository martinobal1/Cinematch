import 'package:cloud_firestore/cloud_firestore.dart';

class UserMovieRating {
  const UserMovieRating({
    required this.id,
    required this.title,
    required this.year,
    required this.stars,
    required this.ratedAt,
    this.posterUrl,
    this.englishTitle,
    this.imdbRating,
    this.csfdRating,
  });

  final String id;
  final String title;
  final int year;
  final int stars;
  final DateTime ratedAt;
  final String? posterUrl;
  final String? englishTitle;
  final double? imdbRating;
  final int? csfdRating;

  factory UserMovieRating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['ratedAt'];
    DateTime ratedAt;
    if (ts is Timestamp) {
      ratedAt = ts.toDate();
    } else if (ts is DateTime) {
      ratedAt = ts;
    } else {
      ratedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserMovieRating(
      id: doc.id,
      title: data['title'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      stars: (data['stars'] as num?)?.toInt() ?? 0,
      ratedAt: ratedAt,
      posterUrl: data['posterUrl'] as String?,
      englishTitle: data['englishTitle'] as String?,
      imdbRating: (data['imdbRating'] as num?)?.toDouble(),
      csfdRating: (data['csfdRating'] as num?)?.toInt(),
    );
  }
}
