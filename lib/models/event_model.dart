import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.venue,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.status,
    required this.createdBy,
    this.posterUrl,
    this.attendanceFormUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String venue;
  final DateTime startAt;
  final DateTime endAt;
  final int capacity;
  final String status;
  final String createdBy;
  final String? posterUrl;
  final String? attendanceFormUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status == 'published';
  bool get isCancelled => status == 'cancelled';

  factory EventModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final legacyDate = _date(data['eventDate']) ?? DateTime.now();
    final start = _date(data['startAt']) ?? legacyDate;
    final end = _date(data['endAt']) ?? start.add(const Duration(hours: 1));
    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled event',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      venue: data['venue'] as String? ?? 'Venue not specified',
      startAt: start,
      endAt: end,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      status: _status(data['status'] as String?),
      createdBy: data['createdBy'] as String? ?? '',
      posterUrl: data['posterUrl'] as String?,
      attendanceFormUrl: data['attendanceFormUrl'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _status(String? value) {
    switch (value?.toLowerCase()) {
      case 'published':
        return 'published';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return 'draft';
    }
  }
}
