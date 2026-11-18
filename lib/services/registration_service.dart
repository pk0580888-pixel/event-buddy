import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../models/registration_model.dart';

class RegistrationService {
  RegistrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _firestore.collection('registrations');

  String _registrationId(String userId, String eventId) => '${userId}_$eventId';

  Future<bool> isRegistered(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snapshot = await _registrations
        .where('userId', isEqualTo: user.uid)
        .get();
    return snapshot.docs.any(
      (document) => document.data()['eventId'] == eventId,
    );
  }

  Future<void> register(EventModel event) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const RegistrationFailure('Please sign in again.');
    }
    if (!event.isPublished) {
      throw const RegistrationFailure(
        'This event is not open for registration.',
      );
    }
    if (!event.startAt.isAfter(DateTime.now())) {
      throw const RegistrationFailure('Registration is closed for this event.');
    }

    if (await isRegistered(event.id)) {
      throw const RegistrationFailure(
        'You are already registered for this event.',
      );
    }

    final reference = _registrations.doc(_registrationId(user.uid, event.id));
    await reference.set({
      'eventId': event.id,
      'eventTitle': event.title,
      'userId': user.uid,
      'email': user.email ?? '',
      'participantName': user.displayName ?? '',
      'status': 'confirmed',
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancel(RegistrationModel registration) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != registration.userId) {
      throw const RegistrationFailure('Please sign in again.');
    }

    await _registrations.doc(registration.id).delete();
  }

  Stream<List<RegistrationModel>> watchMyRegistrations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <RegistrationModel>[]);
    return _registrations.where('userId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final result = snapshot.docs.map(RegistrationModel.fromDocument).toList();
      result.sort(
        (a, b) => (b.registeredAt ?? DateTime(1970)).compareTo(
          a.registeredAt ?? DateTime(1970),
        ),
      );
      return result;
    });
  }

  Stream<List<RegistrationModel>> watchAllRegistrations() {
    return _registrations.snapshots().map((snapshot) {
      final result = snapshot.docs.map(RegistrationModel.fromDocument).toList();
      result.sort(
        (a, b) => (b.registeredAt ?? DateTime(1970)).compareTo(
          a.registeredAt ?? DateTime(1970),
        ),
      );
      return result;
    });
  }
}

class RegistrationFailure implements Exception {
  const RegistrationFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
