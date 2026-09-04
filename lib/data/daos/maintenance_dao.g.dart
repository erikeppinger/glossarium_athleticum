// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_dao.dart';

// ignore_for_file: type=lint
mixin _$MaintenanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $PlansTable get plans => attachedDatabase.plans;
  $PlanSessionsTable get planSessions => attachedDatabase.planSessions;
  $PlanSessionDatesTable get planSessionDates =>
      attachedDatabase.planSessionDates;
  $PlanExercisesTable get planExercises => attachedDatabase.planExercises;
  $SessionLogsTable get sessionLogs => attachedDatabase.sessionLogs;
  $LoggedSetsTable get loggedSets => attachedDatabase.loggedSets;
  $BodyMeasurementsTable get bodyMeasurements =>
      attachedDatabase.bodyMeasurements;
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
  $$PlanSessionDatesTableTableManager get planSessionDates =>
      $$PlanSessionDatesTableTableManager(
        _db.attachedDatabase,
        _db.planSessionDates,
      );
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db.attachedDatabase, _db.planExercises);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db.attachedDatabase, _db.sessionLogs);
  $$LoggedSetsTableTableManager get loggedSets =>
      $$LoggedSetsTableTableManager(_db.attachedDatabase, _db.loggedSets);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(
        _db.attachedDatabase,
        _db.bodyMeasurements,
      );
}
