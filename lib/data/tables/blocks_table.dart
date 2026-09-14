import 'package:drift/drift.dart';

import 'exercises_table.dart';

/// A named, reusable group of exercises (e.g. "Warm-up") that can be
/// inserted into any session without rebuilding it from scratch each time -
/// see `block_dao.dart`'s own doc comment for why inserting one stamps a
/// fresh copy rather than linking back to this row.
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One exercise-in-block row - the same fields as `PlanExercises` minus
/// `sessionId` and `supersetGroupId`: a block is a flat, ordered list with
/// no scheduling or grouping of its own, since those only mean something
/// once it's actually been inserted into a real session.
class BlockExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get blockId =>
      text().references(Blocks, #id, onDelete: KeyAction.cascade)();
  IntColumn get order => integer()();

  /// Resolved match against Exercises.id, same as `PlanExercises.exerciseId`.
  TextColumn get exerciseId =>
      text().nullable().references(Exercises, #id)();
  TextColumn get exerciseName => text()();

  IntColumn get sets => integer()();
  TextColumn get reps => text()();
  TextColumn get weightIntensity => text().withDefault(const Constant(''))();
  IntColumn get restSec => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get videoUrl => text().withDefault(const Constant(''))();
}
