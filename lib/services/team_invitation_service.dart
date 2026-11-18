import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/team_invitation.dart';

class TeamInvitationService {
  TeamInvitationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _firestore.collection('team_invitations');

  Future<void> sendInvitation({
    required String fullName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Please sign in again before sending an invitation.');
    }

    final invitation = _invitations.doc();
    await invitation.set({
      'fullName': fullName.trim(),
      'email': normalizedEmail,
      'status': 'pending',
      'invitedBy': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
    });

    try {
      await _auth.sendSignInLinkToEmail(
        email: normalizedEmail,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://event-buddy-a5fbd.web.app/finishSignIn',
          handleCodeInApp: true,
          androidPackageName: 'com.eventbuddy.app',
          androidInstallApp: true,
          androidMinimumVersion: '1',
          iOSBundleId: 'com.example.eventBuddy',
        ),
      );
    } catch (_) {
      await invitation.update({
        'status': 'send_failed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      rethrow;
    }
  }

  Stream<List<TeamInvitation>> watchInvitations() {
    return _invitations
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeamInvitation.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> cancelInvitation(String invitationId) {
    return _invitations.doc(invitationId).update({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteInvitation(String invitationId) {
    return _invitations.doc(invitationId).delete();
  }

  Future<void> acceptInvitation({
    required String email,
    required String emailLink,
  }) async {
    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw StateError('This invitation link is invalid or has expired.');
    }

    final credential = await _auth.signInWithEmailLink(
      email: email.trim().toLowerCase(),
      emailLink: emailLink,
    );
    final user = credential.user;
    if (user == null) throw StateError('Could not verify this invitation.');

    final query = await _invitations
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('status', isEqualTo: 'pending')
        .get();
    final now = DateTime.now();
    final available = query.docs
        .map((doc) => TeamInvitation.fromMap(doc.id, doc.data()))
        .where((invitation) => invitation.expiresAt.isAfter(now))
        .toList();
    available.sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
    if (available.isEmpty) {
      await _auth.signOut();
      throw StateError('No active invitation was found for this email.');
    }

    final invitation = available.first;
    await user.updateDisplayName(invitation.fullName);
    await _firestore.collection('users').doc(user.uid).set({
      'fullName': invitation.fullName,
      'email': email.trim().toLowerCase(),
      'studentId': null,
      'phoneNumber': null,
      'photoUrl': null,
      'role': 'organizer',
      'invitationId': invitation.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _invitations.doc(invitation.id).update({
      'status': 'accepted',
      'acceptedUid': user.uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }
}
