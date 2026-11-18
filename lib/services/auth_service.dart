import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile_service.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, UserProfileService? profiles})
    : _auth = auth ?? FirebaseAuth.instance,
      _profiles = profiles ?? UserProfileService();

  final FirebaseAuth _auth;
  final UserProfileService _profiles;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required String studentId,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Registration could not be completed.');
      }

      await user.updateDisplayName(fullName.trim());
      await _profiles.createStudentProfile(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        studentId: studentId.trim(),
        phoneNumber: phoneNumber.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } on FirebaseException catch (error) {
      throw AuthFailure(error.message ?? 'Could not save your profile.');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Login could not be completed.');
      }

      final profile = await _profiles.getProfile(user.uid);
      final roleAllowed = expectedRole == 'admin'
          ? profile?.isAdmin == true
          : profile?.role == expectedRole;
      if (profile == null || !roleAllowed) {
        await _auth.signOut();
        throw AuthFailure(
          expectedRole == 'admin'
              ? 'This account is not registered as an administrator.'
              : 'Please use the administrator login for this account.',
        );
      }
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AuthFailure(error.message ?? 'Could not load your user profile.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
