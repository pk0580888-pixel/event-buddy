import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.isPublished,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String createdBy;
  final bool isPublished;
  final DateTime? createdAt;

  factory AnnouncementModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return AnnouncementModel(
      id: document.id,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
