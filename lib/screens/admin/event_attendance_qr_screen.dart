import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventAttendanceQrScreen extends StatefulWidget {
  const EventAttendanceQrScreen({super.key});

  @override
  State<EventAttendanceQrScreen> createState() =>
      _EventAttendanceQrScreenState();
}

class _EventAttendanceQrScreenState extends State<EventAttendanceQrScreen> {
  EventModel? _selectedEvent;

  String? _qrData(EventModel event) {
    final rawUrl = event.attendanceFormUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final replaced = rawUrl
        .replaceAll('{{eventId}}', Uri.encodeComponent(event.id))
        .replaceAll('{{eventTitle}}', Uri.encodeComponent(event.title));
    final uri = Uri.tryParse(replaced);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'eventId': event.id,
            'eventTitle': event.title,
          },
        )
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event attendance QR')),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().watchAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? const <EventModel>[];
          if (events.isEmpty) {
            return const Center(child: Text('No events available.'));
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 42),
            children: [
              const Text(
                'Select an event',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Display the selected event QR on a projector for student attendance.',
              ),
              const SizedBox(height: 12),
              ...events.map(
                (event) => Card(
                  color: _selectedEvent?.id == event.id
                      ? const Color(0xFFE9EEFF)
                      : null,
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(event.title),
                    subtitle: Text(
                      event.attendanceFormUrl?.isNotEmpty == true
                          ? 'Google Form configured'
                          : 'Google Form not configured',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedEvent = event),
                  ),
                ),
              ),
              if (_selectedEvent != null) ...[
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final qrData = _qrData(_selectedEvent!);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Attendance Check-in',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedEvent!.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 18),
                            if (qrData == null) ...[
                              const Icon(
                                Icons.link_off_outlined,
                                size: 54,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Google Form not configured',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Edit this event and add a valid Google Form URL before displaying the QR.',
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              QrImageView(data: qrData, size: 280),
                              const SizedBox(height: 14),
                              const Text(
                                'Students can scan this QR with their phone camera or Google Lens, then submit the form.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
