import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/event_model.dart';
import '../../services/registration_service.dart';
import '../../services/user_profile_service.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    required this.event,
    this.admin = false,
    super.key,
  });

  final EventModel event;
  final bool admin;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _registered = false;
  bool _loading = true;
  bool _submitting = false;
  String? _creatorName;

  @override
  void initState() {
    super.initState();
    if (widget.admin) {
      _loading = false;
    } else {
      RegistrationService()
          .isRegistered(widget.event.id)
          .then((value) {
            if (mounted) {
              setState(() {
                _registered = value;
                _loading = false;
              });
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _loading = false);
          });
    }
    UserProfileService().getProfile(widget.event.createdBy).then((profile) {
      if (!mounted) return;
      setState(() {
        _creatorName = profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName.trim()
            : null;
      });
    });
  }

  Future<void> _register() async {
    setState(() => _submitting = true);
    try {
      await RegistrationService().register(widget.event);
      if (!mounted) return;
      setState(() => _registered = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration confirmed.')));
    } on RegistrationFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Registration failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            72 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF192D53),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(widget.event.category)),
                Chip(label: Text(widget.event.status)),
              ],
            ),
            if (widget.event.posterUrl != null &&
                widget.event.posterUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showPoster(context, widget.event.posterUrl!),
                borderRadius: BorderRadius.circular(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: const Color(0xFFF2EEF8),
                      child: Image.network(
                        widget.event.posterUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.description_outlined,
              title: 'Description',
              value: widget.event.description.isEmpty
                  ? 'No description provided.'
                  : widget.event.description,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'Venue',
              value: widget.event.venue,
            ),
            _InfoRow(
              icon: Icons.schedule,
              title: 'Schedule',
              value:
                  '${_format(widget.event.startAt)}\nUntil ${_format(widget.event.endAt)}',
            ),
            _InfoRow(
              icon: Icons.people_outline,
              title: 'Capacity',
              value: '${widget.event.capacity} participants',
            ),
            if (!widget.admin) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading || _registered || _submitting
                      ? null
                      : _register,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_reg),
                  label: Text(
                    _loading
                        ? 'Checking registration...'
                        : _registered
                        ? 'Registered'
                        : 'Register for event',
                  ),
                ),
              ),
            ],
            if (widget.admin) ...[
              const SizedBox(height: 18),
              const Text(
                'Administrative information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Created by: ${_creatorName ?? widget.event.createdBy}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _format(DateTime value) =>
      '${value.day}/${value.month}/${value.year} at ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void _showPoster(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.82,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    ),
  );
}
