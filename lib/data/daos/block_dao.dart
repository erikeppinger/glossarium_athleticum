import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/blocks_table.dart';
import 'plan_dao.dart' show PlanExerciseInput;

part 'block_dao.g.dart';

/// One exercise-in-block entry, as supplied when creating or editing a
/// block - the same shape as `PlanExerciseInput` minus `supersetGroupId`
/// (grouping only makes sense once a block's exercises are actually
/// inserted into a real session).
class BlockExerciseInput {
  final int order;
  final String? exerciseId;
  final String exerciseName;
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;
  final String videoUrl;

  const BlockExerciseInput({
    required this.order,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.exerciseId,
    this.weightIntensity = '',
    this.restSec,
    this.notes = '',
    this.videoUrl = '',
  });
}

/// The "stamp" step for saving a session's exercises as a block: copies
/// whatever a `PlanExercise` row looked like at this exact moment into a
/// block input, completely independent of the source row from here on -
/// later edits to that session (or to the block itself) never retroactively
/// affect the other. Same "fork, don't mutate shared data in place"
/// precedent this codebase already follows for forking a built-in exercise
/// into a custom one.
extension PlanExerciseToBlockInput on PlanExercise {
  BlockExerciseInput toBlockInput({int? order}) => BlockExerciseInput(
    order: order ?? this.order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    restSec: restSec,
    notes: notes,
    videoUrl: videoUrl,
  );
}

/// The reverse stamp - inserting a block into a real session converts each
/// of its rows back into a `PlanExerciseInput`, a fresh independent copy
/// again rather than a reference to the block, so a later edit to the block
/// never retroactively changes a session that already used it.
extension BlockExerciseToPlanInput on BlockExercise {
  PlanExerciseInput toPlanInput({required int order}) => PlanExerciseInput(
    order: order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    restSec: restSec,
    notes: notes,
    videoUrl: videoUrl,
  );
}

/// A fully-loaded block: the row plus its exercises, in order - the shape
/// the UI actually wants to work with, mirroring `PlanSessionDetails`.
class BlockDetails {
  final Block block;
  final List<BlockExercise> exercises;

  const BlockDetails({required this.block, required this.exercises});
}

@DriftAccessor(tables: [Blocks, BlockExercises])
class BlockDao extends DatabaseAccessor<AppDatabase> with _$BlockDaoMixin {
  BlockDao(super.db);

  Stream<List<Block>> watchAllBlocks() =>
      (select(blocks)..orderBy([(b) => OrderingTerm.asc(b.name)])).watch();

  Future<List<Block>> getAllBlocks() =>
      (select(blocks)..orderBy([(b) => OrderingTerm.asc(b.name)])).get();

