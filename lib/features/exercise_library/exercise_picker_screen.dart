import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../plans/plan_providers.dart' show allExercisesForMatchingProvider;

/// A searchable "pick one exercise from the whole library" screen - push it
/// and await the result, which is the picked [Exercise] or null if the user
/// backed out. Neither `add_exercise_to_plan_screen.dart` (which is only
/// ever reached *with* an exercise already chosen, from the Library screen
/// itself) nor `plan_import_screen.dart`'s unmatched-name resolver (a plain
/// unsearched list, fine for a handful of names but not for browsing a
/// whole library) had this - used by the plan builder and by adding an
/// exercise to an existing plan session.
///
/// Deliberately uses its own local search state rather than the real
/// Exercise Library screen's `exerciseSearchQueryProvider`/
/// `filteredExercisesProvider` - those are global and reused across the
/// whole app, so typing here would leak into (and be reset by) the actual
/// Library screen's own search box.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesForMatchingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose an exercise')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (exercises) {
                final query = _query.trim().toLowerCase();
                final matches = query.isEmpty
                    ? exercises
                    : exercises
                          .where((e) => e.name.toLowerCase().contains(query))
                          .toList();
                if (matches.isEmpty) {
                  return const Center(child: Text('No exercises match.'));
                }
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final exercise = matches[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.category),
                      onTap: () => Navigator.of(context).pop(exercise),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
