import 'package:drift/drift.dart';

import '../../logic/exercise_name_matching.dart';
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

  Future<void> setFavorite(String exerciseId, bool isFavorite) =>
      (update(exercises)..where((e) => e.id.equals(exerciseId))).write(
        ExercisesCompanion(isFavorite: Value(isFavorite)),
      );

  /// Partial update for just the image columns of an already-existing
  /// exercise - deliberately not `upsertExercise`, whose
  /// `insertOnConflictUpdate` validates the companion as if it might need to
  /// perform a real INSERT (requiring every non-nullable column, e.g. name/
  /// category, to be present) even though the row is always known to already
  /// exist at every call site.
  Future<void> attachImages(
    String exerciseId, {
    required String imagePath,
    required String? imagePaths,
  }) => (update(exercises)..where((e) => e.id.equals(exerciseId))).write(
    ExercisesCompanion(
      imagePath: Value(imagePath),
      imagePaths: Value(imagePaths),
    ),
  );

  /// Custom (user-created) exercises only - what a full backup needs to
  /// round-trip; seed-library exercises are reseeded on import instead of
  /// being duplicated into every backup.
  Future<List<Exercise>> getCustomExercises() =>
      (select(exercises)..where((e) => e.isCustom.equals(true))).get();

  /// Search/filter over the library. All filters are optional and AND-ed
  /// together; [query] matches against name (case-insensitive, diacritic-
  /// insensitive substring).
  ///
  /// [query] is deliberately matched in Dart, not via SQL's `LOWER()` -
  /// SQLite's built-in `LOWER()` only case-folds ASCII, so a query like
  /// "Überkopf" (capitalized, non-ASCII) would never match a stored
  /// "Überkopfdrücken" even though Dart's own `toLowerCase()` on the query
  /// side already lowercases it correctly - the two sides silently disagreed
  /// on what "lowercase" means. Folding both sides through [foldDiacritics]
  /// here also fixes the same-family gap where a plain "ss" spelling
  /// wouldn't find a stored "ß" (e.g. "Strassenlauf" now finds
  /// "Straßenlauf"). The library is small (tens to low hundreds of rows), so
  /// filtering the query in Dart after the other, exact-value SQL filters
  /// run is not a real cost - the same tradeoff this DAO already made for
  /// the multi-select category/area filters.
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
  }) async {
    final q = select(exercises);
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
    final rows = await q.get();
    if (query == null || query.trim().isEmpty) return rows;
    final needle = foldDiacritics(query.trim().toLowerCase());
    return rows
        .where((e) => foldDiacritics(e.name.toLowerCase()).contains(needle))
        .toList();
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

  /// Bulk version of [deleteExerciseKeepingHistory], for the "manage
  /// libraries" screen's "delete this whole group" action - one transaction
  /// rather than one per exercise, same "children before parents" ordering.
  /// Never touches `SessionLogs`/`LoggedSets`, same as the single-exercise
  /// version: logged history is kept regardless of what happens to the
  /// library entry it references.
  Future<void> deleteExercisesKeepingHistory(List<String> exerciseIds) {
    if (exerciseIds.isEmpty) return Future.value();
    return transaction(() async {
      await (delete(
        db.planExercises,
      )..where((e) => e.exerciseId.isIn(exerciseIds))).go();
      await (delete(exercises)..where((e) => e.id.isIn(exerciseIds))).go();
    });
  }

  /// Renames every exercise's `sourcePlanName` from [oldName] to [newName] -
  /// the "manage libraries" screen's rename action for a `plan:<name>`
  /// group. Exercises are grouped by this value purely for display/filtering
  /// (see `getCreatorFilterOptions`) - there's no separate "library" row to
  /// update, so relabelling the group means relabelling every exercise in it.
  Future<void> renameSourcePlanName({
    required String oldName,
    required String newName,
  }) {
    return (update(
      exercises,
    )..where((e) => e.sourcePlanName.equals(oldName))).write(
      ExercisesCompanion(sourcePlanName: Value(newName)),
    );
  }

  /// Same as [renameSourcePlanName], for an `author:<name>` group.
  Future<void> renameAuthor({
    required String oldName,
    required String newName,
  }) {
    return (update(exercises)..where((e) => e.author.equals(oldName))).write(
      ExercisesCompanion(author: Value(newName)),
    );
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