  Future<String> createBlock({
    required String name,
    String notes = '',
    required List<BlockExerciseInput> exercises,
  }) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    return transaction(() async {
      await into(blocks).insert(
        BlocksCompanion.insert(
          id: id,
          name: name,
          notes: Value(notes),
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (final e in exercises) {
        await into(blockExercises).insert(
          BlockExercisesCompanion.insert(
            blockId: id,
            order: e.order,
            exerciseId: Value(e.exerciseId),
            exerciseName: e.exerciseName,
            sets: e.sets,
            reps: e.reps,
            weightIntensity: Value(e.weightIntensity),
            restSec: Value(e.restSec),
            notes: Value(e.notes),
            videoUrl: Value(e.videoUrl),
          ),
        );
      }
      return id;
    });
  }

  Future<BlockDetails?> getBlockDetails(String blockId) async {
    final block = await (select(
      blocks,
    )..where((b) => b.id.equals(blockId))).getSingleOrNull();
    if (block == null) return null;
    return BlockDetails(block: block, exercises: await _exercisesFor(blockId));
  }

  Future<List<BlockExercise>> _exercisesFor(String blockId) {
    return (select(blockExercises)
          ..where((e) => e.blockId.equals(blockId))
          ..orderBy([(e) => OrderingTerm.asc(e.order)]))
        .get();
  }

  Future<void> renameBlock(String blockId, String name) {
    return (update(blocks)..where((b) => b.id.equals(blockId))).write(
      BlocksCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
    );
  }

  /// A block's exercises are already independent stamped copies the moment
  /// they're inserted anywhere - nothing else in the schema references a
  /// block, so deleting one can never affect a session that already used
  /// it. No "used in N places" impact check needed before this, unlike
  /// deleting an exercise or a plan.
  Future<void> deleteBlock(String blockId) =>
      (delete(blocks)..where((b) => b.id.equals(blockId))).go();

  Future<void> addExerciseToBlock({
    required String blockId,
    required BlockExerciseInput input,
  }) {
    return transaction(() async {
      final existingOrders = await (select(
        blockExercises,
      )..where((e) => e.blockId.equals(blockId))).map((e) => e.order).get();
      final nextOrder = existingOrders.isEmpty
          ? 1
          : existingOrders.reduce((a, b) => a > b ? a : b) + 1;
      await into(blockExercises).insert(
        BlockExercisesCompanion.insert(
          blockId: blockId,
          order: nextOrder,
          exerciseId: Value(input.exerciseId),
          exerciseName: input.exerciseName,
          sets: input.sets,
          reps: input.reps,
          weightIntensity: Value(input.weightIntensity),
          restSec: Value(input.restSec),
          notes: Value(input.notes),
          videoUrl: Value(input.videoUrl),
        ),
      );
      await _touchUpdatedAt(blockId);
    });
  }

  Future<void> updateBlockExercise({
    required int blockExerciseId,
    required int sets,
    required String reps,
    required String weightIntensity,
    int? restSec,
    required String notes,
  }) {
    return transaction(() async {
      final blockId = await _blockIdFor(blockExerciseId);
      await (update(
        blockExercises,
      )..where((e) => e.id.equals(blockExerciseId))).write(
        BlockExercisesCompanion(
          sets: Value(sets),
          reps: Value(reps),
          weightIntensity: Value(weightIntensity),
          restSec: Value(restSec),
          notes: Value(notes),
        ),
      );
      await _touchUpdatedAt(blockId);
    });
  }

  /// Removes one exercise and closes the gap it leaves in `order` - mirrors
  /// `PlanDao.removeExercise`, but with no fork: a block has no logged
  /// history of its own, so editing it in place is always safe.
  Future<void> removeBlockExercise(int blockExerciseId) {
    return transaction(() async {
      final row = await (select(
        blockExercises,
      )..where((e) => e.id.equals(blockExerciseId))).getSingle();
      await (delete(
        blockExercises,
      )..where((e) => e.id.equals(blockExerciseId))).go();

      final remaining =
          await (select(blockExercises)
                ..where((e) => e.blockId.equals(row.blockId))
                ..orderBy([(e) => OrderingTerm.asc(e.order)]))
              .get();
      for (var i = 0; i < remaining.length; i++) {
        await (update(
          blockExercises,
        )..where((e) => e.id.equals(remaining[i].id))).write(
          BlockExercisesCompanion(order: Value(i + 1)),
        );
      }
      await _touchUpdatedAt(row.blockId);
    });
  }

  Future<void> moveBlockExercise({
    required int blockExerciseId,
    required bool up,
  }) {
    return transaction(() async {
      final row = await (select(
        blockExercises,
      )..where((e) => e.id.equals(blockExerciseId))).getSingle();

      final siblings =
          await (select(blockExercises)
                ..where((e) => e.blockId.equals(row.blockId))
                ..orderBy([(e) => OrderingTerm.asc(e.order)]))
              .get();
      final index = siblings.indexWhere((e) => e.id == blockExerciseId);
      final swapIndex = up ? index - 1 : index + 1;
      if (swapIndex < 0 || swapIndex >= siblings.length) return;

      final other = siblings[swapIndex];
      await (update(blockExercises)..where((e) => e.id.equals(row.id))).write(
        BlockExercisesCompanion(order: Value(other.order)),
      );
      await (update(
        blockExercises,
      )..where((e) => e.id.equals(other.id))).write(
        BlockExercisesCompanion(order: Value(row.order)),
      );
      await _touchUpdatedAt(row.blockId);
    });
  }

  Future<String> _blockIdFor(int blockExerciseId) async {
    final row = await (select(
      blockExercises,
    )..where((e) => e.id.equals(blockExerciseId))).getSingle();
    return row.blockId;
  }

  Future<void> _touchUpdatedAt(String blockId) {
    return (update(blocks)..where((b) => b.id.equals(blockId))).write(
      BlocksCompanion(updatedAt: Value(DateTime.now())),
    );
  }
}
