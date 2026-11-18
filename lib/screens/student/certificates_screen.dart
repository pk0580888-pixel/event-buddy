import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/certificate_model.dart';
import '../../services/certificate_management_service.dart';
import '../../services/certificate_service.dart';

class StudentCertificatesScreen extends StatelessWidget {
  const StudentCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My certificates')),
      body: StreamBuilder<List<CertificateModel>>(
        stream: CertificateManagementService().watchMyCertificates(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load certificates.'));
          }
          final certificates = snapshot.data ?? const <CertificateModel>[];
          if (certificates.isEmpty) {
            return const Center(
              child: Text(
                'Certificates will appear after the organizer publishes them.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: certificates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _CertificateCard(certificate: certificates[index]),
          );
        },
      ),
    );
  }
}

class _CertificateCard extends StatefulWidget {
  const _CertificateCard({required this.certificate});
  final CertificateModel certificate;

  @override
  State<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<_CertificateCard> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      await CertificateService().sharePublishedCertificate(widget.certificate);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download certificate: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        widget.certificate.isAppreciation
            ? Icons.emoji_events_outlined
            : Icons.workspace_premium_outlined,
      ),
      title: Text(widget.certificate.eventTitle),
      subtitle: Text(
        widget.certificate.isAppreciation
            ? 'Certificate of Appreciation • Rank ${widget.certificate.rank}'
            : 'Certificate of Participation',
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              onPressed: _download,
              icon: const Icon(Icons.download_outlined),
            ),
    ),
  );
}
