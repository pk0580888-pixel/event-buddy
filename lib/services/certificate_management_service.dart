import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/certificate_model.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/score_model.dart';
import '../models/user_profile.dart';

class CertificateManagementService {
  CertificateManagementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _templates =>
      _firestore.collection('certificate_templates').doc('default');

  Stream<Map<String, String>> watchTemplates() {
    return _templates.snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return {
        'appreciation': data['appreciationUrl'] as String? ?? '',
        'participation': data['participationUrl'] as String? ?? '',
      };
    });
  }

  Future<String> uploadTemplate({
    required String type,
    required String path,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/mtiqujbg/image/upload'),
          )
          ..fields['upload_preset'] = 'event_buddy_posters'
          ..fields['folder'] = 'certificate_templates'
          ..files.add(await http.MultipartFile.fromPath('file', path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CertificateManagementFailure('Template upload failed.');
    }
    final url = data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const CertificateManagementFailure('No template URL returned.');
    }
    await _templates.set({
      '${type}Url': url,
      'updatedBy': _auth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<int> publishForEvent(EventModel event) async {
    final templateSnapshot = await _templates.get();
    final templateData = templateSnapshot.data() ?? <String, dynamic>{};
    final appreciationUrl = templateData['appreciationUrl'] as String? ?? '';
    final participationUrl = templateData['participationUrl'] as String? ?? '';
    if (appreciationUrl.isEmpty || participationUrl.isEmpty) {
      throw const CertificateManagementFailure(
        'Upload both certificate templates before publishing.',
      );
    }

    final registrationSnapshot = await _firestore
        .collection('registrations')
        .where('eventId', isEqualTo: event.id)
        .get();
    final registrations = registrationSnapshot.docs
        .map(RegistrationModel.fromDocument)
        .where((item) => item.status == 'confirmed')
        .toList();
    if (registrations.isEmpty) {
      throw const CertificateManagementFailure(
        'This event has no confirmed student registrations.',
      );
    }

    final scoreSnapshot = await _firestore
        .collection('scores')
        .where('eventId', isEqualTo: event.id)
        .get();
    final scores = scoreSnapshot.docs.map(ScoreModel.fromDocument).toList();
    final scoreByUser = {for (final score in scores) score.userId: score};
    final missing = registrations
        .where((registration) => !scoreByUser.containsKey(registration.userId))
        .toList();
    if (missing.isNotEmpty) {
      throw CertificateManagementFailure(
        'Assign scores to all ${registrations.length} registered students first. ${missing.length} score(s) are missing.',
      );
    }

    final profilesSnapshot = await _firestore.collection('users').get();
    final profiles = {
      for (final document in profilesSnapshot.docs)
        document.id: UserProfile.fromMap(document.id, document.data()),
    };
    final ranked =
        registrations
            .map((registration) => scoreByUser[registration.userId]!)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    final rankByUser = <String, int>{};
    for (var index = 0; index < ranked.length; index++) {
      rankByUser[ranked[index].userId] = index + 1;
    }

    final batch = _firestore.batch();
    for (final registration in registrations) {
      final score = scoreByUser[registration.userId]!;
      final profile = profiles[registration.userId];
      final rank = rankByUser[registration.userId]!;
      final type = rank <= 3 ? 'appreciation' : 'participation';
      final reference = _firestore
          .collection('certificates')
          .doc('${event.id}_${registration.userId}');
      batch.set(reference, {
        'userId': registration.userId,
        'eventId': event.id,
        'eventTitle': event.title,
        'participantName': profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : registration.participantName,
        'studentId': profile?.studentId ?? '',
        'score': score.score,
        'rank': rank,
        'type': type,
        'templateUrl': type == 'appreciation'
            ? appreciationUrl
            : participationUrl,
        'publishedAt': FieldValue.serverTimestamp(),
        'publishedBy': _auth.currentUser?.uid,
      });
    }
    await batch.commit();
    return registrations.length;
  }

  Stream<List<CertificateModel>> watchMyCertificates(String userId) {
    return _firestore
        .collection('certificates')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CertificateModel.fromDocument).toList(),
        );
  }
}

class CertificateManagementFailure implements Exception {
  const CertificateManagementFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
