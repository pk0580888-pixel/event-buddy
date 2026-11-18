class TeamInvitation {
  const TeamInvitation({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.expiresAt,
    this.acceptedUid,
  });

  final String id;
  final String fullName;
  final String email;
  final String status;
  final DateTime expiresAt;
  final String? acceptedUid;

  bool get isPending =>
      status == 'pending' && expiresAt.isAfter(DateTime.now());

  factory TeamInvitation.fromMap(String id, Map<String, dynamic> data) {
    final expiry = data['expiresAt'];
    return TeamInvitation(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      expiresAt: expiry is DateTime
          ? expiry
          : expiry?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      acceptedUid: data['acceptedUid'] as String?,
    );
  }
}
