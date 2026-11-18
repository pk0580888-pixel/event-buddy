import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  const CertificateModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.participantName,
    required this.studentId,
    required this.score,
    required this.rank,
    required this.type,
    required this.templateUrl,
    this.publishedAt,
  });

  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final String participantName;
  final String studentId;
  final int score;
  final int rank;
  final String type;
  final String templateUrl;
  final DateTime? publishedAt;

  bool get isAppreciation => type == 'appreciation';

  factory CertificateModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['publishedAt'];
    return CertificateModel(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? 'Event',
      participantName: data['participantName'] as String? ?? 'Student',
      studentId: data['studentId'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      rank: (data['rank'] as num?)?.toInt() ?? 0,
      type: data['type'] as String? ?? 'participation',
      templateUrl: data['templateUrl'] as String? ?? '',
      publishedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
