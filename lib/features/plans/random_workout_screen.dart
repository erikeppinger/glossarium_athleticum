import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/exercise_dao.dart' show ownExercisesFilter;
import '../../data/daos/plan_dao.dart';
import '../../logic/muscle_group_colors.dart';
import '../../logic/random_workout_generator.dart';
import '../exercise_library/exercise_library_providers.dart';
import '../settings/app_preferences.dart';
import 'plan_detail_screen.dart';
import 'plan_providers.dart';

/// The four buckets the user actually asked for ("X warm-up, Y legs, Z
/// upper body/arms, A core exercises") - fixed, not user-definable, to keep
/// the common case a handful of number fields rather than a full filter
/// builder. `count: 0` (the default) just means "skip this bucket" -
/// generating with every count at zero is blocked the same way an empty
/// plan-builder session would be.
List<WorkoutBucketSpec> _defaultBuckets() => const [
  WorkoutBucketSpec(label: 'Warm-up', count: 0, category: 'Warm-up'),
  WorkoutBucketSpec(label: 'Legs', count: 0, areas: {MuscleArea.legs}),
  WorkoutBucketSpec(
    label: 'Upper body / arms',
    count: 0,
    areas: {
      MuscleArea.chest,
      MuscleArea.back,
      MuscleArea.shoulders,
      MuscleArea.arms,
    },
  ),
  WorkoutBucketSpec(label: 'Core', count: 0, areas: {MuscleArea.core}),
];

/// Generates a one-off workout by picking a set number of random exercises
/// per muscle-area/category bucket, optionally narrowed to a single library
/// ("which library or libraries") and to only what the user has equipment
/// for. Saves the result as a genuine plan (one session, "Today"'s weekday,
/// unscheduled) so it gets every existing plan feature for free - starting
/// it, editing a set that turned out to be a bad fit, scheduling it again
/// later - rather than a bespoke one-shot "workout" concept with none of
/// that.
class RandomWorkoutScreen extends ConsumerStatefulWidget {
  const RandomWorkoutScreen({super.key});

  @override
  ConsumerState<RandomWorkoutScreen> createState() =>
      _RandomWorkoutScreenState();
}

class _RandomWorkoutScreenState extends ConsumerState<RandomWorkoutScreen> {
  late List<WorkoutBucketSpec> _buckets = _defaultBuckets();
  bool _requireOwnedEquipment = false;
  String? _source;
  GeneratedWorkout? _generated;
  bool _saving = false;

  bool get _canGenerate => _buckets.any((b) => b.count > 0);

  void _setCount(int index, int count) {
    setState(() {
      _buckets = [
        for (var i = 0; i < _buckets.length; i++)
          i == index ? _buckets[i].withCount(count) : _buckets[i],
      ];
      _generated = null;
    });
  }

  Future<void> _generate() async {
    final db = ref.read(appDatabaseProvider);
    final library = await db.exerciseDao.getAllExercises();
    final owned = ref.read(appPreferencesProvider).availableEquipment;
    setState(() {
      _generated = generateRandomWorkout(
        library: library,
        buckets: _buckets.where((b) => b.count > 0).toList(),
        requireOwnedEquipment: _requireOwnedEquipment,
        equipmentOwned: owned,
        source: _source,
      );
    });
  }

  Future<void> _saveAsPlan() async {
    final generated = _generated;
    if (generated == null) return;
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    const weekdayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    var order = 1;
    final exercises = <PlanExerciseInput>[
      for (final exercise in generated.allExercises)
        PlanExerciseInput(
          order: order++,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: 3,
          reps: '8-10',
        ),
    ];

    final planId = const Uuid().v4();
    await db.planDao.createPlan(
      id: planId,
      // A raw '${now.month}/${now.day}' read as US-style M/D to a European
      // user (reported live 2026-09-11: "Random Workout 9/11" on Sep 11
      // looked like a typo, not a date) - spelling the month out removes the
      // ambiguity outright rather than adding a yet another settings toggle
      // for something this can just not be confusing about in the first
      // place. Matches today_screen.dart's own use of the same formatter.
      name:
          'Random Workout ${MaterialLocalizations.of(context).formatMediumDate(now)}',
      sessions: [
        PlanSessionInput(
          weekNumber: 1,
          day: weekdayNames[now.weekday - 1],
          sessionName: 'Random Workout',
          exercises: exercises,
        ),
      ],
    );
    ref.invalidate(plansListProvider);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PlanDetailScreen(planId: planId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creatorOptionsAsync = ref.watch(creatorFilterOptionsProvider);
    final generated = _generated;

    return Scaffold(
      appBar: AppBar(title: const Text('Random workout')),
      body: ListView(
        // "Use this workout" was reported live as partly covered by
        // Android's own gesture/3-button navigation bar - a plain fixed
        // bottom padding doesn't account for that inset, since Scaffold
        // draws content edge-to-edge behind system bars by default (see the
        // same fix on color_palette_screen.dart).
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'How many exercises?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Leave a bucket at 0 to skip it entirely.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _buckets.length; i++)
            _BucketCountRow(
              label: _buckets[i].label,
              count: _buckets[i].count,
              onChanged: (c) => _setCount(i, c),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Only exercises I have equipment for'),
            value: _requireOwnedEquipment,
            onChanged: (v) => setState(() {
              _requireOwnedEquipment = v;
              _generated = null;
            }),
          ),
          creatorOptionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (options) => _SourcePickerField(
              value: _source,
              options: options,
              onChanged: (v) => setState(() {
                _source = v;
                _generated = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _canGenerate ? _generate : null,
            icon: const Icon(Icons.shuffle),
            label: Text(generated == null ? 'Generate' : 'Regenerate'),
          ),
          if (generated != null) ...[
            const SizedBox(height: 24),
            if (generated.allExercises.isEmpty)
              const Text(
                "No exercises matched these filters - try widening them "
                '(a different library, or turning off the equipment filter).',
              )
            else ...[
              for (final bucket in generated.buckets)
                if (bucket.exercises.isNotEmpty || bucket.spec.count > 0)
                  _BucketResultCard(bucket: bucket),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _saveAsPlan,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Use this workout'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BucketCountRow extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onChanged;

  const _BucketCountRow({
    required this.label,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Fewer $label',
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'More $label',
            onPressed: () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}

class _SourcePickerField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SourcePickerField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  static String _label(String? value) {
    if (value == null) return 'All libraries';
    if (value == seedLibraryFilter) return 'Standard library only';
    if (value == ownExercisesFilter) return 'Not in library';
    if (value.startsWith('plan:')) return 'Plan: ${value.substring(5)}';
    if (value.startsWith('author:')) return 'By: ${value.substring(7)}';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'From which library',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: value,
          items: [
            const DropdownMenuItem(value: null, child: Text('All libraries')),
            const DropdownMenuItem(
              value: seedLibraryFilter,
              child: Text('Standard library only'),
            ),
            const DropdownMenuItem(
              value: ownExercisesFilter,
              child: Text('Not in library'),
            ),
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(_label(option))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BucketResultCard extends StatelessWidget {
  final GeneratedBucket bucket;

  const _BucketResultCard({required this.bucket});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bucket.spec.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (bucket.shortfall > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Only found ${bucket.exercises.length} of '
                  '${bucket.spec.count} requested.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            if (bucket.exercises.isEmpty)
              const Text('None found')
            else
              for (final exercise in bucket.exercises)
                Text('• ${exercise.name}'),
          ],
        ),
      ),
    );
  }
}
