// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_log_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlansTable get plans => attachedDatabase.plans;
  $PlanSessionsTable get planSessions => attachedDatabase.planSessions;
  $SessionLogsTable get sessionLogs => attachedDatabase.sessionLogs;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $LoggedSetsTable get loggedSets => attachedDatabase.loggedSets;
  SessionLogDaoManager get managers => SessionLogDaoManager(this);
}

class SessionLogDaoManager {
  final _$SessionLogDaoMixin _db;
  SessionLogDaoManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db.attachedDatabase, _db.plans);
  $$PlanSessionsTableTableManager get planSessions =>
      $$PlanSessionsTableTableManager(_db.attachedDatabase, _db.planSessions);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db.attachedDatabase, _db.sessionLogs);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$LoggedSetsTableTableManager get loggedSets =>
      $$LoggedSetsTableTableManager(_db.attachedDatabase, _db.loggedSets);
}
