// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_dao.dart';

// ignore_for_file: type=lint
mixin _$MaintenanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $PlansTable get plans => attachedDatabase.plans;
  $PlanSessionsTable get planSessions => attachedDatabase.planSessions;
  $PlanExercisesTable get planExercises => attachedDatabase.planExercises;
  $SessionLogsTable get sessionLogs => attachedDatabase.sessionLogs;
  $LoggedSetsTable get loggedSets => attachedDatabase.loggedSets;
  MaintenanceDaoManager get managers => MaintenanceDaoManager(this);
}

class MaintenanceDaoManager {
  final _$MaintenanceDaoMixin _db;
  MaintenanceDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db.attachedDatabase, _db.plans);
  $$PlanSessionsTableTableManager get planSessions =>
      $$PlanSessionsTableTableManager(_db.attachedDatabase, _db.planSessions);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db.attachedDatabase, _db.planExercises);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db.attachedDatabase, _db.sessionLogs);
  $$LoggedSetsTableTableManager get loggedSets =>
      $$LoggedSetsTableTableManager(_db.attachedDatabase, _db.loggedSets);
}
