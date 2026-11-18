import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../models/score_model.dart';
import '../../models/user_profile.dart';
import '../../services/event_service.dart';
import '../../services/score_service.dart';
import '../../services/user_profile_service.dart';

class TopPerformersScreen extends StatefulWidget {
  const TopPerformersScreen({super.key});

  @override
  State<TopPerformersScreen> createState() => _TopPerformersScreenState();
}

class _TopPerformersScreenState extends State<TopPerformersScreen> {
  EventModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top performers')),
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
                'View the three highest-scoring students for each event.',
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
                    onTap: () => setState(() => _selectedEvent = event),
                  ),
                ),
              ),
              if (_selectedEvent != null) ...[
                const SizedBox(height: 22),
                Text(
                  _selectedEvent!.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _TopThree(eventId: _selectedEvent!.id),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TopThree extends StatelessWidget {
  const _TopThree({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScoreModel>>(
      stream: ScoreService().watchScoresForEvent(eventId),
      builder: (context, scoreSnapshot) {
        if (scoreSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final scores = scoreSnapshot.data ?? const <ScoreModel>[];
        if (scores.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.emoji_events_outlined),
              title: Text('No scores assigned yet.'),
              subtitle: Text(
                'Top performers will appear after scores are saved.',
              ),
            ),
          );
        }
        return StreamBuilder<List<UserProfile>>(
          stream: UserProfileService().watchStudents(),
          builder: (context, profileSnapshot) {
            final profileById = {
              for (final profile
                  in profileSnapshot.data ?? const <UserProfile>[])
                profile.uid: profile,
            };
            final winners = scores.take(3).toList();
            return Column(
              children: [
                ...winners.asMap().entries.map(
                  (entry) => _WinnerCard(
                    position: entry.key + 1,
                    score: entry.value,
                    profile: profileById[entry.value.userId],
                  ),
                ),
                if (scores.length < 3)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Fewer than three students have scores for this event.',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.position,
    required this.score,
    required this.profile,
  });

  final int position;
  final ScoreModel score;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Student';
    final studentId = profile?.studentId;
    final color = position == 1
        ? const Color(0xFFFFB300)
        : position == 2
        ? const Color(0xFF78909C)
        : const Color(0xFFB87333);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Text(
            '$position',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          studentId == null || studentId.isEmpty
              ? 'Position $position'
              : 'Student ID: $studentId • Position $position',
        ),
        trailing: Text(
          '${score.score}/100',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
