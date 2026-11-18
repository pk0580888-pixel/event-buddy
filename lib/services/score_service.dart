import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/score_model.dart';

class ScoreService {
  ScoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<ScoreModel>> watchMyScores() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <ScoreModel>[]);
    return _firestore
        .collection('scores')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ScoreModel.fromDocument).toList());
  }

  Stream<List<ScoreModel>> watchScoresForEvent(String eventId) {
    return _firestore
        .collection('scores')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final scores = snapshot.docs.map(ScoreModel.fromDocument).toList();
          scores.sort((a, b) => b.score.compareTo(a.score));
          return scores;
        });
  }

  Future<List<ScoreModel>> getScoresForEvent(String eventId) async {
    final snapshot = await _firestore
        .collection('scores')
        .where('eventId', isEqualTo: eventId)
        .get();
    final scores = snapshot.docs.map(ScoreModel.fromDocument).toList();
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  Future<void> assignScore({
    required String userId,
    required String eventId,
    required String eventTitle,
    required int score,
    required String remarks,
  }) {
    if (score < 0 || score > 100) {
      throw const ScoreFailure('Score must be between 0 and 100.');
    }
    return _firestore.collection('scores').doc('${userId}_$eventId').set({
      'userId': userId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'score': score,
      'remarks': remarks.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class ScoreFailure implements Exception {
  const ScoreFailure(this.message);
  final String message;
}
