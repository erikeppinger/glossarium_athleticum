// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_dao.dart';

// ignore_for_file: type=lint
mixin _$BlockDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlocksTable get blocks => attachedDatabase.blocks;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $BlockExercisesTable get blockExercises => attachedDatabase.blockExercises;
  BlockDaoManager get managers => BlockDaoManager(this);
}

class BlockDaoManager {
  final _$BlockDaoMixin _db;
  BlockDaoManager(this._db);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db.attachedDatabase, _db.blocks);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$BlockExercisesTableTableManager get blockExercises =>
      $$BlockExercisesTableTableManager(
        _db.attachedDatabase,
        _db.blockExercises,
      );
}
