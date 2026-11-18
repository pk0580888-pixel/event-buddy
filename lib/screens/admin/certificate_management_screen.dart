import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../services/certificate_management_service.dart';
import '../../services/event_service.dart';

class CertificateManagementScreen extends StatefulWidget {
  const CertificateManagementScreen({super.key});

  @override
  State<CertificateManagementScreen> createState() =>
      _CertificateManagementScreenState();
}

class _CertificateManagementScreenState
    extends State<CertificateManagementScreen> {
  final _service = CertificateManagementService();
  EventModel? _selectedEvent;
  bool _busy = false;

  Future<void> _upload(String type) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.uploadTemplate(type: type, path: picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_label(type)} template uploaded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    final event = _selectedEvent;
    if (event == null) return;
    setState(() => _busy = true);
    try {
      final count = await _service.publishForEvent(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count certificates published successfully.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish certificates: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(String type) =>
      type == 'appreciation' ? 'Appreciation' : 'Participation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: StreamBuilder<Map<String, String>>(
        stream: _service.watchTemplates(),
        builder: (context, templateSnapshot) {
          final templates = templateSnapshot.data ?? const <String, String>{};
          return StreamBuilder<List<EventModel>>(
            stream: EventService().watchAllEvents(),
            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = eventSnapshot.data ?? const <EventModel>[];
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 48),
                children: [
                  const Text(
                    '1. Upload certificate templates',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload image templates with empty space for the student name and event details.',
                  ),
                  const SizedBox(height: 14),
                  _TemplateTile(
                    title: 'Certificate of Appreciation',
                    uploaded: templates['appreciation']?.isNotEmpty == true,
                    onUpload: _busy ? null : () => _upload('appreciation'),
                  ),
                  _TemplateTile(
                    title: 'Certificate of Participation',
                    uploaded: templates['participation']?.isNotEmpty == true,
                    onUpload: _busy ? null : () => _upload('participation'),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '2. Publish for an event',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select an event. Certificates can be published only after every registered student has a score.',
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    const Text('No events available.')
                  else
                    ...events.map(
                      (event) => Card(
                        color: _selectedEvent?.id == event.id
                            ? const Color(0xFFE9EEFF)
                            : null,
                        child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(event.title),
                          subtitle: Text('${event.category} • ${event.status}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _busy
                              ? null
                              : () => setState(() => _selectedEvent = event),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _selectedEvent == null || _busy
                        ? null
                        : _publish,
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(
                      _selectedEvent == null
                          ? 'Select an event first'
                          : 'Publish certificates for ${_selectedEvent!.title}',
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.title,
    required this.uploaded,
    required this.onUpload,
  });
  final String title;
  final bool uploaded;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(uploaded ? Icons.check_circle : Icons.upload_file_outlined),
      title: Text(title),
      subtitle: Text(uploaded ? 'Template uploaded' : 'No template uploaded'),
      trailing: TextButton(onPressed: onUpload, child: const Text('Upload')),
    ),
  );
}
