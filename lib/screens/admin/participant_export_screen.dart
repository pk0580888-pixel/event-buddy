import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/participant_export_service.dart';

class ParticipantExportScreen extends StatefulWidget {
  const ParticipantExportScreen({super.key});

  @override
  State<ParticipantExportScreen> createState() =>
      _ParticipantExportScreenState();
}

class _ParticipantExportScreenState extends State<ParticipantExportScreen> {
  final _service = ParticipantExportService();
  EventModel? _selectedEvent;
  List<ParticipantRecord>? _records;
  String? _error;
  bool _loadingRecords = false;
  bool _sharing = false;

  Future<void> _selectEvent(EventModel event) async {
    setState(() {
      _selectedEvent = event;
      _records = null;
      _error = null;
      _loadingRecords = true;
    });
    try {
      final records = await _service.loadRecords(eventId: event.id);
      if (mounted) {
        setState(() {
          _records = records;
          _loadingRecords = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load students for this event.';
          _loadingRecords = false;
        });
      }
    }
  }

  Future<void> _share(bool excel) async {
    final records = _records;
    final event = _selectedEvent;
    if (records == null || event == null) return;
    setState(() => _sharing = true);
    try {
      if (excel) {
        await _service.shareExcel(records, eventTitle: event.title);
      } else {
        await _service.sharePdf(records, eventTitle: event.title);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student records export')),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().watchAllEvents(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventSnapshot.hasError) {
            return const Center(child: Text('Could not load events.'));
          }
          final events = eventSnapshot.data ?? const <EventModel>[];
          if (events.isEmpty) {
            return const Center(child: Text('No events available for export.'));
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            children: [
              const Text(
                '1. Select an event',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose an event to view and download only its registered students.',
              ),
              const SizedBox(height: 14),
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
                    onTap: () => _selectEvent(event),
                  ),
                ),
              ),
              if (_selectedEvent != null) ...[
                const SizedBox(height: 20),
                Text(
                  '2. ${_selectedEvent!.title} participants',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingRecords)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(_error!)
                else ...[
                  Text('${_records!.length} registered student records'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _records!.isEmpty || _sharing
                        ? null
                        : () => _share(true),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Export Excel file'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _records!.isEmpty || _sharing
                        ? null
                        : () => _share(false),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export PDF file'),
                  ),
                  if (_sharing) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 12),
                  if (_records!.isEmpty)
                    const Text('No students registered for this event.')
                  else
                    ..._records!.map(
                      (record) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(
                            record.profile.fullName.isEmpty
                                ? 'Student'
                                : record.profile.fullName,
                          ),
                          subtitle: Text(
                            '${record.profile.studentId ?? 'No student ID'} • ${record.profile.email}\n${record.profile.phoneNumber ?? 'No phone number'}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
