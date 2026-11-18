import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/registration_model.dart';

class QrPassScreen extends StatelessWidget {
  const QrPassScreen({required this.registration, super.key});

  final RegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    final registeredDate = registration.registeredAt == null
        ? 'Pending confirmation'
        : _format(registration.registeredAt!);
    final payload =
        '''EVENT_BUDDY_PASS
Student UID: ${registration.userId}
Event ID: ${registration.eventId}
Registration ID: ${registration.id}
Student: ${registration.participantName}
Event: ${registration.eventTitle}
Status: ${registration.status}
Registered: $registeredDate
Pass ID: ${registration.id}''';

    return Scaffold(
      appBar: AppBar(title: const Text('Event pass')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.confirmation_num_outlined,
                    size: 42,
                    color: Color(0xFF192D53),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    registration.eventTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF192D53),
                    ),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    registration.participantName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF192D53),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Show this QR code at the event entrance.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Status: ${registration.status}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Registered: $registeredDate',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _format(DateTime value) =>
      '${value.day}/${value.month}/${value.year} at '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
