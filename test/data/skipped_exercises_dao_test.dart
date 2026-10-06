import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';

void main() {
  late AppDatabase db;
  late int sessionId;

  Future<void> addExercise(String id, String name) {
    return db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: name,
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
  }

  const benchSkip = SkippedExerciseInput(
    exerciseId: 'EX_BP',
    exerciseName: 'Bench Press',
    prescribedSets: 4,
    prescribedReps: '8',
    prescribedWeightIntensity: '60kg',
    prescribedRestSec: 120,
    reason: 'machine_busy',
  );

  /// One finished session that logged a Row set and skipped [skipped].
  Future<void> logSession(
    String id,
    DateTime at, {
    List<SkippedExerciseInput> skipped = const [],
    List<LoggedSetInput> extraSets = const [],
  }) {
    return db.sessionLogDao.createSessionLog(
      id: id,
      planSessionId: sessionId,
      loggedAt: at,
      entries: [
        const LoggedSetInput(exerciseId: 'EX_ROW', setNumber: 1, reps: 8),
        ...extraSets,
      ],
      skipped: skipped,
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await addExercise('EX_BP', 'Bench Press');
    await addExercise('EX_ROW', 'Barbell Row');
    await addExercise('EX_DB', 'Dumbbell Press');
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Upper',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 4,
              reps: '8',
            ),
            PlanExerciseInput(
              order: 2,
              exerciseId: 'EX_ROW',
              exerciseName: 'Barbell Row',
              sets: 3,
              reps: '8',
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    sessionId = details!.sessions.single.session.id;
  });

  tearDown(() => db.close());

  test('a skip is saved with the session and shows in the workout', () async {
    await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

    final workout = await db.sessionLogDao.getCompletedWorkout('log-1');
    final skip = workout!.skipped.single;
    expect(skip.exerciseName, 'Bench Press');
    expect(skip.prescribedSets, 4);
    expect(skip.prescribedWeightIntensity, '60kg');
    expect(skip.reason, 'machine_busy');
  });

  test('a logged substitute is linked back to what it replaced', () async {
    await logSession(
      'log-1',
      DateTime(2026, 9, 1),
      skipped: [
        const SkippedExerciseInput(
          exerciseId: 'EX_BP',
          exerciseName: 'Bench Press',
          prescribedSets: 4,
          prescribedReps: '8',
          replacedByExerciseId: 'EX_DB',
          replacedByExerciseName: 'Dumbbell Press',
        ),
      ],
      extraSets: const [
        LoggedSetInput(exerciseId: 'EX_DB', setNumber: 1, reps: 10),
      ],
    );

    final workout = await db.sessionLogDao.getCompletedWorkout('log-1');
    final substitute = workout!.exercises.singleWhere(
      (e) => e.exerciseId == 'EX_DB',
    );
    expect(substitute.substituteFor, 'Bench Press');
  });

  group('getPendingMakeUps', () {
    test('lists an unreplaced skip', () async {
      await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

      final pending = await db.sessionLogDao.getPendingMakeUps();
      expect(pending.single.skip.exerciseName, 'Bench Press');
      expect(pending.single.skippedAt, DateTime(2026, 9, 1));
    });

    test('leaves out a skip that was replaced', () async {
      await logSession(
        'log-1',
        DateTime(2026, 9, 1),
        skipped: [
          const SkippedExerciseInput(
            exerciseId: 'EX_BP',
            exerciseName: 'Bench Press',
            prescribedSets: 4,
            prescribedReps: '8',
            replacedByExerciseId: 'EX_DB',
            replacedByExerciseName: 'Dumbbell Press',
          ),
        ],
      );

      expect(await db.sessionLogDao.getPendingMakeUps(), isEmpty);
    });

    test('clears once the exercise is logged in a later session', () async {
      await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);
      await logSession(
        'log-2',
        DateTime(2026, 9, 3),
        extraSets: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8),
        ],
      );

      expect(await db.sessionLogDao.getPendingMakeUps(), isEmpty);
    });

    test('an earlier session with that exercise does not clear it', () async {
      await logSession(
        'log-0',
        DateTime(2026, 8, 25),
        extraSets: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8),
        ],
      );
      await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

      expect(await db.sessionLogDao.getPendingMakeUps(), hasLength(1));
    });

    test('a skip of an exercise since deleted from the library is not offered',
        () async {
      await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

      await db.exerciseDao.deleteExerciseKeepingHistory('EX_BP');

      expect(await db.sessionLogDao.getPendingMakeUps(), isEmpty);
    });

    test('queue and dismiss are stored, and dismiss can be undone', () async {
      await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);
      final id = (await db.sessionLogDao.getPendingMakeUps()).single.skip.id;

      await db.sessionLogDao.setMakeUpQueued(id, true);
      final queued = await db.sessionLogDao.getPendingMakeUps();
      expect(queued.single.skip.queuedForNextSession, isTrue);

      await db.sessionLogDao.setMakeUpDismissed(id, true);
      expect(await db.sessionLogDao.getPendingMakeUps(), isEmpty);

      await db.sessionLogDao.setMakeUpDismissed(id, false);
      expect(await db.sessionLogDao.getPendingMakeUps(), hasLength(1));
    });
  });

  test('deleting the workout deletes its skips', () async {
    await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

    await db.sessionLogDao.deleteSessionLog('log-1');

    expect(await db.select(db.skippedExercises).get(), isEmpty);
  });

  test('deleting the plan with its history deletes its skips', () async {
    await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

    await db.planDao.deletePlanAndHistory('plan-1');

    expect(await db.select(db.skippedExercises).get(), isEmpty);
  });

  test('wipeAllData deletes skips', () async {
    await logSession('log-1', DateTime(2026, 9, 1), skipped: [benchSkip]);

    await db.maintenanceDao.wipeAllData();

    expect(await db.select(db.skippedExercises).get(), isEmpty);
  });
}
