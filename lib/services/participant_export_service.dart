import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/registration_model.dart';
import '../models/user_profile.dart';

class ParticipantExportService {
  ParticipantExportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ParticipantRecord>> loadRecords({String? eventId}) async {
    final profiles = await _firestore.collection('users').get();
    final registrations = await _firestore.collection('registrations').get();
    final registrationsByUser = <String, List<RegistrationModel>>{};
    for (final document in registrations.docs) {
      final registration = RegistrationModel.fromDocument(document);
      registrationsByUser
          .putIfAbsent(registration.userId, () => <RegistrationModel>[])
          .add(registration);
    }
    final selectedRegistrations = registrationsByUser.values
        .expand((items) => items)
        .where(
          (registration) =>
              registration.status == 'confirmed' &&
              (eventId == null || registration.eventId == eventId),
        )
        .toList();
    final registeredUserIds = selectedRegistrations
        .map((registration) => registration.userId)
        .toSet();
    final result = profiles.docs
        .map((document) => UserProfile.fromMap(document.id, document.data()))
        .where(
          (profile) =>
              profile.role != 'admin' &&
              (eventId == null || registeredUserIds.contains(profile.uid)),
        )
        .map(
          (profile) => ParticipantRecord(
            profile: profile,
            registrations: eventId == null
                ? registrationsByUser[profile.uid] ?? const []
                : selectedRegistrations
                      .where(
                        (registration) => registration.userId == profile.uid,
                      )
                      .toList(),
          ),
        )
        .toList();
    result.sort(
      (a, b) => a.profile.fullName.toLowerCase().compareTo(
        b.profile.fullName.toLowerCase(),
      ),
    );
    return result;
  }

  Future<void> shareExcel(
    List<ParticipantRecord> records, {
    String? eventTitle,
  }) async {
    final excel = Excel.createExcel();
    // Excel creates Sheet1 by default. Populate that first sheet so the
    // downloaded workbook never opens on an empty worksheet.
    final sheet = excel['Sheet1'];
    sheet.appendRow(
      _excelRow(['Name', 'Student ID', 'Email', 'Phone', 'Registered events']),
    );
    for (final record in records) {
      sheet.appendRow(
        _excelRow([
          record.profile.fullName,
          record.profile.studentId ?? '',
          record.profile.email,
          record.profile.phoneNumber ?? '',
          record.registrations.map((item) => item.eventTitle).join(', '),
        ]),
      );
    }
    final bytes = excel.save();
    if (bytes == null) {
      throw const ExportFailure('Could not create Excel file.');
    }
    final file = await _writeFile(
      '${_safeName(eventTitle ?? 'all_students')}_students.xlsx',
      bytes,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
      ),
    );
  }

  Future<void> sharePdf(
    List<ParticipantRecord> records, {
    String? eventTitle,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Event Buddy - ${eventTitle ?? 'Student Records'}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Name',
              'Student ID',
              'Email',
              'Phone',
              'Registered events',
            ],
            data: records
                .map(
                  (record) => [
                    record.profile.fullName,
                    record.profile.studentId ?? '',
                    record.profile.email,
                    record.profile.phoneNumber ?? '',
                    record.registrations
                        .map((item) => item.eventTitle)
                        .join(', '),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    final file = await _writeFile(
      '${_safeName(eventTitle ?? 'all_students')}_students.pdf',
      await document.save(),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }

  List<CellValue> _excelRow(List<String> values) =>
      values.map((value) => TextCellValue(value)).toList();

  Future<File> _writeFile(String name, List<int> bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }

  String _safeName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class ParticipantRecord {
  const ParticipantRecord({required this.profile, required this.registrations});
  final UserProfile profile;
  final List<RegistrationModel> registrations;
}

class ExportFailure implements Exception {
  const ExportFailure(this.message);
  final String message;
}
