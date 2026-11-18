import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/event_card.dart';
import '../admin/event_details_screen.dart';

class StudentEventsScreen extends StatelessWidget {
  const StudentEventsScreen({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<EventModel>>(
    stream: EventService().watchPublishedEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Could not load upcoming events.'));
      }
      final events = (snapshot.data ?? [])
          .where((event) => event.startAt.isAfter(DateTime.now()))
          .toList();
      if (events.isEmpty) {
        return const Center(
          child: Text('No published events are available yet.'),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Upcoming events',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF192D53),
            ),
          ),
          const SizedBox(height: 16),
          ...events.map(
            (event) => EventCard(
              event: event,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(event: event),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
