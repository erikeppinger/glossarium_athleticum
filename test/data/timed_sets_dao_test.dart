import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/logic/set_measure.dart';

void main() {
  late AppDatabase db;
  late int sessionId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    for (final (id, name, type) in [
      ('EX_PL', 'Plank', 'Time'),
      ('EX_FC', "Farmer's Carry", 'Distance or Time'),
    ]) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: name,
          category: 'Core',
          movementPattern: '',
          muscleGroups: 'Core',
          equipment: 'None (Bodyweight)',
          difficulty: 'Beginner',
          measurementType: type,
        ),
      );
    }
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Core',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_PL',
              exerciseName: 'Plank',
              sets: 3,
              reps: '1',
              weightIntensity: '45 sec',
            ),
          ],
        ),
      ],
    );
    sessionId = (await db.planDao.getPlanDetails('plan-1'))!
        .sessions
        .single
        .session
        .id;
  });

  tearDown(() => db.close());

  Future<void> log(String id, DateTime at, List<LoggedSetInput> sets) {
    return db.sessionLogDao.createSessionLog(
      id: id,
      planSessionId: sessionId,
      loggedAt: at,
      entries: sets,
    );
  }

  test('a hold shows on the dashboard as its longest time', () async {
    await log('log-1', DateTime(2026, 10, 1), const [
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 45),
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 2, durationSec: 60),
    ]);

    final summary = (await db.sessionLogDao.getLatestTopSetPerExercise())
        .single;
    expect(summary.exerciseId, 'EX_PL');
    expect(summary.topDurationSec, 60);
    expect(summary.topDistance, isNull);
    expect(summary.topWeight, isNull);
  });

  test('a loaded carry shows its furthest set and that set\'s load', () async {
    await log('log-1', DateTime(2026, 10, 1), const [
      LoggedSetInput(
        exerciseId: 'EX_FC',
        setNumber: 1,
        distance: 40,
        weight: 50,
      ),
      LoggedSetInput(
        exerciseId: 'EX_FC',
        setNumber: 2,
        distance: 50,
        weight: 60,
      ),
    ]);

    final summary = (await db.sessionLogDao.getLatestTopSetPerExercise())
        .single;
    expect(summary.topDistance, 50);
    expect(summary.topWeight, 60);
  });

  test('getMeasuredHistory reduces each session to best and total', () async {
    await log('log-1', DateTime(2026, 10, 1), const [
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 45),
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 2, durationSec: 30),
    ]);
    await log('log-2', DateTime(2026, 10, 3), const [
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 60),
    ]);

    final history = await db.sessionLogDao.getMeasuredHistory('EX_PL');
    expect(history!.measure, SetMeasure.time);
    expect(history.entries.map((e) => e.best), [45, 60]);
    expect(history.entries.first.total, 75);
    expect(history.entries.first.setCount, 2);
  });

  test('getMeasuredHistory is null for an exercise with no times or distances',
      () async {
    await log('log-1', DateTime(2026, 10, 1), const [
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, reps: 1),
    ]);
    expect(await db.sessionLogDao.getMeasuredHistory('EX_PL'), isNull);
  });

  test('updateLoggedSet can correct a hold\'s time', () async {
    await log('log-1', DateTime(2026, 10, 1), const [
      LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 45),
    ]);
    final set = (await db.sessionLogDao.getLoggedSetsForSessionLog('log-1'))
        .single;

    await db.sessionLogDao.updateLoggedSet(id: set.id, durationSec: 50);

    final updated = (await db.sessionLogDao.getLoggedSetsForSessionLog(
      'log-1',
    )).single;
    expect(updated.durationSec, 50);
    expect(updated.reps, isNull);
  });
}
