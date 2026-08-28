import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Stream<List<Exercise>> watchAllExercises() => select(exercises).watch();

  Future<Exercise?> getExerciseById(String id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> upsertExercise(ExercisesCompanion entry) =>
      into(exercises).insertOnConflictUpdate(entry);

  Future<void> upsertExercises(List<ExercisesCompanion> entries) {
    return batch((b) => b.insertAllOnConflictUpdate(exercises, entries));
  }

  Future<int> deleteExercise(String id) =>
      (delete(exercises)..where((e) => e.id.equals(id))).go();

  /// Custom (user-created) exercises only - what a full backup needs to
  /// round-trip; seed-library exercises are reseeded on import instead of
  /// being duplicated into every backup.
  Future<List<Exercise>> getCustomExercises() =>
      (select(exercises)..where((e) => e.isCustom.equals(true))).get();

  /// Search/filter over the library. All filters are optional and AND-ed
  /// together; [query] matches against name (case-insensitive substring).
  ///
  /// [creator] encodes which creator-filter the user picked: `ownExercisesFilter`
  /// for custom exercises with no plan/author attribution, `'plan:<name>'`
  /// for exercises created while importing that plan, or `'author:<name>'`
  /// for exercises tagged with that free-text author.
  Future<List<Exercise>> search({
    String? query,
    String? category,
    String? equipment,
    String? difficulty,
    String? creator,
  }) {
    final q = select(exercises);
    if (query != null && query.trim().isNotEmpty) {
      q.where((e) => e.name.lower().contains(query.trim().toLowerCase()));
    }
    if (category != null) {
      q.where((e) => e.category.equals(category));
    }
    if (equipment != null) {
      q.where((e) => e.equipment.equals(equipment));
    }
    if (difficulty != null) {
      q.where((e) => e.difficulty.equals(difficulty));
    }
    if (creator == ownExercisesFilter) {
      q.where(
        (e) =>
            e.isCustom.equals(true) &
            e.sourcePlanName.isNull() &
            e.author.isNull(),
      );
    } else if (creator != null && creator.startsWith('plan:')) {
      q.where((e) => e.sourcePlanName.equals(creator.substring(5)));
    } else if (creator != null && creator.startsWith('author:')) {
      q.where((e) => e.author.equals(creator.substring(7)));
    }
    return q.get();
  }

  /// Where an exercise is currently referenced, so deleting it can say what
  /// would be affected instead of just failing or silently orphaning rows.
  Future<ExerciseUsage> getExerciseUsage(String exerciseId) async {
    final planRows = await (select(
      db.planExercises,
    )..where((e) => e.exerciseId.equals(exerciseId))).get();

    final planNames = <String>{};
    for (final row in planRows) {
      final session = await (select(
        db.planSessions,
      )..where((s) => s.id.equals(row.sessionId))).getSingleOrNull();
      if (session == null) continue;
      final plan = await (select(
        db.plans,
      )..where((p) => p.id.equals(session.planId))).getSingleOrNull();
      if (plan != null) planNames.add(plan.name);
    }

    final loggedSetCount = (await (select(
      db.loggedSets,
    )..where((s) => s.exerciseId.equals(exerciseId))).get()).length;

    return ExerciseUsage(
      planReferences: planRows.length,
      planNames: planNames.toList()..sort(),
      loggedSets: loggedSetCount,
    );
  }

  /// Removes an exercise from every plan that prescribes it, then deletes the
  /// library entry - while leaving logged sets intact.
  ///
  /// Logged sets keep their `exercise_id` pointing at the now-deleted row.
  /// That's deliberate: the history is a record of what was actually done and
  /// shouldn't evaporate because the library entry was tidied up. Screens
  /// resolve names defensively and fall back to the stored id.
  Future<void> deleteExerciseKeepingHistory(String exerciseId) {
    return transaction(() async {
      await (delete(
        db.planExercises,
      )..where((e) => e.exerciseId.equals(exerciseId))).go();
      await (delete(exercises)..where((e) => e.id.equals(exerciseId))).go();
    });
  }

  /// Every distinct `plan:<name>`/`author:<name>` creator-filter value in the
  /// library, for populating the Exercise Library's creator filter.
  Future<List<String>> getCreatorFilterOptions() async {
    final all = await getAllExercises();
    final options = <String>{};
    for (final e in all) {
      if (e.sourcePlanName != null) options.add('plan:${e.sourcePlanName}');
      if (e.author != null) options.add('author:${e.author}');
    }
    final sorted = options.toList()..sort();
    return sorted;
  }
}

/// Sentinel for [ExerciseDao.search]'s `creator` filter: custom exercises
/// with no plan/author attribution (created standalone, not via an import).
const ownExercisesFilter = '__own__';

/// Where an exercise is referenced, for showing the consequences of deleting
/// it before anything is destroyed.
class ExerciseUsage {
  /// How many plan rows prescribe this exercise.
  final int planReferences;

  /// Names of the plans involved, for naming them in a confirmation.
  final List<String> planNames;

  /// How many sets have ever been logged against it - the irreplaceable part.
  final int loggedSets;

  const ExerciseUsage({
    required this.planReferences,
    required this.planNames,
    required this.loggedSets,
  });

  bool get isUnused => planReferences == 0 && loggedSets == 0;
}
