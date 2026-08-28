import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/exercise_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  ExercisesCompanion exercise(String id, String name, {String category = 'Warm-up'}) {
    return ExercisesCompanion.insert(
      id: id,
      name: name,
      category: category,
      movementPattern: 'Mobility',
      muscleGroups: 'Shoulders',
      equipment: 'None',
      difficulty: 'Beginner',
      measurementType: 'Weight x Reps',
    );
  }

  test('upsert then getAllExercises round-trips', () async {
    await db.exerciseDao.upsertExercise(exercise('EX001', 'Band Pull-Apart'));
    final all = await db.exerciseDao.getAllExercises();
    expect(all, hasLength(1));
    expect(all.single.name, 'Band Pull-Apart');
  });

  test('upsert with same id updates rather than duplicates', () async {
    await db.exerciseDao.upsertExercise(exercise('EX001', 'Band Pull-Apart'));
    await db.exerciseDao.upsertExercise(exercise('EX001', 'Band Pull-Apart v2'));
    final all = await db.exerciseDao.getAllExercises();
    expect(all, hasLength(1));
    expect(all.single.name, 'Band Pull-Apart v2');
  });

  test('getExerciseById returns null for unknown id', () async {
    expect(await db.exerciseDao.getExerciseById('nope'), isNull);
  });

  test('deleteExercise removes it', () async {
    await db.exerciseDao.upsertExercise(exercise('EX001', 'Band Pull-Apart'));
    await db.exerciseDao.deleteExercise('EX001');
    expect(await db.exerciseDao.getAllExercises(), isEmpty);
  });

  group('search', () {
    setUp(() async {
      await db.exerciseDao.upsertExercises([
        exercise('EX001', 'Band Pull-Apart', category: 'Warm-up'),
        exercise('EX002', 'Deadlift', category: 'Main Lift'),
        exercise('EX003', 'Farmer\'s Carry', category: 'Loaded Carry'),
      ]);
    });

    test('by query matches case-insensitively', () async {
      final results = await db.exerciseDao.search(query: 'dead');
      expect(results.map((e) => e.id), ['EX002']);
    });

    test('by category filters exactly', () async {
      final results = await db.exerciseDao.search(category: 'Loaded Carry');
      expect(results.map((e) => e.id), ['EX003']);
    });

    test('with no filters returns everything', () async {
      final results = await db.exerciseDao.search();
      expect(results, hasLength(3));
    });

    test('combining query and category narrows further', () async {
      final results = await db.exerciseDao.search(query: 'carry', category: 'Loaded Carry');
      expect(results.map((e) => e.id), ['EX003']);
    });
  });

  group('creator filter', () {
    setUp(() async {
      await db.exerciseDao.upsertExercises([
        exercise('EX001', 'Seed Exercise'),
        ExercisesCompanion.insert(
          id: 'EX_OWN',
          name: 'Own Custom Exercise',
          category: 'Custom',
          movementPattern: '',
          muscleGroups: '',
          equipment: '',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
          isCustom: const Value(true),
        ),
        ExercisesCompanion.insert(
          id: 'EX_PLAN',
          name: 'Plan-Sourced Exercise',
          category: 'Custom',
          movementPattern: '',
          muscleGroups: '',
          equipment: '',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
          isCustom: const Value(true),
          sourcePlanName: const Value('Nine-Block Strength Program'),
        ),
        ExercisesCompanion.insert(
          id: 'EX_AUTHOR',
          name: 'Coach-Authored Exercise',
          category: 'Custom',
          movementPattern: '',
          muscleGroups: '',
          equipment: '',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
          isCustom: const Value(true),
          author: const Value('Coach Erik'),
        ),
      ]);
    });

    test('ownExercisesFilter matches only custom exercises with no plan/author', () async {
      final results = await db.exerciseDao.search(creator: ownExercisesFilter);
      expect(results.map((e) => e.id), ['EX_OWN']);
    });

    test('plan:<name> matches exercises sourced from that plan', () async {
      final results = await db.exerciseDao.search(
        creator: 'plan:Nine-Block Strength Program',
      );
      expect(results.map((e) => e.id), ['EX_PLAN']);
    });

    test('author:<name> matches exercises tagged with that author', () async {
      final results = await db.exerciseDao.search(creator: 'author:Coach Erik');
      expect(results.map((e) => e.id), ['EX_AUTHOR']);
    });

    test('getCreatorFilterOptions returns every distinct plan/author value', () async {
      final options = await db.exerciseDao.getCreatorFilterOptions();
      expect(options, [
        'author:Coach Erik',
        'plan:Nine-Block Strength Program',
      ]);
    });
  });
}
