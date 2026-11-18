import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/event_model.dart';

class EventService {
  static const allowedStatuses = {'draft', 'published', 'cancelled'};

  EventService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  Stream<List<EventModel>> watchAllEvents() => _events.snapshots().map(
    (snapshot) => _sortByCreatedAt(snapshot.docs.map(EventModel.fromDocument)),
  );

  Stream<List<EventModel>> watchPublishedEvents() => _events
      .where('status', isEqualTo: 'published')
      .snapshots()
      .map(
        (snapshot) => _sortByStart(snapshot.docs.map(EventModel.fromDocument)),
      );

  Future<EventModel?> getEvent(String eventId) async {
    final document = await _events.doc(eventId).get();
    return document.exists ? EventModel.fromDocument(document) : null;
  }

  Future<String> createEvent({
    required String title,
    required String description,
    required String category,
    required String venue,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
    required String status,
    String? posterUrl,
    String? attendanceFormUrl,
  }) async {
    _validateStatus(status);
    final user = _auth.currentUser;
    if (user == null) throw const EventFailure('Please sign in again.');
    final reference = await _events.add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'venue': venue.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'capacity': capacity,
      'status': status,
      if (posterUrl != null && posterUrl.isNotEmpty) 'posterUrl': posterUrl,
      if (attendanceFormUrl != null && attendanceFormUrl.trim().isNotEmpty)
        'attendanceFormUrl': attendanceFormUrl.trim(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> updateEvent({
    required EventModel event,
    required String title,
    required String description,
    required String category,
    required String venue,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
    required String status,
    String? posterUrl,
    String? attendanceFormUrl,
  }) {
    _validateStatus(status);
    return _events.doc(event.id).update({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'venue': venue.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'capacity': capacity,
      'status': status,
      'posterUrl': posterUrl ?? event.posterUrl ?? '',
      'attendanceFormUrl':
          attendanceFormUrl?.trim() ?? event.attendanceFormUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(EventModel event, String status) {
    _validateStatus(status);
    return _events.doc(event.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadPoster({
    required String eventId,
    required String path,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/mtiqujbg/image/upload'),
          )
          ..fields['upload_preset'] = 'event_buddy_posters'
          ..fields['folder'] = 'event_posters'
          ..files.add(await http.MultipartFile.fromPath('file', path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      throw EventFailure(
        error is Map
            ? (error['message'] as String? ?? 'Cloudinary upload failed.')
            : 'Cloudinary upload failed.',
      );
    }
    final url = data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const EventFailure('Cloudinary did not return an image URL.');
    }
    await _events.doc(eventId).update({'posterUrl': url});
    return url;
  }

  Future<void> deleteEvent(String eventId) => _events.doc(eventId).delete();

  void _validateStatus(String status) {
    if (!allowedStatuses.contains(status)) {
      throw EventFailure('Unsupported event status: $status');
    }
  }

  List<EventModel> _sortByStart(Iterable<EventModel> events) {
    final result = events.toList();
    result.sort((a, b) => b.startAt.compareTo(a.startAt));
    return result;
  }

  List<EventModel> _sortByCreatedAt(Iterable<EventModel> events) {
    final result = events.toList();
    result.sort(
      (a, b) => (b.createdAt ?? b.startAt).compareTo(a.createdAt ?? a.startAt),
    );
    return result;
  }
}

class EventFailure implements Exception {
  const EventFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
