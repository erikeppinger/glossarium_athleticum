import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/import/plan_sync.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedLibrary() => db.exerciseDao.upsertExercise(
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

  Future<void> createLocalPlan({
    List<PlanSessionInput>? sessions,
    DateTime? updatedAt,
  }) => db.planDao.createPlan(
    id: 'plan-1',
    name: 'My Plan',
    updatedAt: updatedAt,
    sessions:
        sessions ??
        [
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Push Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_BP',
                exerciseName: 'Bench Press',
                sets: 4,
                reps: '8-10',
              ),
            ],
          ),
        ],
  );

  group('checkPlanSync', () {
    test('is PlanSyncNew when no local plan shares the incoming id', () async {
      await seedLibrary();
      final outcome = await checkPlanSync({
        'schema_version': 1,
        'id': 'plan-never-seen',
        'name': 'x',
        'weeks': [],
      }, db);
      expect(outcome, isA<PlanSyncNew>());
    });

    test('is PlanSyncUpToDate when updated_at matches exactly', () async {
      await seedLibrary();
      final updatedAt = DateTime(2026, 1, 1, 12);
      await createLocalPlan(updatedAt: updatedAt);

      final outcome = await checkPlanSync({
        'schema_version': 1,
        'id': 'plan-1',
        'name': 'My Plan',
        'updated_at': updatedAt.toIso8601String(),
        'weeks': [],
      }, db);
      expect(outcome, isA<PlanSyncUpToDate>());
    });

    test('is PlanSyncConflict when updated_at differs', () async {
      await seedLibrary();
      await createLocalPlan(updatedAt: DateTime(2026, 1, 1, 12));

      final outcome = await checkPlanSync({
        'schema_version': 1,
        'id': 'plan-1',
        'name': 'My Plan',
        'updated_at': DateTime(2026, 1, 2, 9).toIso8601String(),
        'weeks': [],
      }, db);
      expect(outcome, isA<PlanSyncConflict>());
      final conflict = outcome as PlanSyncConflict;
      expect(conflict.local.plan.id, 'plan-1');
    });
  });

  group('findLogsThatWouldBeLost', () {
    test(
      'finds logs for a session absent from the incoming plan, ignores logs for a session present in both',
      () async {
        await seedLibrary();
        await createLocalPlan(
          sessions: [
            const PlanSessionInput(
              weekNumber: 1,
              day: 'Mon',
              sessionName: 'Push Day',
              exercises: [
                PlanExerciseInput(
                  order: 1,
                  exerciseId: 'EX_BP',
                  exerciseName: 'Bench Press',
                  sets: 4,
                  reps: '8-10',
                ),
              ],
            ),
            const PlanSessionInput(
              weekNumber: 1,
              day: 'Wed',
              sessionName: 'Pull Day',
              exercises: [
                PlanExerciseInput(
                  order: 1,
                  exerciseId: 'EX_BP',
                  exerciseName: 'Bench Press',
                  sets: 3,
                  reps: '10',
                ),
              ],
            ),
          ],
        );
        final local = await db.planDao.getPlanDetails('plan-1');
        final pushDaySession = local!.sessions.firstWhere(
          (s) => s.session.sessionName == 'Push Day',
        );
        final pullDaySession = local.sessions.firstWhere(
          (s) => s.session.sessionName == 'Pull Day',
        );
        await db.sessionLogDao.createSessionLog(
          id: 'log-push',
          planSessionId: pushDaySession.session.id,
          loggedAt: DateTime(2026, 1, 1),
          entries: const [
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
          ],
        );
        await db.sessionLogDao.createSessionLog(
          id: 'log-pull',
          planSessionId: pullDaySession.session.id,
          loggedAt: DateTime(2026, 1, 3),
          entries: const [
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 10, weight: 40),
          ],
        );

        // Incoming plan keeps "Push Day" but drops "Pull Day" entirely.
        final incomingJson = {
          'schema_version': 1,
          'id': 'plan-1',
          'name': 'My Plan',
          'updated_at': DateTime(2026, 1, 5).toIso8601String(),
          'weeks': [
            {
              'week_number': 1,
              'sessions': [
                {
                  'day': 'Mon',
                  'session_name': 'Push Day',
                  'exercises': [
                    {
                      'order': 1,
                      'exercise_id': 'EX_BP',
                      'exercise_name': 'Bench Press',
                      'sets': 5,
                      'reps': '5',
                    },
                  ],
                },
              ],
            },
          ],
        };

        final lost = await findLogsThatWouldBeLost(local, incomingJson, db);
        expect(lost, hasLength(1));
        expect(lost.single.log.id, 'log-pull');
      },
    );
  });

  group('applyIncomingPlan', () {
    test(
      'replaces the plan definition and re-links a log whose session survives',
      () async {
        await seedLibrary();
        await createLocalPlan();
        final local = await db.planDao.getPlanDetails('plan-1');
        final pushDaySession = local!.sessions.single;
        await db.sessionLogDao.createSessionLog(
          id: 'log-1',
          planSessionId: pushDaySession.session.id,
          loggedAt: DateTime(2026, 1, 1),
          entries: const [
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
          ],
        );

        final incomingJson = {
          'schema_version': 1,
          'id': 'plan-1',
          'name': 'My Plan (edited elsewhere)',
          'updated_at': DateTime(2026, 1, 5).toIso8601String(),
          'weeks': [
            {
              'week_number': 1,
              'sessions': [
                {
                  'day': 'Mon',
                  'session_name': 'Push Day',
                  'exercises': [
                    {
                      'order': 1,
                      'exercise_id': 'EX_BP',
                      'exercise_name': 'Bench Press',
                      'sets': 5, // changed from 4
                      'reps': '5',
                    },
                  ],
                },
              ],
            },
          ],
        };

        await applyIncomingPlan(incomingJson, db);

        final updated = await db.planDao.getPlanDetails('plan-1');
        expect(updated!.plan.name, 'My Plan (edited elsewhere)');
        expect(updated.sessions.single.exercises.single.sets, 5);

        final logs = await db.sessionLogDao.getLogsForPlanSession(
          updated.sessions.single.session.id,
        );
        expect(logs, hasLength(1));
        expect(logs.single.id, 'log-1');
      },
    );

    test('a re-linked log keeps its notes and skipped exercises', () async {
      await seedLibrary();
      await createLocalPlan();
      final local = await db.planDao.getPlanDetails('plan-1');
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: local!.sessions.single.session.id,
        loggedAt: DateTime(2026, 1, 1),
        notes: 'Gym was packed',
        entries: const [
          LoggedSetInput(
            exerciseId: 'EX_BP',
            setNumber: 1,
            reps: 8,
            notes: 'Shoulder felt off',
          ),
        ],
        skipped: const [
          SkippedExerciseInput(
            exerciseId: 'EX_SQ',
            exerciseName: 'Back Squat',
            prescribedSets: 3,
            prescribedReps: '5',
            reason: 'machine_busy',
          ),
        ],
      );

      await applyIncomingPlan({
        'schema_version': 1,
        'id': 'plan-1',
        'name': 'My Plan',
        'updated_at': DateTime(2026, 1, 5).toIso8601String(),
        'weeks': [
          {
            'week_number': 1,
            'sessions': [
              {
                'day': 'Mon',
                'session_name': 'Push Day',
                'exercises': [
                  {
                    'order': 1,
                    'exercise_id': 'EX_BP',
                    'exercise_name': 'Bench Press',
                    'sets': 5,
                    'reps': '5',
                  },
                ],
              },
            ],
          },
        ],
      }, db);

      final workout = await db.sessionLogDao.getCompletedWorkout('log-1');
      expect(workout!.log.notes, 'Gym was packed');
      expect(
        workout.exercises.single.sets.single.notes,
        'Shoulder felt off',
      );
      expect(workout.skipped.single.exerciseName, 'Back Squat');
      expect(workout.skipped.single.reason, 'machine_busy');
    });

    test('drops a log whose session no longer exists in the incoming plan', () async {
      await seedLibrary();
      await createLocalPlan();
      final local = await db.planDao.getPlanDetails('plan-1');
      final pushDaySession = local!.sessions.single;
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: pushDaySession.session.id,
        loggedAt: DateTime(2026, 1, 1),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      // Incoming plan renames the session entirely - no natural-key match.
      final incomingJson = {
        'schema_version': 1,
        'id': 'plan-1',
        'name': 'My Plan',
        'updated_at': DateTime(2026, 1, 5).toIso8601String(),
        'weeks': [
          {
            'week_number': 1,
            'sessions': [
              {
                'day': 'Tue',
                'session_name': 'Completely Different Session',
                'exercises': [
                  {
                    'order': 1,
                    'exercise_id': 'EX_BP',
                    'exercise_name': 'Bench Press',
                    'sets': 5,
                    'reps': '5',
                  },
                ],
              },
            ],
          },
        ],
      };

      await applyIncomingPlan(incomingJson, db);

      final updated = await db.planDao.getPlanDetails('plan-1');
      final logs = await db.sessionLogDao.getLogsForPlanSession(
        updated!.sessions.single.session.id,
      );
      expect(logs, isEmpty);
    });
  });
}
