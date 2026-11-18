import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attendance_model.dart';
import '../models/registration_model.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection('attendance');

  Future<AttendanceScanResult> markFromQr(String payload) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      throw const AttendanceFailure(
        'Please sign in again as an administrator.',
      );
    }

    final fields = _parsePayload(payload);
    if (fields['type'] != 'EVENT_BUDDY_PASS' ||
        _isBlank(fields['userId']) ||
        _isBlank(fields['eventId']) ||
        _isBlank(fields['registrationId'])) {
      throw const AttendanceFailure('This is not a valid Event Buddy pass.');
    }

    final registration = await _firestore
        .collection('registrations')
        .doc(fields['registrationId'])
        .get();
    final data = registration.data();
    if (!registration.exists || data == null) {
      throw const AttendanceFailure('Registration not found.');
    }
    if (data['userId'] != fields['userId'] ||
        data['eventId'] != fields['eventId'] ||
        data['status'] != 'confirmed') {
      throw const AttendanceFailure(
        'This pass is not valid for this registration.',
      );
    }

    return _markRegistration(
      registrationId: registration.id,
      data: data,
      adminUid: admin.uid,
      method: 'qr',
    );
  }

  Future<AttendanceScanResult> markManual(
    RegistrationModel registration,
  ) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      throw const AttendanceFailure(
        'Please sign in again as an administrator.',
      );
    }
    if (registration.status != 'confirmed') {
      throw const AttendanceFailure(
        'Only confirmed registrations can be marked.',
      );
    }

    final registrationSnapshot = await _firestore
        .collection('registrations')
        .doc(registration.id)
        .get();
    final data = registrationSnapshot.data();
    if (!registrationSnapshot.exists || data == null) {
      throw const AttendanceFailure('Registration not found.');
    }
    if (data['userId'] != registration.userId ||
        data['eventId'] != registration.eventId ||
        data['status'] != 'confirmed') {
      throw const AttendanceFailure('This registration is no longer valid.');
    }

    return _markRegistration(
      registrationId: registrationSnapshot.id,
      data: data,
      adminUid: admin.uid,
      method: 'manual',
    );
  }

  Future<AttendanceScanResult> _markRegistration({
    required String registrationId,
    required Map<String, dynamic> data,
    required String adminUid,
    required String method,
  }) async {
    final userId = data['userId'] as String? ?? '';
    final eventId = data['eventId'] as String? ?? '';
    if (userId.isEmpty || eventId.isEmpty) {
      throw const AttendanceFailure(
        'Registration is missing student or event details.',
      );
    }

    final attendanceId = '${userId}_$eventId';
    final existing = await _attendance.doc(attendanceId).get();
    if (existing.exists) {
      return AttendanceScanResult(
        attendance: AttendanceModel.fromDocument(existing),
        alreadyMarked: true,
      );
    }

    final reference = _attendance.doc(attendanceId);
    await reference.set({
      'userId': userId,
      'eventId': eventId,
      'eventTitle': data['eventTitle'] as String? ?? 'Event',
      'participantName': data['participantName'] as String? ?? 'Student',
      'registrationId': registrationId,
      'scannedBy': adminUid,
      'scannedAt': FieldValue.serverTimestamp(),
      'method': method,
    });

    final saved = await reference.get();
    return AttendanceScanResult(
      attendance: AttendanceModel.fromDocument(saved),
      alreadyMarked: false,
    );
  }

  Stream<List<AttendanceModel>> watchForStudent(String userId) {
    return _attendance.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final result = snapshot.docs.map(AttendanceModel.fromDocument).toList();
      result.sort(
        (a, b) => (b.scannedAt ?? DateTime(1970)).compareTo(
          a.scannedAt ?? DateTime(1970),
        ),
      );
      return result;
    });
  }

  Map<String, String> _parsePayload(String payload) {
    final result = <String, String>{};
    for (final line in payload.split('\n')) {
      final separator = line.indexOf(':');
      if (separator < 0) {
        if (line.trim() == 'EVENT_BUDDY_PASS') result['type'] = line.trim();
        continue;
      }
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      switch (key) {
        case 'Student UID':
          result['userId'] = value;
        case 'Event ID':
          result['eventId'] = value;
        case 'Registration ID':
          result['registrationId'] = value;
        case 'Student':
          result['participantName'] = value;
        case 'Event':
          result['eventTitle'] = value;
      }
    }
    return result;
  }

  bool _isBlank(String? value) => value == null || value.isEmpty;
}

class AttendanceScanResult {
  const AttendanceScanResult({
    required this.attendance,
    required this.alreadyMarked,
  });

  final AttendanceModel attendance;
  final bool alreadyMarked;
}

class AttendanceFailure implements Exception {
  const AttendanceFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
