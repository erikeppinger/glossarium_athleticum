import 'package:drift/drift.dart';

import 'exercises_table.dart';

/// A training plan. Mirrors schema/plan.schema.json's top level.
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Who authored this plan (e.g. a trainer's name), for a plan handed off
  /// as a file to someone else to train from - purely free text, no real
  /// identity/account system behind it (this app has none). Null for a plan
  /// someone built for themselves, which is the common case and has no
  /// "author" worth stating. Unlike `Exercises.author`/`sourcePlanName`
  /// (which get *regenerated* per import - see `plan_json_import.dart`),
  /// this round-trips the original value through export/import unchanged,
  /// since the whole point is a trainer's name surviving the handoff to a
  /// client's device.
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set when the plan is archived - hidden from the plan list but fully
  /// intact and restorable. Archiving is the reversible way to get a plan
  /// out of the way; deleting is the irreversible one. Null = active.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// For a plan imported from someone else's file (typically a trainer's):
  /// the `id` that plan has in the file. Imports always get a fresh local
  /// id, so this is how a later, updated version of the same plan is
  /// recognised (see `checkPlanSync`). Null for a plan built here.
  TextColumn get sourcePlanId => text().nullable()();

  /// The `updated_at` of the version this plan was last imported or
  /// updated from - the same version arriving again is "already up to date".
  DateTimeColumn get sourceUpdatedAt => dateTime().nullable()();

  /// `planContentFingerprint` of that version's contents. When the current
  /// contents still match, the user hasn't edited the plan, so an update
  /// can replace them with a single confirmation.
  TextColumn get sourceContentHash => text().nullable()();

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

  /// Non-null when this row is one member of a superset/circuit within its
  /// own session - every row sharing the same value is done back-to-back
  /// in round-robin order with one shared rest between rounds (see
  /// execution_screen.dart's `_groupedExercisesFor`/`_SupersetCard`). A
  /// small integer **scoped only to its own session** - not a foreign key,
  /// not globally unique - so two different sessions can each legitimately
  /// have a group numbered 1 without colliding, and grouping survives
  /// cloning a session (duplicateSessionToWeeks) or forking a plan for
  /// free. Set/cleared via PlanDao.setSupersetGroup/clearSupersetGroup.
  IntColumn get supersetGroupId => integer().nullable()();

  /// Same opt-in as Exercises.embeddingAllowed, but for this specific
  /// prescription's own [videoUrl] - a plan's video can differ from the
  /// library exercise's own (e.g. a trainer's demo of this exact variation),
  /// so it carries its own independent flag rather than inheriting the
  /// library exercise's. Note: nothing renders a plan exercise's video today
  /// (see execution_screen.dart) - this only stamps the author's choice
  /// through import/fork/export so it isn't lost once a display exists.
  BoolColumn get embeddingAllowed =>
      boolean().withDefault(const Constant(false))();
}
