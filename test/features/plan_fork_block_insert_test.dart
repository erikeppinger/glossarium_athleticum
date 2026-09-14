import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/block_dao.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/plans/plan_fork.dart';

// "Insert block" (edit_session_screen.dart) builds the exact same
// existing-exercises-plus-block-exercises list `_addExercise` already does
// for a single exercise, then goes through the same fork - this exercises
// that combined list at the data level directly, matching plan_fork_test.dart's
// own established way of testing fork behavior without driving the
// fork-name dialog through the widget tree.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'a block\'s exercises land in the forked session, appended after the '
    'existing ones, as independent stamped copies',
    () async {
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: const [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Push Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseName: 'Bench Press',
                sets: 4,
                reps: '8-10',
              ),
            ],
          ),
        ],
      );
      final blockId = await db.blockDao.createBlock(
        name: 'Warm-up',
        exercises: const [
          BlockExerciseInput(
            order: 1,
            exerciseName: 'Band Pull-Apart',
            sets: 2,
            reps: '15',
          ),
          BlockExerciseInput(
            order: 2,
            exerciseName: 'Arm Circles',
            sets: 1,
            reps: '30s',
          ),
        ],
      );

      final source = (await db.planDao.getPlanDetails('plan-1'))!;
      final sessionId = source.sessions.single.session.id;
      final blockDetails = (await db.blockDao.getBlockDetails(blockId))!;

      // _forkAndNavigate (edit_session_screen.dart) always renumbers the
      // combined list 1..N by position before forking - replicate that
      // here, since this test calls the fork function directly rather than
      // going through that UI step.
      final combined = [
        for (final e in source.sessions.single.exercises) e.toInput(),
        for (final e in blockDetails.exercises) e.toPlanInput(order: 0),
      ];
      final ordered = [
        for (var i = 0; i < combined.length; i++) combined[i].withOrder(i + 1),
      ];

      final newPlanId = await forkPlanWithModifiedSession(
        db,
        sourcePlanId: 'plan-1',
        newPlanName: 'Plan A (edited)',
        editedSessionId: sessionId,
        newExercisesForEditedSession: ordered,
      );

      final forked = (await db.planDao.getPlanDetails(newPlanId))!;
      expect(forked.sessions.single.exercises.map((e) => e.exerciseName), [
        'Bench Press',
        'Band Pull-Apart',
        'Arm Circles',
      ]);

      // Editing the block afterward must not retroactively change the
      // session that already used it.
      await db.blockDao.updateBlockExercise(
        blockExerciseId: blockDetails.exercises.first.id,
        sets: 99,
        reps: '99',
        weightIntensity: '',
        notes: '',
      );
      final unaffected = (await db.planDao.getPlanDetails(
        newPlanId,
      ))!.sessions.single.exercises.firstWhere(
        (e) => e.exerciseName == 'Band Pull-Apart',
      );
      expect(unaffected.sets, 2);
      expect(unaffected.reps, '15');

      // The original plan (and the block itself) are untouched by the fork.
      final original = (await db.planDao.getPlanDetails('plan-1'))!;
      expect(original.sessions.single.exercises, hasLength(1));
    },
  );
}
