import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & analytics')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, eventsSnapshot) {
          if (eventsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventsSnapshot.hasError) {
            return const _AnalyticsMessage('Unable to load event analytics.');
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('registrations')
                .snapshots(),
            builder: (context, registrationsSnapshot) {
              if (registrationsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('feedback')
                    .snapshots(),
                builder: (context, feedbackSnapshot) {
                  if (feedbackSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('scores')
                        .snapshots(),
                    builder: (context, scoresSnapshot) {
                      if (scoresSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, usersSnapshot) {
                          final adminUserIds = (usersSnapshot.data?.docs ?? [])
                              .where((user) => user.data()['role'] == 'admin')
                              .map((user) => user.id)
                              .toSet();
                          final adminNames = (usersSnapshot.data?.docs ?? [])
                              .where((user) => user.data()['role'] == 'admin')
                              .map(
                                (user) =>
                                    (user.data()['fullName'] as String?) ??
                                    (user.data()['name'] as String?) ??
                                    '',
                              )
                              .where((name) => name.trim().isNotEmpty)
                              .toSet();
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          final currentUserName =
                              FirebaseAuth.instance.currentUser?.displayName;
                          if (currentUserId != null) {
                            adminUserIds.add(currentUserId);
                          }
                          if (currentUserName != null &&
                              currentUserName.trim().isNotEmpty) {
                            adminNames.add(currentUserName);
                          }
                          return _AnalyticsContent(
                            events: eventsSnapshot.data?.docs ?? const [],
                            registrations:
                                registrationsSnapshot.data?.docs ?? const [],
                            feedback: feedbackSnapshot.data?.docs ?? const [],
                            scores: scoresSnapshot.data?.docs ?? const [],
                            adminUserIds: adminUserIds,
                            adminNames: adminNames,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.events,
    required this.registrations,
    required this.feedback,
    required this.scores,
    required this.adminUserIds,
    required this.adminNames,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> events;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> feedback;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> scores;
  final Set<String> adminUserIds;
  final Set<String> adminNames;

  @override
  Widget build(BuildContext context) {
    final participantRegistrations = registrations
        .where((registration) => !_isAdminRecord(registration))
        .toList();
    final participantFeedback = feedback
        .where((item) => !_isAdminRecord(item))
        .toList();
    final participantScores = scores
        .where((item) => !_isAdminRecord(item))
        .toList();
    final published = events.where((event) => _status(event) == 'published');
    final draft = events.where((event) => _status(event) == 'draft');
    final cancelled = events.where((event) => _status(event) == 'cancelled');
    final ratings = participantFeedback
        .map((item) => (item.data()['rating'] as num?)?.toDouble() ?? 0)
        .where((rating) => rating > 0)
        .toList();
    final averageRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;
    final scoresList = participantScores
        .map((item) => (item.data()['score'] as num?)?.toDouble() ?? 0)
        .toList();
    final averageScore = scoresList.isEmpty
        ? 0.0
        : scoresList.reduce((a, b) => a + b) / scoresList.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        const Text(
          'Event overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 160,
          children: [
            _MetricCard(
              label: 'Total events',
              value: '${events.length}',
              icon: Icons.event_outlined,
              color: Colors.blue,
              onTap: () => _showEventDetails(context, 'All events', events),
            ),
            _MetricCard(
              label: 'Published',
              value: '${published.length}',
              icon: Icons.public,
              color: Colors.green,
              onTap: () =>
                  _showEventDetails(context, 'Published events', published),
            ),
            _MetricCard(
              label: 'Draft',
              value: '${draft.length}',
              icon: Icons.edit_note_outlined,
              color: Colors.orange,
              onTap: () => _showEventDetails(context, 'Draft events', draft),
            ),
            _MetricCard(
              label: 'Registrations',
              value: '${participantRegistrations.length}',
              icon: Icons.people_outline,
              color: Colors.deepPurple,
              onTap: () =>
                  _showRegistrationDetails(context, participantRegistrations),
            ),
            _MetricCard(
              label: 'Cancelled',
              value: '${cancelled.length}',
              icon: Icons.event_busy_outlined,
              color: Colors.redAccent,
              onTap: () =>
                  _showEventDetails(context, 'Cancelled events', cancelled),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Participant insights',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Average feedback rating'),
                trailing: Text(
                  '${averageRating.toStringAsFixed(1)} / 5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('Feedback responses'),
                trailing: Text('${participantFeedback.length}'),
                onTap: () => _showFeedbackDetails(context, participantFeedback),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Average assigned score'),
                trailing: Text(
                  '${averageScore.toStringAsFixed(1)} / 100',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => _showScoreDetails(context, participantScores),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _status(QueryDocumentSnapshot<Map<String, dynamic>> event) {
    final value = (event.data()['status'] as String? ?? 'draft').toLowerCase();
    if (value == 'published') return 'published';
    if (value == 'cancelled' || value == 'canceled') return 'cancelled';
    return 'draft';
  }

  bool _isAdminRecord(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final userId = data['userId'];
    final participantName = data['participantName'];
    return (userId is String && adminUserIds.contains(userId)) ||
        (participantName is String &&
            adminNames.any(
              (name) =>
                  name.trim().toLowerCase() ==
                  participantName.trim().toLowerCase(),
            ));
  }

  Future<void> _showEventDetails(
    BuildContext context,
    String title,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> eventDocuments,
  ) {
    final items = eventDocuments.map((document) {
      final data = document.data();
      return ListTile(
        leading: const Icon(Icons.event_outlined),
        title: Text(data['title'] as String? ?? 'Untitled event'),
        subtitle: Text(
          '${_status(document).toUpperCase()} • ${data['venue'] as String? ?? 'Venue not specified'}',
        ),
      );
    }).toList();
    return _showDetailsSheet(
      context,
      title,
      items,
      'No events in this category.',
    );
  }

  Future<void> _showRegistrationDetails(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  ) {
    final items = registrations.where((document) => !_isAdminRecord(document)).map((
      document,
    ) {
      final data = document.data();
      return ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(data['participantName'] as String? ?? 'Participant'),
        subtitle: Text(
          '${data['eventTitle'] as String? ?? 'Event'} • ${data['status'] as String? ?? 'confirmed'}',
        ),
      );
    }).toList();
    return _showDetailsSheet(
      context,
      'All student registrations',
      items,
      'No registrations yet.',
    );
  }

  Future<void> _showFeedbackDetails(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> feedback,
  ) {
    final items = feedback.map((document) {
      final data = document.data();
      final rating = (data['rating'] as num?)?.toInt() ?? 0;
      return ListTile(
        leading: Icon(Icons.star, color: Colors.amber.shade700),
        title: Text(data['eventTitle'] as String? ?? 'Event'),
        subtitle: Text(
          '${'★' * rating}${'☆' * (5 - rating)}\n${data['comment'] as String? ?? 'No written response.'}',
        ),
        isThreeLine: true,
      );
    }).toList();
    return _showDetailsSheet(
      context,
      'Feedback responses',
      items,
      'No feedback responses yet.',
    );
  }

  Future<void> _showScoreDetails(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> scores,
  ) {
    final items = scores.map((document) {
      final data = document.data();
      return ListTile(
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text(data['eventTitle'] as String? ?? 'Event'),
        subtitle: Text(data['remarks'] as String? ?? 'No remarks.'),
        trailing: Text(
          '${(data['score'] as num?)?.toInt() ?? 0}/100',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
    return _showDetailsSheet(
      context,
      'Assigned scores',
      items,
      'No scores have been assigned yet.',
    );
  }

  Future<void> _showDetailsSheet(
    BuildContext context,
    String title,
    List<Widget> items,
    String emptyMessage,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(emptyMessage))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) => items[index],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.grey)),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsMessage extends StatelessWidget {
  const _AnalyticsMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
