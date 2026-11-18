import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/event_card.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';

class AdminEventListScreen extends StatelessWidget {
  const AdminEventListScreen({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<EventModel>>(
    stream: EventService().watchAllEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Could not load events.'));
      }
      final events = snapshot.data ?? [];
      if (events.isEmpty) return const _EmptyAdminEvents();
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Manage Events',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF192D53),
            ),
          ),
          const SizedBox(height: 16),
          ...events.map(
            (event) => EventCard(
              event: event,
              onTap: () => _openDetails(context, event),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _action(context, event, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'publish', child: Text('Publish')),
                  PopupMenuItem(value: 'draft', child: Text('Unpublish')),
                  PopupMenuItem(value: 'cancel', child: Text('Cancel event')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  void _openDetails(BuildContext context, EventModel event) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EventDetailsScreen(event: event, admin: true),
    ),
  );

  Future<void> _action(
    BuildContext context,
    EventModel event,
    String action,
  ) async {
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateEventScreen(event: event)),
      );
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete event?'),
          content: Text('Delete “${event.title}” permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await EventService().deleteEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Event deleted.')));
      }
      return;
    }
    final status = action == 'publish'
        ? 'published'
        : action == 'cancel'
        ? 'cancelled'
        : 'draft';
    await EventService().updateStatus(event, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event status updated.')));
    }
  }
}

class _EmptyAdminEvents extends StatelessWidget {
  const _EmptyAdminEvents();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No events yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Create your first event using the button below.'),
        ],
      ),
    ),
  );
}
