import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../models/feedback_model.dart';
import '../../models/registration_model.dart';
import '../../models/score_model.dart';
import '../../models/user_profile.dart';
import '../../services/event_service.dart';
import '../../services/score_service.dart';

/// Live event analysis sheet. All values are read from Firestore so organisers
/// can work from one screen without moving between participant, score, and
/// feedback screens.
class AnalysisPortalScreen extends StatefulWidget {
  const AnalysisPortalScreen({super.key});

  @override
  State<AnalysisPortalScreen> createState() => _AnalysisPortalScreenState();
}

class _AnalysisPortalScreenState extends State<AnalysisPortalScreen> {
  EventModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis portal')),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().watchPublishedEvents(),
        builder: (context, eventsSnapshot) {
          if (eventsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventsSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load published events.'),
            );
          }
          final events = eventsSnapshot.data ?? const <EventModel>[];
          if (_selectedEvent != null &&
              !events.any((event) => event.id == _selectedEvent!.id)) {
            _selectedEvent = null;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              if (events.isEmpty)
                const Expanded(
                  child: Center(child: Text('No published events available.')),
                )
              else ...[
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _EventChoice(
                        event: event,
                        selected: event.id == _selectedEvent?.id,
                        onTap: () => setState(() => _selectedEvent = event),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _selectedEvent == null
                      ? const Center(
                          child: Text(
                            'Select an event to open its analysis sheet.',
                          ),
                        )
                      : _LiveAnalysis(event: _selectedEvent!),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One live sheet for every event',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Track attendance, events attended, scores, and feedback together. Changes appear for all organisers in real time.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _LiveAnalysis extends StatelessWidget {
  const _LiveAnalysis({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .snapshots(),
      builder: (context, registrationsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('scores')
                  .snapshots(),
              builder: (context, scoresSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('feedback')
                      .snapshots(),
                  builder: (context, feedbackSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('attendance')
                          .snapshots(),
                      builder: (context, attendanceSnapshot) {
                        if (registrationsSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            usersSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            scoresSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            feedbackSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            attendanceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final rows = _buildRows(
                          registrationsSnapshot.data?.docs ?? const [],
                          usersSnapshot.data?.docs ?? const [],
                          scoresSnapshot.data?.docs ?? const [],
                          feedbackSnapshot.data?.docs ?? const [],
                          attendanceSnapshot.data?.docs ?? const [],
                        );
                        return _AnalysisContent(event: event, rows: rows);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<_AnalysisRow> _buildRows(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> scores,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> feedback,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> attendance,
  ) {
    final profiles = {
      for (final document in users)
        document.id: UserProfile.fromMap(document.id, document.data()),
    };
    final confirmed = registrations
        .map(RegistrationModel.fromDocument)
        .where((item) => item.status == 'confirmed')
        .toList();
    final registrationsByUser = <String, List<RegistrationModel>>{};
    for (final item in confirmed) {
      registrationsByUser.putIfAbsent(item.userId, () => []).add(item);
    }
    final scoresByUser = <String, ScoreModel>{};
    for (final document in scores) {
      final item = ScoreModel.fromDocument(document);
      if (item.eventId == event.id) scoresByUser[item.userId] = item;
    }
    final feedbackByUser = <String, FeedbackModel>{};
    for (final document in feedback) {
      final item = FeedbackModel.fromDocument(document);
      if (item.eventId == event.id) feedbackByUser[item.userId] = item;
    }
    final present = attendance
        .map((document) => document.data())
        .where((item) => item['eventId'] == event.id)
        .map((item) => item['userId'] as String? ?? '')
        .toSet();

    return confirmed.where((item) => item.eventId == event.id).map((
      registration,
    ) {
      final profile = profiles[registration.userId];
      final score = scoresByUser[registration.userId];
      final feedbackItem = feedbackByUser[registration.userId];
      return _AnalysisRow(
        userId: registration.userId,
        name: profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : registration.participantName,
        studentId: profile?.studentId ?? '',
        email: profile?.email ?? '',
        attendedEvents: registrationsByUser[registration.userId]?.length ?? 0,
        present: present.contains(registration.userId),
        score: score,
        feedback: feedbackItem?.comment ?? score?.remarks ?? '',
      );
    }).toList();
  }
}

class _AnalysisContent extends StatefulWidget {
  const _AnalysisContent({required this.event, required this.rows});
  final EventModel event;
  final List<_AnalysisRow> rows;

  @override
  State<_AnalysisContent> createState() => _AnalysisContentState();
}

class _AnalysisContentState extends State<_AnalysisContent> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final rows = widget.rows.where((row) {
      if (query.isEmpty) return true;
      return row.name.toLowerCase().contains(query) ||
          row.studentId.toLowerCase().contains(query) ||
          row.email.toLowerCase().contains(query);
    }).toList();
    final scored = widget.rows.where((row) => row.score != null).length;
    final present = widget.rows.where((row) => row.present).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
      children: [
        Row(
          children: [
            _Metric(
              label: 'Students',
              value: '${widget.rows.length}',
              color: Colors.blue,
            ),
            _Metric(label: 'Present', value: '$present', color: Colors.green),
            _Metric(
              label: 'Scored',
              value: '$scored',
              color: Colors.deepPurple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            labelText: 'Search this event sheet',
            hintText: 'Name, student ID, or email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.clear),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.event.title} • ${rows.length} shown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('No matching participants.')),
          )
        else
          ...rows.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                isThreeLine: true,
                leading: CircleAvatar(child: Text(_initial(row.name))),
                title: Text(
                  row.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${row.studentId.isEmpty ? 'Student ID unavailable' : row.studentId}\n${row.email}\n${row.attendedEvents} event(s) attended • ${row.present ? 'Present' : 'Not marked present'}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.score == null
                          ? 'Not scored'
                          : '${row.score!.score}/100',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      row.feedback.isEmpty ? 'No feedback' : 'Feedback added',
                      style: const TextStyle(fontSize: 11),
                    ),
                    TextButton(
                      onPressed: () => _editRow(row),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editRow(_AnalysisRow row) async {
    final scoreController = TextEditingController(
      text: '${row.score?.score ?? ''}',
    );
    final feedbackController = TextEditingController(text: row.feedback);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${row.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Score (0-100)'),
                validator: (value) {
                  final score = int.tryParse(value?.trim() ?? '');
                  if (score == null || score < 0 || score > 100) {
                    return 'Enter 0 to 100';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Score feedback / remarks',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ScoreService().assignScore(
                userId: row.userId,
                eventId: widget.event.id,
                eventTitle: widget.event.title,
                score: int.parse(scoreController.text.trim()),
                remarks: feedbackController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    scoreController.dispose();
    feedbackController.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Analysis sheet updated.')));
    }
  }

  String _initial(String value) =>
      value.trim().isEmpty ? '?' : value.trim().substring(0, 1).toUpperCase();
}

class _AnalysisRow {
  const _AnalysisRow({
    required this.userId,
    required this.name,
    required this.studentId,
    required this.email,
    required this.attendedEvents,
    required this.present,
    required this.score,
    required this.feedback,
  });
  final String userId;
  final String name;
  final String studentId;
  final String email;
  final int attendedEvents;
  final bool present;
  final ScoreModel? score;
  final String feedback;
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventChoice extends StatelessWidget {
  const _EventChoice({
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.event_outlined,
                      color: const Color(0xFF3975FF),
                    ),
                    const Spacer(),
                    Text(event.category, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.venue, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
