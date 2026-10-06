import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'plans_table.dart';

/// One execution of a scheduled [PlanSessions] row - created when the user
/// starts logging a workout in execution mode. Mirrors
/// schema/backup.schema.json's "sessionLog", except it references the
/// specific [PlanSessions] row (`planSessionId`) rather than duplicating
/// `plan_id` + `session_name` as flat fields - the JSON export (Phase 3)
/// derives those via a join instead of storing them redundantly here.
///
/// [planSessionId] is nullable so this table can also hold an **ad-hoc
/// activity** - a walk, run, or anything else logged directly against a
/// date rather than against a scheduled plan session. An ad-hoc row has no
/// [LoggedSets] children at all (there's no exercise to log sets against);
/// its own [activityName]/[durationSec]/[distance] describe what was done
/// instead. `planSessionId == null` is exactly what distinguishes the two
/// kinds everywhere they're read back (calendar, workout history, backup).
class SessionLogs extends Table {
  TextColumn get id => text()();
  IntColumn get planSessionId => integer().nullable().references(
    PlanSessions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get loggedAt => dateTime()();

  /// Null means this row is a **draft** - an in-progress execution-mode
  /// session autosaved (see `execution_screen.dart`'s app-lifecycle
  /// observer) so a set already checked off survives the app process being
  /// killed while backgrounded, without ever showing up anywhere a real,
  /// finished workout would (Progress, History, Calendar, backup export -
  /// every one of `SessionLogDao`'s read queries filters on
  /// `finishedAt.isNotNull()`). Set the instant a row is created for
  /// [SessionLogDao.createSessionLog]/[SessionLogDao.createAdHocActivity] -
  /// those two are the only ways a *real* log has ever been created, so
  /// existing rows predating this column are backfilled to `loggedAt` in the
  /// schema 10->11 migration. A draft row is replaced wholesale (delete +
  /// reinsert) on every autosave rather than diffed/updated in place - see
  /// [SessionLogDao.saveDraft].
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Optional free-text note taken right after finishing, e.g. "felt heavy
  /// today" - surfaced on the workout's own detail screen.
  TextColumn get notes => text().nullable()();

  /// Non-null only for an ad-hoc activity (e.g. "Walk", "Run", "Yoga") -
  /// null for a normal plan-session log, which gets its name from the plan
  /// session it belongs to instead.
  TextColumn get activityName => text().nullable()();
  RealColumn get durationSec => real().nullable()();
  RealColumn get distance => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One completed set within a [SessionLogs] entry. Mirrors
/// schema/backup.schema.json's "loggedSet". Exactly one of
/// weight+reps / durationSec / distance is populated depending on the
/// exercise's measurement type; the others stay null.
class LoggedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionLogId =>
      text().references(SessionLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setNumber => integer()();

  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get durationSec => real().nullable()();
  RealColumn get distance => real().nullable()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();

  /// Free-text feedback the trainee attaches to this specific set while
  /// logging it (e.g. "shoulder felt off on this one") - the trainee-to-
  /// trainer counterpart of `PlanExercises.notes` (the trainer's own
  /// prescription note, already shown in execution mode). Deliberately
  /// per-set rather than a single per-exercise field, matching this table's
  /// existing granularity (`rpe`/`isPr` are per set too) - a note meant for
  /// the whole exercise is simply attached to its first set; the trainer
  /// report renders any non-empty note under the exercise it belongs to.
  TextColumn get notes => text().nullable()();
}

/// One prescribed exercise skipped during a finished [SessionLogs] entry
/// (machine busy, pain, no equipment...), optionally with the exercise done
/// in its place. Feeds the Today tab's make-up list and the trainer PDF.
///
/// The prescription and both exercise names are snapshots rather than a
/// reference to the `PlanExercises` row, since plans get edited, forked and
/// deleted after the fact while this record has to keep saying what was
/// actually missed.
///
/// A skip counts as made up once any later finished session logs a set of
/// the same [exerciseId] - derived at read time (see
/// `SessionLogDao.getPendingMakeUps`), not stored, so it can never drift
/// from the actual history.
class SkippedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionLogId =>
      text().references(SessionLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseName => text()();
  IntColumn get prescribedSets => integer()();
  TextColumn get prescribedReps => text()();
  TextColumn get prescribedWeightIntensity =>
      text().withDefault(const Constant(''))();
  IntColumn get prescribedRestSec => integer().nullable()();

  /// A `SkipReason.key`, or null when no reason was picked.
  TextColumn get reason => text().nullable()();

  /// Set only when a substitute was actually logged in its place.
  TextColumn get replacedByExerciseId => text().nullable()();
  TextColumn get replacedByExerciseName => text().nullable()();

  /// "Add to next session" from the Today tab - the next execution-mode
  /// session offers it as an optional extra.
  BoolColumn get queuedForNextSession =>
      boolean().withDefault(const Constant(false))();

  /// The trainee explicitly dropped it from the make-up list.
  DateTimeColumn get dismissedAt => dateTime().nullable()();
}
