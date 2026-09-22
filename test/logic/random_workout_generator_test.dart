import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/exercise_dao.dart' show ownExercisesFilter;
import 'package:training_app/logic/muscle_group_colors.dart';
import 'package:training_app/logic/random_workout_generator.dart';

Exercise _exercise({
  required String id,
  required String category,
  String muscleGroups = '',
  String equipment = 'None (Bodyweight)',
  bool isCustom = false,
  String? sourcePlanName,
  String? author,
}) {
  return Exercise(
    id: id,
    name: id,
    category: category,
    movementPattern: '',
    muscleGroups: muscleGroups,
    equipment: equipment,
    difficulty: 'Beginner',
    measurementType: 'Weight x Reps',
    description: '',
    safetyNotes: '',
    videoReference: '',
    embeddingAllowed: false,
    isCustom: isCustom,
    sourcePlanName: sourcePlanName,
    author: author,
    imagePath: null,
    imagePaths: null,
    isFavorite: false,
  );
}

void main() {
  group('generateRandomWorkout', () {
    final library = [
      _exercise(id: 'warmup1', category: 'Warm-up'),
      _exercise(id: 'warmup2', category: 'Warm-up'),
      _exercise(id: 'leg1', category: 'Main Lift', muscleGroups: 'Quads'),
      _exercise(id: 'leg2', category: 'Main Lift', muscleGroups: 'Hamstrings'),
      _exercise(id: 'leg3', category: 'Accessory', muscleGroups: 'Calves'),
      _exercise(id: 'chest1', category: 'Main Lift', muscleGroups: 'Chest'),
      _exercise(id: 'core1', category: 'Accessory', muscleGroups: 'Abs, Core'),
    ];

    test('fills each bucket from its own category/area filter', () {
      final workout = generateRandomWorkout(
        library: library,
        buckets: const [
          WorkoutBucketSpec(label: 'Warm-up', count: 1, category: 'Warm-up'),
          WorkoutBucketSpec(label: 'Legs', count: 2, areas: {MuscleArea.legs}),
          WorkoutBucketSpec(label: 'Core', count: 1, areas: {MuscleArea.core}),
        ],
        random: Random(1),
      );

      expect(workout.buckets[0].exercises, hasLength(1));
      expect(workout.buckets[0].exercises.single.category, 'Warm-up');
      expect(workout.buckets[1].exercises, hasLength(2));
      expect(
        workout.buckets[1].exercises.map((e) => e.id),
        everyElement(anyOf('leg1', 'leg2', 'leg3')),
      );
      expect(workout.buckets[2].exercises.single.id, 'core1');
      expect(workout.hasAnyShortfall, isFalse);
    });

    test(
      'reports a shortfall rather than padding when a bucket asks for more '
      'than the filtered library has',
      () {
        final workout = generateRandomWorkout(
          library: library,
          buckets: const [
            WorkoutBucketSpec(label: 'Warm-up', count: 5, category: 'Warm-up'),
          ],
          random: Random(1),
        );
        expect(workout.buckets.single.exercises, hasLength(2));
        expect(workout.buckets.single.shortfall, 3);
        expect(workout.hasAnyShortfall, isTrue);
      },
    );

    test('never picks the same exercise into two different buckets', () {
      // Both buckets target the same single warm-up-category pool.
      final workout = generateRandomWorkout(
        library: library,
        buckets: const [
          WorkoutBucketSpec(label: 'A', count: 1, category: 'Warm-up'),
          WorkoutBucketSpec(label: 'B', count: 1, category: 'Warm-up'),
        ],
        random: Random(1),
      );
      final ids = workout.allExercises.map((e) => e.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('requireOwnedEquipment excludes exercises the user cannot do', () {
      final libraryWithEquipment = [
        ..._equipmentLibrary(),
      ];
      final workout = generateRandomWorkout(
        library: libraryWithEquipment,
        buckets: const [WorkoutBucketSpec(label: 'Any', count: 5)],
        requireOwnedEquipment: true,
        equipmentOwned: {'Dumbbell'},
        random: Random(1),
      );
      expect(
        workout.allExercises.map((e) => e.id),
        isNot(contains('barbellOnly')),
      );
      expect(workout.allExercises.map((e) => e.id), contains('dumbbellOnly'));
      expect(
        workout.allExercises.map((e) => e.id),
        contains('bodyweightOnly'),
      );
    });

    test('source filter narrows to the requested library grouping', () {
      final mixedSourceLibrary = [
        _exercise(id: 'seed1', category: 'Main Lift'),
        _exercise(
          id: 'plan1',
          category: 'Main Lift',
          isCustom: true,
          sourcePlanName: 'My Plan',
        ),
        _exercise(
          id: 'author1',
          category: 'Main Lift',
          isCustom: true,
          author: 'Coach',
        ),
        _exercise(id: 'own1', category: 'Main Lift', isCustom: true),
      ];

      GeneratedWorkout run(String? source) => generateRandomWorkout(
        library: mixedSourceLibrary,
        buckets: const [WorkoutBucketSpec(label: 'Any', count: 10)],
        source: source,
        random: Random(1),
      );

      expect(run(seedLibraryFilter).allExercises.map((e) => e.id), ['seed1']);
      expect(run('plan:My Plan').allExercises.map((e) => e.id), ['plan1']);
      expect(run('author:Coach').allExercises.map((e) => e.id), ['author1']);
      expect(run(ownExercisesFilter).allExercises.map((e) => e.id), ['own1']);
      expect(run(null).allExercises, hasLength(4));
    });
  });
}

List<Exercise> _equipmentLibrary() => [
  _exercise(id: 'barbellOnly', category: 'Main Lift', equipment: 'Barbell'),
  _exercise(id: 'dumbbellOnly', category: 'Main Lift', equipment: 'Dumbbell'),
  _exercise(
    id: 'bodyweightOnly',
    category: 'Main Lift',
    equipment: 'None (Bodyweight)',
  ),
];
