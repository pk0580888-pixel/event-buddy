import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feedback_model.dart';

class FeedbackService {
  FeedbackService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _feedback =>
      _firestore.collection('feedback');

  String _id(String userId, String eventId) => '${userId}_$eventId';

  Future<FeedbackModel?> getMyFeedback(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _feedback.where('userId', isEqualTo: user.uid).get();
    for (final document in snapshot.docs) {
      if (document.data()['eventId'] == eventId) {
        return FeedbackModel.fromDocument(document);
      }
    }
    return null;
  }

  Future<void> submit({
    required String eventId,
    required String eventTitle,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const FeedbackFailure('Please sign in again.');
    if (rating < 1 || rating > 5) {
      throw const FeedbackFailure('Choose a rating from 1 to 5.');
    }

    await _feedback.doc(_id(user.uid, eventId)).set({
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': user.uid,
      'rating': rating,
      'comment': comment.trim(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FeedbackModel>> watchAllFeedback() {
    return _feedback.snapshots().map((snapshot) {
      final feedback = snapshot.docs.map(FeedbackModel.fromDocument).toList();
      feedback.sort(
        (a, b) => (b.submittedAt ?? DateTime(1970)).compareTo(
          a.submittedAt ?? DateTime(1970),
        ),
      );
      return feedback;
    });
  }
}

class FeedbackFailure implements Exception {
  const FeedbackFailure(this.message);
  final String message;
}
