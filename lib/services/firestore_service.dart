import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/movie_recommendation.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> saveRecommendation({
    required String userPrompt,
    required RecommendationResult result,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirestoreException('Pre uloženie sa musíš prihlásiť.');
    }

    await _db.collection('recommendations').add({
      'userId': uid,
      'userPrompt': userPrompt,
      'summary': result.summary,
      'movies': result.movies
          .map(
            (m) => {
              'title': m.title,
              'year': m.year,
              'reason': m.reason,
              'moodTags': m.moodTags,
              'moodColors': m.moodColors,
              if (m.imdbRating != null) 'imdbRating': m.imdbRating,
              if (m.csfdRating != null) 'csfdRating': m.csfdRating,
            },
          )
          .toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHistory({int limit = 10}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _db
        .collection('recommendations')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}

class FirestoreException implements Exception {
  FirestoreException(this.message);
  final String message;

  @override
  String toString() => message;
}
