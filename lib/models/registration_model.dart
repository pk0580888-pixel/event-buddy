import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.participantName,
    required this.eventTitle,
    required this.status,
    required this.registeredAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String participantName;
  final String eventTitle;
  final String status;
  final DateTime? registeredAt;

  factory RegistrationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['registeredAt'];
    return RegistrationModel(
      id: document.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      participantName: data['participantName'] as String? ?? 'Student',
      eventTitle: data['eventTitle'] as String? ?? 'Event',
      status: data['status'] as String? ?? 'confirmed',
      registeredAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
