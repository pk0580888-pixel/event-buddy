import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/score_model.dart';
import '../../models/user_profile.dart';
import '../../services/registration_service.dart';
import '../../services/event_service.dart';
import '../../services/score_service.dart';
import '../../services/user_profile_service.dart';
import 'analysis_portal_screen.dart';

class ScoreManagementScreen extends StatefulWidget {
  const ScoreManagementScreen({super.key});

  @override
  State<ScoreManagementScreen> createState() => _ScoreManagementScreenState();
}

class _ScoreManagementScreenState extends State<ScoreManagementScreen> {
  EventModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participant scores'),
        actions: [
          IconButton(
            tooltip: 'Open analysis portal',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisPortalScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().watchPublishedEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load published events.'),
            );
          }
          final events = snapshot.data ?? const <EventModel>[];
          if (_selectedEvent != null &&
              !events.any((event) => event.id == _selectedEvent!.id)) {
            _selectedEvent = null;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Text(
                  '1. Select a published event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (events.isEmpty)
                const Expanded(
                  child: Center(child: Text('No published events available.')),
                )
              else
                SizedBox(
                  height: 145,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _EventChoiceCard(
                      event: events[index],
                      selected: _selectedEvent?.id == events[index].id,
                      onTap: () =>
                          setState(() => _selectedEvent = events[index]),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Text(
                  '2. Assign participant scores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _selectedEvent == null
                    ? const Center(
                        child: Text(
                          'Select an event to view its participants.',
                        ),
                      )
                    : Column(
                        children: [
                          _EventLeaderboard(eventId: _selectedEvent!.id),
                          Expanded(
                            child: _ParticipantsForEvent(
                              event: _selectedEvent!,
                              onScore: _openScoreDialog,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openScoreDialog(
    BuildContext context,
    RegistrationModel registration,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ScoreEntryDialog(registration: registration),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Score saved.')));
    }
  }
}

class _EventLeaderboard extends StatelessWidget {
  const _EventLeaderboard({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScoreModel>>(
      stream: ScoreService().watchScoresForEvent(eventId),
      builder: (context, scoreSnapshot) {
        final scores = scoreSnapshot.data ?? const <ScoreModel>[];
        if (scores.isEmpty) return const SizedBox.shrink();
        return StreamBuilder<List<UserProfile>>(
          stream: UserProfileService().watchStudents(),
          builder: (context, profileSnapshot) {
            final names = {
              for (final profile
                  in profileSnapshot.data ?? const <UserProfile>[])
                profile.uid: profile.fullName,
            };
            final winners = scores.take(3).toList();
            return Card(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current top performers',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...winners.asMap().entries.map((entry) {
                      final score = entry.value;
                      final name = names[score.userId];
                      return Text(
                        '${entry.key + 1}. ${name == null || name.isEmpty ? 'Student' : name} — ${score.score}/100',
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ParticipantsForEvent extends StatelessWidget {
  const _ParticipantsForEvent({required this.event, required this.onScore});

  final EventModel event;
  final Future<void> Function(BuildContext, RegistrationModel) onScore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RegistrationModel>>(
      stream: RegistrationService().watchAllRegistrations(),
      builder: (context, registrationSnapshot) {
        if (registrationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<UserProfile>>(
          stream: UserProfileService().watchStudents(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profiles = profileSnapshot.data ?? const <UserProfile>[];
            final studentIds = profiles.map((profile) => profile.uid).toSet();
            final profileById = {
              for (final profile in profiles) profile.uid: profile,
            };
            final registrations =
                (registrationSnapshot.data ?? const <RegistrationModel>[])
                    .where(
                      (registration) =>
                          registration.eventId == event.id &&
                          registration.status == 'confirmed' &&
                          studentIds.contains(registration.userId),
                    )
                    .toList();
            if (registrations.isEmpty) {
              return const Center(
                child: Text('No students registered for this event.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: registrations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final registration = registrations[index];
                final profile = profileById[registration.userId];
                final name = profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : registration.participantName;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(name),
                    subtitle: Text(
                      'Registration ID: ${registration.id}\nStudent ID: ${profile?.studentId ?? 'Not available'}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => onScore(context, registration),
                      child: const Text('Score'),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EventChoiceCard extends StatelessWidget {
  const _EventChoiceCard({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final EventModel event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        color: selected ? const Color(0xFFE9EEFF) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.event,
                      color: const Color(0xFF3975FF),
                    ),
                    const Spacer(),
                    Text(event.category, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(event.venue, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreEntryDialog extends StatefulWidget {
  const ScoreEntryDialog({required this.registration, super.key});

  final RegistrationModel registration;

  @override
  State<ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<ScoreEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ScoreService().assignScore(
        userId: widget.registration.userId,
        eventId: widget.registration.eventId,
        eventTitle: widget.registration.eventTitle,
        score: int.parse(_scoreController.text.trim()),
        remarks: _remarksController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ScoreFailure catch (error) {
      _showError(error.message);
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'Could not save score.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Score ${widget.registration.participantName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _scoreController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Score (0-100)'),
              validator: (value) {
                final score = int.tryParse(value?.trim() ?? '');
                if (score == null || score < 0 || score > 100) {
                  return 'Enter a score from 0 to 100';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _remarksController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save score'),
        ),
      ],
    );
  }
}
