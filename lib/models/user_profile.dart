class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.studentId,
    this.phoneNumber,
    this.photoUrl,
  });

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String? studentId;
  final String? phoneNumber;
  final String? photoUrl;

  bool get isAdmin => role == 'admin' || role == 'organizer';

  bool get isOrganizer => role == 'organizer';

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName:
          (data['fullName'] as String?) ?? (data['name'] as String?) ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      studentId: data['studentId'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
