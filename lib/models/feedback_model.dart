import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  const FeedbackModel({
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.rating,
    required this.comment,
    this.submittedAt,
  });

  final String userId;
  final String eventId;
  final String eventTitle;
  final int rating;
  final String comment;
  final DateTime? submittedAt;

  factory FeedbackModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['submittedAt'];
    return FeedbackModel(
      userId: data['userId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? 'Event',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      submittedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
