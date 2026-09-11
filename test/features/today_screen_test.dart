import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/settings/app_preferences.dart';
import 'package:training_app/features/today/today_screen.dart';

void main() {
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

  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      appPreferencesProvider.overrideWith((ref) => AppPreferencesNotifier()),
    ],
    child: const MaterialApp(home: TodayScreen()),
  );

  testWidgets('shows "nothing scheduled" with no sessions and no streak', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('shows the next upcoming session with a Start action', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId = (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.single.session.id;
    final today = DateTime.now();
    await db.planDao.addSessionDate(
      sessionId,
      DateTime(today.year, today.month, today.day),
    );

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.textContaining('Plan A'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
