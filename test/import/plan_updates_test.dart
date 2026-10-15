import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/export/backup_export.dart';
import 'package:training_app/export/plan_export.dart';
import 'package:training_app/import/backup_import.dart';
import 'package:training_app/import/plan_json_import.dart';
import 'package:training_app/import/plan_sync.dart';
import 'package:training_app/logic/plan_fingerprint.dart';

// A trainer sends a plan; the client imports it (a fresh local id), puts
// sessions on the calendar and trains. The trainer then sends an updated
// version. The trainer owns the contents; the client owns dates and logs.
void main() {
  // The backup restore re-seeds the bundled exercise library.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase trainer;
  late AppDatabase client;

  setUp(() {
    trainer = AppDatabase.forTesting(NativeDatabase.memory());
    client = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await trainer.close();
    await client.close();
  });

  Future<Map<String, dynamic>> trainerPlanV1() async {
    await trainer.planDao.createPlan(
      id: 'trainer-plan',
      name: 'Nine-Block',
      createdBy: 'Coach Olaf',
      updatedAt: DateTime.utc(2026, 10, 1),
      sessions: const [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Day 1',
          sessionName: 'Block 1',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseName: 'Deadlift',
              sets: 5,
              reps: '5',
              supersetGroupId: 1,
            ),
            PlanExerciseInput(
              order: 2,
              exerciseName: 'Face Pull',
              sets: 3,
              reps: '12',
              supersetGroupId: 1,
            ),
          ],
        ),
      ],
    );
    return planToJson((await trainer.planDao.getPlanDetails('trainer-plan'))!);
  }

  /// The trainer's next version: Deadlift reps changed, a day later.
  Map<String, dynamic> nextVersion(Map<String, dynamic> json, {int day = 2}) {
    final copy = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    copy['updated_at'] = DateTime.utc(2026, 10, day).toIso8601String();
    final exercises =
        (((copy['weeks'] as List).first as Map)['sessions'] as List).first
            as Map;
    ((exercises['exercises'] as List).first as Map)['reps'] = '3';
    return copy;
  }

  Future<PlanDetails> importOnClient(Map<String, dynamic> json) async {
    final id = await importPlanJson(json, client);
    return (await client.planDao.getPlanDetails(id))!;
  }

  test('supersets survive export and import', () async {
    final local = await importOnClient(await trainerPlanV1());
    expect(local.sessions.single.exercises.map((e) => e.supersetGroupId), [
      1,
      1,
    ]);
  });

  test('an import remembers where it came from', () async {
    final v1 = await trainerPlanV1();
    final local = await importOnClient(v1);
    expect(local.plan.id, isNot('trainer-plan'));
    expect(local.plan.sourcePlanId, 'trainer-plan');
    expect(
      local.plan.sourceUpdatedAt!.isAtSameMomentAs(DateTime.utc(2026, 10, 1)),
      isTrue,
    );
    expect(
      local.plan.sourceContentHash,
      planContentFingerprint(planToJson(local)),
      reason: 'the fingerprint must match the imported plan as stored here',
    );
  });

  test('the same file again is already up to date, not a duplicate', () async {
    final v1 = await trainerPlanV1();
    await importOnClient(v1);
    expect(await checkPlanSync(v1, client), isA<PlanSyncUpToDate>());
  });

  test(
    'an update replaces the contents and keeps dates, logs and settings',
    () async {
      final v1 = await trainerPlanV1();
      final local = await importOnClient(v1);
      final session = local.sessions.single.session;
      await client.planDao.addSessionDate(session.id, DateTime(2026, 10, 20));
      await client.planDao.archivePlan(local.plan.id);
      await client.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: session.id,
        loggedAt: DateTime(2026, 10, 3),
        entries: [
          LoggedSetInput(
            exerciseId: local.sessions.single.exercises.first.exerciseId!,
            setNumber: 1,
            reps: 5,
            weight: 100,
          ),
        ],
      );

      final v2 = nextVersion(v1);
      final outcome = await checkPlanSync(v2, client);
      expect(outcome, isA<PlanSyncUpdate>());
      expect(
        (outcome as PlanSyncUpdate).editedHere,
        isFalse,
        reason: 'scheduling and training are not edits to the contents',
      );

      await applyPlanUpdate(outcome.local, v2, client);

      final after = (await client.planDao.getPlanDetails(local.plan.id))!;
      final s = after.sessions.single;
      expect(s.exercises.first.reps, '3', reason: 'the new contents');
      expect(s.exercises.map((e) => e.supersetGroupId), [1, 1]);
      expect(s.dates, [DateTime(2026, 10, 20)], reason: 'client date kept');
      expect(after.plan.archivedAt, isNotNull, reason: 'archived stays');
      final logs = await client.sessionLogDao.getLogsForPlanSession(
        s.session.id,
      );
      expect(logs.map((l) => l.id), ['log-1'], reason: 'workout kept');
      expect(await client.planDao.getAllPlans(), hasLength(1));
      expect(await checkPlanSync(v2, client), isA<PlanSyncUpToDate>());
    },
  );

  test('contents changed on the client count as edited', () async {
    final v1 = await trainerPlanV1();
    final local = await importOnClient(v1);
    final exercise = local.sessions.single.exercises.first;
    await client.planDao.updatePlanExercise(
      planExerciseId: exercise.id,
      sets: exercise.sets,
      reps: '6',
      weightIntensity: exercise.weightIntensity,
      restSec: exercise.restSec,
      notes: exercise.notes,
    );

    final v2 = nextVersion(v1);
    final outcome = await checkPlanSync(v2, client) as PlanSyncUpdate;
    expect(outcome.editedHere, isTrue);

    // Keeping their own version: the same file doesn't ask again, but the
    // next version still sees the client's edit.
    await keepLocalOverUpdate(outcome.local, v2, client);
    expect(await checkPlanSync(v2, client), isA<PlanSyncUpToDate>());
    final v3 = nextVersion(v1, day: 3);
    expect(
      (await checkPlanSync(v3, client) as PlanSyncUpdate).editedHere,
      isTrue,
    );
  });

  test('keeping both makes the new copy the one that follows', () async {
    final v1 = await trainerPlanV1();
    final local = await importOnClient(v1);
    final v2 = nextVersion(v1);

    await keepBothAfterUpdate(local, v2, client);

    final plans = await client.planDao.getAllPlans();
    expect(plans, hasLength(2));
    final old = plans.firstWhere((p) => p.id == local.plan.id);
    final copy = plans.firstWhere((p) => p.id != local.plan.id);
    expect(old.sourcePlanId, isNull, reason: 'the old copy is theirs now');
    expect(copy.sourcePlanId, 'trainer-plan');
    expect(await checkPlanSync(v2, client), isA<PlanSyncUpToDate>());
  });

  test('a backup restore keeps where a plan came from', () async {
    final local = await importOnClient(await trainerPlanV1());
    final backup = await buildBackupJson(client);
    await importBackupJson(backup, client);

    final restored = (await client.planDao.getPlanDetails(local.plan.id))!;
    expect(restored.plan.sourcePlanId, 'trainer-plan');
    expect(restored.plan.sourceContentHash, local.plan.sourceContentHash);
    expect(restored.sessions.single.exercises.map((e) => e.supersetGroupId), [
      1,
      1,
    ]);
  });
}
