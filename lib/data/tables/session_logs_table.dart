import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'plans_table.dart';

/// One execution of a scheduled [PlanSessions] row - created when the user
/// starts logging a workout in execution mode. Mirrors
/// schema/backup.schema.json's "sessionLog", except it references the
/// specific [PlanSessions] row (`planSessionId`) rather than duplicating
/// `plan_id` + `session_name` as flat fields - the JSON export (Phase 3)
/// derives those via a join instead of storing them redundantly here.
class SessionLogs extends Table {
  TextColumn get id => text()();
  IntColumn get planSessionId =>
      integer().references(PlanSessions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get loggedAt => dateTime()();

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
}
