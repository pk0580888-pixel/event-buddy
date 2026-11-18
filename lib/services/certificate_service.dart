import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/event_model.dart';
import '../models/certificate_model.dart';
import '../models/user_profile.dart';

class CertificateService {
  Future<void> sharePublishedCertificate(CertificateModel certificate) async {
    final document = pw.Document();
    pw.MemoryImage? template;
    if (certificate.templateUrl.isNotEmpty) {
      try {
        template = pw.MemoryImage(
          await http.readBytes(Uri.parse(certificate.templateUrl)),
        );
      } catch (_) {
        template = null;
      }
    }
    final award = certificate.isAppreciation
        ? 'Certificate of Appreciation'
        : 'Certificate of Participation';
    final achievement = certificate.isAppreciation
        ? '${_ordinal(certificate.rank)} place • Score ${certificate.score}/100'
        : 'Participant • Score ${certificate.score}/100';
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Stack(
          children: [
            if (template != null)
              pw.Positioned.fill(
                child: pw.Image(template, fit: pw.BoxFit.cover),
              ),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(28),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      award,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    pw.Text(
                      'This certificate is proudly presented to',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      certificate.participantName.isEmpty
                          ? 'Student'
                          : certificate.participantName,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (certificate.studentId.isNotEmpty)
                      pw.Text(
                        'Student ID: ${certificate.studentId}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'for ${certificate.eventTitle}',
                      style: const pw.TextStyle(fontSize: 15),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      achievement,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.indigo,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final directory = await getTemporaryDirectory();
    final safeName = certificate.eventTitle.replaceAll(
      RegExp(r'[^a-zA-Z0-9]+'),
      '_',
    );
    final file = File('${directory.path}/${safeName}_certificate.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }

  Future<void> shareCertificate({
    required EventModel event,
    required UserProfile student,
    required int score,
    required int rank,
  }) async {
    final document = pw.Document();
    final award = rank <= 3
        ? 'Certificate of Appreciation'
        : 'Certificate of Participation';
    final achievement = rank <= 3
        ? '${_ordinal(rank)} place • Score $score/100'
        : 'Participant • Score $score/100';
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(34),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.indigo, width: 5),
            color: PdfColors.white,
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'EVENT BUDDY',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.indigo,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 22),
              pw.Text(
                award,
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This certificate is proudly presented to',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                student.fullName.isEmpty ? 'Student' : student.fullName,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if ((student.studentId ?? '').isNotEmpty)
                pw.Text(
                  'Student ID: ${student.studentId}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 14),
              pw.Text(
                'for ${event.title}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                achievement,
                style: pw.TextStyle(
                  fontSize: 15,
                  color: PdfColors.indigo,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Event Buddy',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    '${event.startAt.day}/${event.startAt.month}/${event.startAt.year}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final directory = await getTemporaryDirectory();
    final safeName = event.title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    final file = File('${directory.path}/${safeName}_certificate.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }

  String _ordinal(int value) {
    if (value == 1) return '1st';
    if (value == 2) return '2nd';
    return '3rd';
  }
}
