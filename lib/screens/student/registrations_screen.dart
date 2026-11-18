import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/registration_model.dart';
import '../../services/registration_service.dart';
import 'feedback_screen.dart';
import 'qr_pass_screen.dart';

class StudentRegistrationsScreen extends StatelessWidget {
  const StudentRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My registrations')),
      body: StreamBuilder<List<RegistrationModel>>(
        stream: RegistrationService().watchMyRegistrations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load registrations.'));
          }

          final registrations = snapshot.data ?? const <RegistrationModel>[];
          if (registrations.isEmpty) {
            return const Center(
              child: Text('You have no event registrations yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: registrations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final registration = registrations[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.confirmation_num_outlined),
                  title: Text(registration.eventTitle),
                  subtitle: Text(
                    registration.registeredAt == null
                        ? 'Registration confirmed'
                        : 'Registered ${_format(registration.registeredAt!)}',
                  ),
                  trailing: registration.status == 'confirmed'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View QR pass',
                              icon: const Icon(Icons.qr_code_2),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QrPassScreen(registration: registration),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Give feedback',
                              icon: const Icon(Icons.rate_review_outlined),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FeedbackScreen(
                                    registration: registration,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cancel registration',
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () =>
                                  _confirmCancellation(context, registration),
                            ),
                          ],
                        )
                      : Chip(label: Text(registration.status)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    RegistrationModel registration,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel registration?'),
        content: Text(
          'Do you want to cancel your registration for ${registration.eventTitle}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep registration'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel registration'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await RegistrationService().cancel(registration);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration cancelled.')));
    } on RegistrationFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Could not cancel registration.'),
          ),
        );
      }
    }
  }

  String _format(DateTime value) => '${value.day}/${value.month}/${value.year}';
}
