// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlansTable get plans => attachedDatabase.plans;
  $PlanSessionsTable get planSessions => attachedDatabase.planSessions;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $PlanExercisesTable get planExercises => attachedDatabase.planExercises;
  PlanDaoManager get managers => PlanDaoManager(this);
}

class PlanDaoManager {
  final _$PlanDaoMixin _db;
  PlanDaoManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db.attachedDatabase, _db.plans);
  $$PlanSessionsTableTableManager get planSessions =>
      $$PlanSessionsTableTableManager(_db.attachedDatabase, _db.planSessions);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db.attachedDatabase, _db.planExercises);
}
