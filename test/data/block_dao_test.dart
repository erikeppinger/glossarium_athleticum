import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/block_dao.dart';
import 'package:training_app/data/daos/plan_dao.dart';

// Blocks are a reusable, named group of exercises (e.g. "Warm-up") that can
// be inserted into any session. Confirms the "stamp" semantics: a block's
// exercises are independent copies from the moment they're saved, so
// editing the source session (or the block itself) afterward never
// retroactively changes the other.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> seedExercises() async {
    for (final id in ['EX_A', 'EX_B']) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: id,
          category: 'Accessory',
          movementPattern: 'Pull',
          muscleGroups: 'Back',
          equipment: 'None (Bodyweight)',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
        ),
      );
    }
  }

  test('createBlock then getBlockDetails round-trips name and exercises in order', () async {
    await seedExercises();
    final blockId = await db.blockDao.createBlock(
      name: 'Warm-up',
      exercises: const [
        BlockExerciseInput(
          order: 1,
          exerciseId: 'EX_A',
          exerciseName: 'EX_A',
          sets: 2,
          reps: '10',
        ),
        BlockExerciseInput(
          order: 2,
          exerciseId: 'EX_B',
          exerciseName: 'EX_B',
          sets: 1,
          reps: '15',
        ),
      ],
    );

    final details = await db.blockDao.getBlockDetails(blockId);
    expect(details, isNotNull);
    expect(details!.block.name, 'Warm-up');
    expect(details.exercises, hasLength(2));
    expect(details.exercises[0].exerciseName, 'EX_A');
    expect(details.exercises[1].exerciseName, 'EX_B');
  });

  test(
    'editing a block after inserting it into a session does not change the '
    'already-inserted (stamped) copy, and vice versa',
    () async {
      await seedExercises();
      final blockId = await db.blockDao.createBlock(
        name: 'Warm-up',
        exercises: const [
          BlockExerciseInput(
            order: 1,
            exerciseId: 'EX_A',
            exerciseName: 'EX_A',
            sets: 2,
            reps: '10',
          ),
        ],
      );

      // "Insert" the block into a real session - the actual stamp step a UI
      // action would perform.
      final blockDetails = await db.blockDao.getBlockDetails(blockId);
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan',
        sessions: [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Session',
            exercises: [
              for (final e in blockDetails!.exercises) e.toPlanInput(order: 1),
            ],
          ),
        ],
      );

      // Edit the block afterward - the already-inserted session exercise
      // must be untouched.
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
      await db.blockDao.updateBlockExercise(
        blockExerciseId: blockDetails.exercises.single.id,
        sets: 5,
        reps: '5',
        weightIntensity: '',
        notes: '',
      );

      final sessionExercise =
          (await db.planDao.getSessionDetails(sessionId))!.exercises.single;
      expect(sessionExercise.sets, 2);
      expect(sessionExercise.reps, '10');

      // Editing the already-inserted session exercise must not touch the
      // block either.
      await db.planDao.updatePlanExercise(
        planExerciseId: sessionExercise.id,
        sets: 99,
        reps: '99',
        weightIntensity: '',
        notes: '',
      );
      final blockExercise =
          (await db.blockDao.getBlockDetails(blockId))!.exercises.single;
      expect(blockExercise.sets, 5);
      expect(blockExercise.reps, '5');
    },
  );

  test('renameBlock updates the name; deleteBlock removes it and its exercises', () async {
    await seedExercises();
    final blockId = await db.blockDao.createBlock(
      name: 'Warm-up',
      exercises: const [
        BlockExerciseInput(
          order: 1,
          exerciseId: 'EX_A',
          exerciseName: 'EX_A',
          sets: 2,
          reps: '10',
        ),
      ],
    );

    await db.blockDao.renameBlock(blockId, 'Warm-up (updated)');
    expect((await db.blockDao.getBlockDetails(blockId))!.block.name, 'Warm-up (updated)');

    await db.blockDao.deleteBlock(blockId);
    expect(await db.blockDao.getBlockDetails(blockId), isNull);
    expect(await db.blockDao.getAllBlocks(), isEmpty);
  });

  test('removeBlockExercise closes the order gap; moveBlockExercise swaps order', () async {
    await seedExercises();
    final blockId = await db.blockDao.createBlock(
      name: 'Block',
      exercises: const [
        BlockExerciseInput(
          order: 1,
          exerciseId: 'EX_A',
          exerciseName: 'EX_A',
          sets: 1,
          reps: '1',
        ),
        BlockExerciseInput(
          order: 2,
          exerciseId: 'EX_B',
          exerciseName: 'EX_B',
          sets: 1,
          reps: '1',
        ),
      ],
    );
    var details = await db.blockDao.getBlockDetails(blockId);
    final firstId = details!.exercises[0].id;
    final secondId = details.exercises[1].id;

    await db.blockDao.moveBlockExercise(blockExerciseId: secondId, up: true);
    details = await db.blockDao.getBlockDetails(blockId);
    expect(details!.exercises[0].id, secondId);
    expect(details.exercises[1].id, firstId);

    await db.blockDao.removeBlockExercise(secondId);
    details = await db.blockDao.getBlockDetails(blockId);
    expect(details!.exercises, hasLength(1));
    expect(details.exercises.single.id, firstId);
    expect(details.exercises.single.order, 1);
  });
}
