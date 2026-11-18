import 'package:material_ui/material_ui.dart';

import '../../models/registration_model.dart';
import '../../services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({required this.registration, super.key});

  final RegistrationModel registration;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    FeedbackService()
        .getMyFeedback(widget.registration.eventId)
        .then((value) {
          if (!mounted) return;
          if (value != null) {
            _rating = value.rating;
            _commentController.text = value.comment;
          }
          setState(() => _loading = false);
        })
        .catchError((_) {
          if (mounted) setState(() => _loading = false);
        });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FeedbackService().submit(
        eventId: widget.registration.eventId,
        eventTitle: widget.registration.eventTitle,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback saved successfully.')),
      );
      Navigator.pop(context);
    } on FeedbackFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event feedback')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.registration.eventTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF192D53),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  initialValue: _rating,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value / 5'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _rating = value ?? 5),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    hintText: 'Tell us about your experience',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Save feedback'),
                ),
              ],
            ),
    );
  }
}
