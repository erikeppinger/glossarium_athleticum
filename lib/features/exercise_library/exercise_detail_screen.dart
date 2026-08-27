import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_database.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../history/history_screen.dart';

/// Shows everything the library has on one exercise - description, safety
/// notes, muscle groups, and a reference video/link - with a way to jump to
/// its logged history or add it straight into a plan. Previously, tapping
/// an exercise skipped straight to its history with no way to read about it
/// first; that's still one tap away via the app bar action.
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final muscleGroups = exercise.muscleGroups
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'View history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HistoryScreen(
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(exercise.category)),
              if (exercise.movementPattern.isNotEmpty)
                Chip(label: Text(exercise.movementPattern)),
              Chip(label: Text(exercise.equipment)),
              Chip(label: Text(exercise.difficulty)),
              Chip(label: Text(exercise.measurementType)),
            ],
          ),
          if (muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Muscle groups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(muscleGroups.join(', ')),
          ],
          if (exercise.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(exercise.description),
          ],
          if (exercise.safetyNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Safety notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 4),
            Text(exercise.safetyNotes),
          ],
          if (exercise.videoReference.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Reference video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _openVideo(context, exercise.videoReference),
              child: Text(
                exercise.videoReference,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add to plan'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddExerciseToPlanScreen(
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open this link.")));
    }
  }
}
