import 'package:material_ui/material_ui.dart';

import '../../models/feedback_model.dart';
import '../../models/user_profile.dart';
import '../../services/feedback_service.dart';
import '../../services/user_profile_service.dart';

class FeedbackManagementScreen extends StatelessWidget {
  const FeedbackManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback review')),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: FeedbackService().watchAllFeedback(),
        builder: (context, feedbackSnapshot) {
          if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (feedbackSnapshot.hasError) {
            return const _FeedbackMessage(
              icon: Icons.error_outline,
              message: 'Unable to load feedback.',
            );
          }

          final feedback = feedbackSnapshot.data ?? const <FeedbackModel>[];
          if (feedback.isEmpty) {
            return const _FeedbackMessage(
              icon: Icons.rate_review_outlined,
              message: 'No student feedback has been submitted yet.',
            );
          }

          return StreamBuilder<List<UserProfile>>(
            stream: UserProfileService().watchParticipants(),
            builder: (context, profileSnapshot) {
              final profiles = <String, UserProfile>{
                for (final profile in profileSnapshot.data ?? const [])
                  profile.uid: profile,
              };
              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: feedback.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = feedback[index];
                  return _FeedbackCard(
                    feedback: item,
                    participant: profiles[item.userId],
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

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, this.participant});

  final FeedbackModel feedback;
  final UserProfile? participant;

  @override
  Widget build(BuildContext context) {
    final name = participant?.fullName.isNotEmpty == true
        ? participant!.fullName
        : 'Student participant';
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        feedback.eventTitle,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                _Rating(rating: feedback.rating),
              ],
            ),
            if (feedback.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '“${feedback.comment.trim()}”',
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ],
            if (feedback.submittedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                _date(feedback.submittedAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
