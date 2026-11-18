import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement_model.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  Stream<List<AnnouncementModel>> watchPublished() {
    return _announcements
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map(_sorted);
  }

  Stream<List<AnnouncementModel>> watchAll() {
    return _announcements.snapshots().map(_sorted);
  }

  List<AnnouncementModel> _sorted(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final announcements = snapshot.docs
        .map(AnnouncementModel.fromDocument)
        .toList();
    announcements.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );
    return announcements;
  }

  Future<void> save({
    String? id,
    required String title,
    required String message,
    required bool isPublished,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AnnouncementFailure('Please sign in again.');
    if (title.trim().isEmpty || message.trim().isEmpty) {
      throw const AnnouncementFailure(
        'Enter a title and announcement message.',
      );
    }

    final data = <String, dynamic>{
      'title': title.trim(),
      'message': message.trim(),
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      data['createdBy'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      await _announcements.add(data);
    } else {
      await _announcements.doc(id).update(data);
    }
  }

  Future<void> delete(String id) => _announcements.doc(id).delete();
}

class AnnouncementFailure implements Exception {
  const AnnouncementFailure(this.message);
  final String message;
}
