import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/movie_recommendation.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> saveRecommendation({
    required String userPrompt,
    required RecommendationResult result,
  }) async {
    await _db.collection('recommendations').add({
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
    return _db
        .collection('recommendations')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
