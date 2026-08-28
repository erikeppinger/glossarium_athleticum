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
