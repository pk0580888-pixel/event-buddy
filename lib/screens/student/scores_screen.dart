import 'package:material_ui/material_ui.dart';

import '../../models/score_model.dart';
import '../../services/score_service.dart';

class StudentScoresScreen extends StatelessWidget {
  const StudentScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My scores')),
      body: StreamBuilder<List<ScoreModel>>(
        stream: ScoreService().watchMyScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load scores.'));
          }
          final scores = snapshot.data ?? const <ScoreModel>[];
          if (scores.isEmpty) {
            return const Center(
              child: Text('No scores have been assigned yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: scores.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final score = scores[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text(score.eventTitle),
                  subtitle: Text(
                    score.remarks.isEmpty ? 'No remarks' : score.remarks,
                  ),
                  trailing: Text(
                    '${score.score}/100',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
