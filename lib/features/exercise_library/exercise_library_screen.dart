import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import 'exercise_library_providers.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    final selectedCategory = ref.watch(exerciseCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('exerciseSearchField'),
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = value,
            ),
          ),
          categoriesAsync.when(
            data: (categories) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: selectedCategory == null,
                      onSelected: () => ref
                          .read(exerciseCategoryFilterProvider.notifier)
                          .state = null,
                    ),
                    for (final category in categories)
                      _CategoryChip(
                        label: category,
                        selected: selectedCategory == category,
                        onSelected: () => ref
                            .read(exerciseCategoryFilterProvider.notifier)
                            .state = category,
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises match.'));
                }
                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) =>
                      _ExerciseTile(exercise: exercises[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exercise.name),
      subtitle: Text(
        '${exercise.category} • ${exercise.equipment} • ${exercise.difficulty}',
      ),
      trailing: Text(exercise.measurementType),
    );
  }
}
