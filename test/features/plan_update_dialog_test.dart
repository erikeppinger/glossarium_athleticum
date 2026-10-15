import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/export/plan_export.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';
import 'package:training_app/features/plans/plan_sync_handler.dart';
import 'package:training_app/import/plan_json_import.dart';

import 'fake_notification_service.dart';

// A client who hasn't changed a trainer's plan gets one confirmation for an
// updated version, naming who sent it.
void main() {
  testWidgets('an unchanged plan updates after one confirmation', (
    tester,
  ) async {
    final trainer = AppDatabase.forTesting(NativeDatabase.memory());
    final client = AppDatabase.forTesting(NativeDatabase.memory());
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
            ),
          ],
        ),
      ],
    );
    final v1 = planToJson(
      (await trainer.planDao.getPlanDetails('trainer-plan'))!,
    );
    final localId = await importPlanJson(v1, client);
    final v2 = jsonDecode(jsonEncode(v1)) as Map<String, dynamic>;
    v2['updated_at'] = DateTime.utc(2026, 10, 2).toIso8601String();
    ((((v2['weeks'] as List).first as Map)['sessions'] as List).first
            as Map)['exercises'][0]['reps'] =
        '3';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(client),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => importOrSyncPlanJson(context, ref, v2),
                child: const Text('receive'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('receive'));
    await tester.pumpAndSettle();

    expect(find.text('Update "Nine-Block"?'), findsOneWidget);
    expect(
      find.textContaining('Coach Olaf sent an updated version'),
      findsOneWidget,
    );

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Updated to the new version.'), findsOneWidget);
    final plan = (await client.planDao.getPlanDetails(localId))!;
    expect(plan.sessions.single.exercises.single.reps, '3');
    expect(await client.planDao.getAllPlans(), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await trainer.close();
    await client.close();
  });
}
