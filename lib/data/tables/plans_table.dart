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

  /// Tri-state opt-in for a periodic "check your progress on this plan"
  /// reminder - 'notAsked'/'enabled'/'declined', same reasoning as
  /// `BodyTracking`: a "no" is remembered rather than asked again. Per-plan
  /// (not a device-wide setting, unlike the existing weekly-digest
  /// notification) since interest in check-ins can differ per plan. Asked
  /// once at first session start - see plan_report_prompt.dart.
  TextColumn get reportPreference =>
      text().withDefault(const Constant('notAsked'))();

  /// Days between reminders once enabled (7/14/30 offered at opt-in time) -
  /// null until enabled.
  IntColumn get reportFrequencyDays => integer().nullable()();

  /// When the plan owner opted in - the anchor point reminders are computed
  /// from each time they're rebuilt, so "every 7 days" means every 7 days
  /// from when they said yes, not from some arbitrary fixed epoch.
  DateTimeColumn get reportOptInAt => dateTime().nullable()();

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
}

/// One date a `PlanSessions` row is scheduled on - a session can have zero,
/// one, or many of these (e.g. the same "Push Day" placed on several
/// Mondays). Used to be a single nullable `assignedDate` column directly on
/// `PlanSessions`; pulled into its own table so a session isn't limited to
/// one scheduled occurrence at a time. Removing a row only ever unschedules
/// that date - it never touches `SessionLogs`, since what was actually
/// trained on a date is independent of whether that date is still "on the
/// calendar" as upcoming.
class PlanSessionDates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(PlanSessions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
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
