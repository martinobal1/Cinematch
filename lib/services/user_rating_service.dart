import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/movie_recommendation.dart';
import '../models/user_movie_rating.dart';

class UserRatingService {
  UserRatingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('user_ratings');

  String _docId(String uid, String title, int year) {
    final slug = '${title}_$year'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${uid}_$slug';
  }

  Future<void> saveRating({
    required MovieRecommendation movie,
    required int stars,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw UserRatingException('Pre hodnotenie sa musíš prihlásiť.');
    }
    if (stars < 1 || stars > 5) {
      throw UserRatingException('Hodnotenie musí byť 1–5 hviezdičiek.');
    }

    final docId = _docId(uid, movie.title, movie.year);
    await _collection.doc(docId).set({
      'userId': uid,
      'title': movie.title,
      'year': movie.year,
      'stars': stars,
      'posterUrl': movie.posterUrl,
      'englishTitle': movie.englishTitle,
      if (movie.imdbRating != null) 'imdbRating': movie.imdbRating,
      if (movie.csfdRating != null) 'csfdRating': movie.csfdRating,
      'ratedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<UserMovieRating>> watchMyRatings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    // Bez orderBy vo Firestore — nevyžaduje composite index; zoradíme lokálne.
    return _collection.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(UserMovieRating.fromDoc).toList();
      list.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
      return list;
    });
  }

  Future<int?> getMyStarsFor(String title, int year) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _collection.doc(_docId(uid, title, year)).get();
    if (!doc.exists) return null;
    return (doc.data()?['stars'] as num?)?.toInt();
  }

  Future<void> deleteRating(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _collection.doc(docId).get();
    if (doc.data()?['userId'] == uid) {
      await _collection.doc(docId).delete();
    }
  }
}

class UserRatingException implements Exception {
  UserRatingException(this.message);
  final String message;

  @override
  String toString() => message;
}
