import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.participantName,
    required this.registrationId,
    required this.scannedBy,
    required this.scannedAt,
  });

  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final String participantName;
  final String registrationId;
  final String scannedBy;
  final DateTime? scannedAt;

  factory AttendanceModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['scannedAt'];
    return AttendanceModel(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? 'Event',
      participantName: data['participantName'] as String? ?? 'Student',
      registrationId: data['registrationId'] as String? ?? '',
      scannedBy: data['scannedBy'] as String? ?? '',
      scannedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
