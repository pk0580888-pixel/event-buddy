import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../../models/event_model.dart';
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({this.event, super.key});
  final EventModel? event;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _capacity = TextEditingController();
  final _attendanceFormUrl = TextEditingController();
  final _service = EventService();
  final _categories = const [
    'Cultural',
    'Hackathon',
    'Technical',
    'Sports',
    'Workshop',
    'Seminar',
    'Competition',
    'Communication Event',
    'Other',
  ];
  String _category = 'Cultural';
  String _status = 'draft';
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endAt = DateTime.now().add(const Duration(hours: 2));
  bool _saving = false;
  XFile? _poster;

  bool get editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _title.text = event.title;
      _description.text = event.description;
      _venue.text = event.venue;
      _capacity.text = event.capacity.toString();
      _attendanceFormUrl.text = event.attendanceFormUrl ?? '';
      _category = _categories.contains(event.category)
          ? event.category
          : 'Other';
      _status = event.status;
      _startAt = event.startAt;
      _endAt = event.endAt;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _venue.dispose();
    _capacity.dispose();
    _attendanceFormUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit event' : 'Create event')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              56 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Event title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an event title'
                    : null,
              ),
              const SizedBox(height: 14),
              _PosterPicker(
                selectedFile: _poster,
                existingUrl: widget.event?.posterUrl,
                onTap: _pickPoster,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Other'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _venue,
                decoration: const InputDecoration(labelText: 'Venue'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a venue'
                    : null,
              ),
              const SizedBox(height: 14),
              _DateButton(
                label: 'Starts',
                value: _startAt,
                onTap: () => _pickDateTime(isStart: true),
              ),
              _DateButton(
                label: 'Ends',
                value: _endAt,
                onTap: () => _pickDateTime(isStart: false),
              ),
              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum capacity',
                ),
                validator: (value) {
                  final capacity = int.tryParse(value ?? '');
                  return capacity == null || capacity <= 0
                      ? 'Enter a capacity greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _attendanceFormUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Google Form attendance URL (optional)',
                  hintText: 'Paste a different form link for this event',
                  helperText: 'Use {{eventId}} or {{eventTitle}} for event-specific prefilled fields.',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'draft'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(editing ? 'Save changes' : 'Create event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _startAt : _endAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startAt = selected;
      } else {
        _endAt = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      _showError('End time must be after start time.');
      return;
    }
    setState(() => _saving = true);
    try {
      final capacity = int.parse(_capacity.text.trim());
      if (editing) {
        await _service.updateEvent(
          event: widget.event!,
          title: _title.text,
          description: _description.text,
          category: _category,
          venue: _venue.text,
          startAt: _startAt,
          endAt: _endAt,
          capacity: capacity,
          status: _status,
          posterUrl: widget.event?.posterUrl,
          attendanceFormUrl: _attendanceFormUrl.text,
        );
        if (_poster != null) {
          await _service.uploadPoster(
            eventId: widget.event!.id,
            path: _poster!.path,
          );
        }
      } else {
        final eventId = await _service.createEvent(
          title: _title.text,
          description: _description.text,
          category: _category,
          venue: _venue.text,
          startAt: _startAt,
          endAt: _endAt,
          capacity: capacity,
          status: _status,
          attendanceFormUrl: _attendanceFormUrl.text,
        );
        if (_poster != null) {
          await _service.uploadPoster(eventId: eventId, path: _poster!.path);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'Could not save the event.');
    } on EventFailure catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPoster() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => _poster = picked);
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _PosterPicker extends StatelessWidget {
  const _PosterPicker({
    required this.selectedFile,
    required this.existingUrl,
    required this.onTap,
  });

  final XFile? selectedFile;
  final String? existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        selectedFile != null ||
        (existingUrl != null && existingUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Event poster'),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8CDE2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? (selectedFile != null
                        ? Image.file(
                            File(selectedFile!.path),
                            fit: BoxFit.contain,
                          )
                        : Image.network(existingUrl!, fit: BoxFit.contain))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 42),
                        SizedBox(height: 8),
                        Text('Add event poster'),
                        Text('Square image recommended'),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.calendar_month),
      title: Text(label),
      subtitle: Text(
        '${value.day}/${value.month}/${value.year} at ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      ),
      onTap: onTap,
    ),
  );
}
