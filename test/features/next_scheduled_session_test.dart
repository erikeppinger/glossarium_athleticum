import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/today/today_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  const pushDay = PlanSessionInput(
    weekNumber: 1,
    day: 'Mon',
    sessionName: 'Push Day',
    exercises: [
      PlanExerciseInput(
        order: 1,
        exerciseName: 'Bench Press',
        sets: 1,
        reps: '8',
      ),
    ],
  );

  test('is null when nothing is scheduled', () async {
    expect(await container.read(nextScheduledSessionProvider.future), isNull);
  });

  test('finds the earliest upcoming, not-yet-logged occurrence', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId = (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.single.session.id;

    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final nextWeek = DateTime(today.year, today.month, today.day + 7);
    await db.planDao.addSessionDate(sessionId, nextWeek);
    await db.planDao.addSessionDate(sessionId, tomorrow);

    final next = await container.read(nextScheduledSessionProvider.future);
    expect(next, isNotNull);
    expect(next!.date, tomorrow);
  });

  test('skips an occurrence already logged on its own scheduled day', () async {
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_BP',
        name: 'Bench Press',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId = (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.single.session.id;

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final nextWeek = DateTime(today.year, today.month, today.day + 7);
    await db.planDao.addSessionDate(sessionId, todayDay);
    await db.planDao.addSessionDate(sessionId, nextWeek);

    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: todayDay,
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8),
      ],
    );

    final next = await container.read(nextScheduledSessionProvider.future);
    expect(next, isNotNull);
    expect(next!.date, nextWeek);
  });
}
