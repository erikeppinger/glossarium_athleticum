import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/execution/execution_screen.dart'
    show exerciseLookupProvider;
import 'package:training_app/features/plans/plan_providers.dart';
import 'package:training_app/features/plans/plan_sync_handler.dart';

// Regression test (found live, 2026-10-07): importing a plan file creates
// custom exercises, but the cached exercise list the plan-spreadsheet import
// matches against wasn't refreshed - a spreadsheet of the same plan, imported
// right after in the same app session, listed every one of them as
// "unmatched" until the app restarted.
void main() {
  final planJson = <String, dynamic>{
    'schema_version': 2,
    'id': 'nine-block',
    'name': 'Nine-Block',
    'weeks': [
      {
        'week_number': 1,
        'sessions': [
          {
            'day': 'Day 1',
            'session_name': 'Block 1',
            'assigned_dates': <String>[],
            'exercises': [
              {
                'order': 1,
                'exercise_id': null,
                'exercise_name': 'Lu Raise',
                'sets': 5,
                'reps': '5',
              },
            ],
          },
        ],
      },
    ],
  };

  testWidgets('a plan-file import refreshes the cached exercise lists', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => importOrSyncPlanJson(context, ref, planJson),
                child: const Text('import'),
              ),
            ),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.text('import')),
    );

    // Cache both lists before the import, as an earlier screen would have.
    expect(
      await container.read(allExercisesForMatchingProvider.future),
      isEmpty,
    );
    expect(await container.read(exerciseLookupProvider.future), isEmpty);

    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();

    final matching = await container.read(
      allExercisesForMatchingProvider.future,
    );
    expect(matching.map((e) => e.name), ['Lu Raise']);
    final lookup = await container.read(exerciseLookupProvider.future);
    expect(lookup.values.map((e) => e.name), ['Lu Raise']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
