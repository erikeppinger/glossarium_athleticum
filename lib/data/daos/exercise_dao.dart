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

  /// Search/filter over the library. All filters are optional and AND-ed
  /// together; [query] matches against name (case-insensitive substring).
  Future<List<Exercise>> search({
    String? query,
    String? category,
    String? equipment,
    String? difficulty,
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
    return q.get();
  }
}
