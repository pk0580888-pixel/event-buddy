import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreModel {
  const ScoreModel({
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.score,
    required this.remarks,
    this.updatedAt,
  });

  final String userId;
  final String eventId;
  final String eventTitle;
  final int score;
  final String remarks;
  final DateTime? updatedAt;

  factory ScoreModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['updatedAt'];
    return ScoreModel(
      userId: data['userId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? 'Event',
      score: (data['score'] as num?)?.toInt() ?? 0,
      remarks: data['remarks'] as String? ?? '',
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
