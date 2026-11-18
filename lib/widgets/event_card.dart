import 'package:material_ui/material_ui.dart';

import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final EventModel event;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final statusColor = event.isCancelled
        ? Colors.red
        : event.isPublished
        ? Colors.green
        : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF0FF),
          child: Icon(
            Icons.event,
            color: event.isCancelled ? Colors.red : const Color(0xFF3975FF),
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${event.category} • ${_date(event.startAt)}\n${event.venue}',
        ),
        isThreeLine: true,
        trailing:
            trailing ??
            Chip(
              label: Text(event.status),
              labelStyle: TextStyle(color: statusColor),
            ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
