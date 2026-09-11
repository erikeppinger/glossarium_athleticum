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

  group('setFavorite', () {
    test('defaults to false', () async {
      await db.exerciseDao.upsertExercise(exercise('EX001', 'Squat'));
      final row = await db.exerciseDao.getExerciseById('EX001');
      expect(row!.isFavorite, isFalse);
    });

    test('toggles and persists', () async {
      await db.exerciseDao.upsertExercise(exercise('EX001', 'Squat'));

      await db.exerciseDao.setFavorite('EX001', true);
      expect((await db.exerciseDao.getExerciseById('EX001'))!.isFavorite, isTrue);

      await db.exerciseDao.setFavorite('EX001', false);
      expect((await db.exerciseDao.getExerciseById('EX001'))!.isFavorite, isFalse);
    });

    test('only affects the targeted exercise', () async {
      await db.exerciseDao.upsertExercise(exercise('EX001', 'Squat'));
      await db.exerciseDao.upsertExercise(exercise('EX002', 'Bench Press'));

      await db.exerciseDao.setFavorite('EX001', true);

      expect((await db.exerciseDao.getExerciseById('EX001'))!.isFavorite, isTrue);
      expect((await db.exerciseDao.getExerciseById('EX002'))!.isFavorite, isFalse);
    });
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

  // "Manage libraries" screen support - bulk operations on a whole
  // sourcePlanName/author group at once, rather than one exercise at a time.
  group('library management bulk operations', () {
    setUp(() async {
      await db.exerciseDao.upsertExercise(
        exercise('EX1', 'Ex 1').copyWith(
          isCustom: const Value(true),
          sourcePlanName: const Value('Old Plan Name'),
        ),
      );
      await db.exerciseDao.upsertExercise(
        exercise('EX2', 'Ex 2').copyWith(
          isCustom: const Value(true),
          sourcePlanName: const Value('Old Plan Name'),
        ),
      );
      await db.exerciseDao.upsertExercise(
        exercise('EX3', 'Ex 3').copyWith(
          isCustom: const Value(true),
          author: const Value('Old Author'),
        ),
      );
    });

    test('renameSourcePlanName relabels every exercise in that group', () async {
      await db.exerciseDao.renameSourcePlanName(
        oldName: 'Old Plan Name',
        newName: 'New Plan Name',
      );
      final all = await db.exerciseDao.getAllExercises();
      expect(
        all.where((e) => e.sourcePlanName == 'New Plan Name').map((e) => e.id),
        ['EX1', 'EX2'],
      );
      // The author-tagged exercise is a different group - untouched.
      expect(
        all.firstWhere((e) => e.id == 'EX3').author,
        'Old Author',
      );
    });

    test('renameAuthor relabels every exercise in that group', () async {
      await db.exerciseDao.renameAuthor(
        oldName: 'Old Author',
        newName: 'New Author',
      );
      final ex3 = await db.exerciseDao.getExerciseById('EX3');
      expect(ex3!.author, 'New Author');
    });

    test('deleteExercisesKeepingHistory removes every exercise in the group', () async {
      await db.exerciseDao.deleteExercisesKeepingHistory(['EX1', 'EX2']);
      final all = await db.exerciseDao.getAllExercises();
      expect(all.map((e) => e.id), ['EX3']);
    });

    test('deleteExercisesKeepingHistory with an empty list is a no-op', () async {
      await db.exerciseDao.deleteExercisesKeepingHistory([]);
      final all = await db.exerciseDao.getAllExercises();
      expect(all, hasLength(3));
    });
  });
}
