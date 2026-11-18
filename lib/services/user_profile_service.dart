import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('users');

  Future<void> createStudentProfile({
    required String uid,
    required String fullName,
    required String email,
    required String studentId,
    required String phoneNumber,
  }) {
    return _profiles.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'studentId': studentId,
      'phoneNumber': phoneNumber,
      'photoUrl': null,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return snapshot.exists && data != null
          ? UserProfile.fromMap(uid, data)
          : null;
    });
  }

  Future<void> updateStudentProfile({
    required String uid,
    required String fullName,
    required String email,
    required String studentId,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) {
      throw StateError('Please sign in again before updating your profile.');
    }

    await user.updateDisplayName(fullName.trim());
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      await user.updatePhotoURL(photoUrl.trim());
    }
    if (user.email?.trim().toLowerCase() != email.trim().toLowerCase()) {
      // Newer Firebase Auth versions require email verification before the
      // sign-in email is changed. The profile is updated below and the Auth
      // email becomes active after the student confirms the link.
      await user.verifyBeforeUpdateEmail(email.trim());
    }

    await _profiles.doc(uid).update({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'studentId': studentId.trim(),
      'phoneNumber': phoneNumber.trim(),
      if (photoUrl != null && photoUrl.trim().isNotEmpty)
        'photoUrl': photoUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadProfileImage({
    required String filePath,
    required String uid,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/mtiqujbg/image/upload'),
          )
          ..fields['upload_preset'] = 'event_buddy_posters'
          ..fields['public_id'] = 'student_profiles/$uid'
          ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Profile image upload failed. Please try again.');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Cloudinary did not return an image URL.');
    }
    return url;
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  Stream<List<UserProfile>> watchParticipants() {
    return _profiles.snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map((document) => UserProfile.fromMap(document.id, document.data()))
          .where((profile) => profile.role != 'admin')
          .toList();
      profiles.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return profiles;
    });
  }

  Stream<List<UserProfile>> watchStudents() {
    return _profiles.snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map((document) => UserProfile.fromMap(document.id, document.data()))
          .where(
            (profile) =>
                profile.role == 'student' || profile.role == 'participant',
          )
          .toList();
      profiles.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return profiles;
    });
  }

  Stream<List<UserProfile>> watchTeamMembers() {
    return _profiles.snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map((document) => UserProfile.fromMap(document.id, document.data()))
          .where((profile) => profile.role != 'student')
          .toList();
      profiles.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return profiles;
    });
  }

  Stream<List<UserProfile>> watchAllProfiles() {
    return _profiles.snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map((document) => UserProfile.fromMap(document.id, document.data()))
          .where((profile) => profile.role != 'admin')
          .toList();
      profiles.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return profiles;
    });
  }

  Future<void> setOrganizerAccess({
    required String uid,
    required bool enabled,
  }) {
    return _profiles.doc(uid).update({
      'role': enabled ? 'organizer' : 'student',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProfile(String uid) {
    return _profiles.doc(uid).delete();
  }
}
