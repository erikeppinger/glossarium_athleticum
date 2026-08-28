import 'package:drift/drift.dart';

import 'exercises_table.dart';

/// A training plan. Mirrors schema/plan.schema.json's top level.
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set when the plan is archived - hidden from the plan list but fully
  /// intact and restorable. Archiving is the reversible way to get a plan
  /// out of the way; deleting is the irreversible one. Null = active.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row-group from the plan template: same Week + Day + Session Name.
/// Mirrors schema/plan.schema.json's "session" definition.
class PlanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planId =>
      text().references(Plans, #id, onDelete: KeyAction.cascade)();
  IntColumn get weekNumber => integer()();
  TextColumn get day => text()();
  TextColumn get sessionName => text()();

  /// Null while still template-only; set once placed on the calendar.
  DateTimeColumn get assignedDate => dateTime().nullable()();
}

/// One exercise-in-session row. Mirrors schema/plan.schema.json's
/// "planExercise" definition and one row of templates/training_plan_template.csv.
class PlanExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(PlanSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get order => integer()();

  /// Resolved match against Exercises.id; null until the import-preview
  /// screen resolves it (or the row was built from the in-app library directly).
  TextColumn get exerciseId =>
      text().nullable().references(Exercises, #id)();

  /// Raw name as typed/imported - kept even after resolution so re-export
  /// round-trips the original text.
  TextColumn get exerciseName => text()();

  IntColumn get sets => integer()();
  TextColumn get reps => text()();
  TextColumn get weightIntensity => text().withDefault(const Constant(''))();
  IntColumn get restSec => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get videoUrl => text().withDefault(const Constant(''))();
}
