import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/export/backup_export.dart';
import 'package:training_app/features/plans/plan_import_screen.dart';
import 'package:training_app/features/sharing/incoming_share_handler.dart';

// Exercises handleSharedContent (the routing logic) directly with in-memory
// strings, not handleSharedFile. Real dart:io file reads reliably hang when
// they happen after pumpWidget in a testWidgets test on this machine - a
// Windows/flutter_test environment interaction, not a product bug (see
// CLAUDE.md's Windows-only flakiness notes). Splitting file I/O from
// content-routing (mirroring the project's lib/logic/ pure-function
// convention) sidesteps that entirely while still covering all the real
// decision logic; handleSharedFile's one-line read is exercised manually
// on the emulator instead.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
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
  });

  tearDown(() => db.close());

  Future<void> pumpTrigger(
    WidgetTester tester, {
    required String extension,
    required String suggestedPlanName,
    required String displayName,
    required String content,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => handleSharedContent(
                  context,
                  ref,
                  extension: extension,
                  suggestedPlanName: suggestedPlanName,
                  displayName: displayName,
                  content: content,
                ),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
  }

  testWidgets('a shared .csv file opens the spreadsheet import screen', (
    tester,
  ) async {
    await pumpTrigger(
      tester,
      extension: '.csv',
      suggestedPlanName: 'received_plan',
      displayName: 'received_plan.csv',
      content:
          'Week,Day,Session Name,Order,Exercise Name,Sets,Reps,Weight/Intensity,Rest (sec),Notes,Video URL\n'
          '1,Mon,Push Day,1,Bench Press,4,8-10,60kg,90,,\n',
    );

    expect(find.byType(PlanImportScreen), findsOneWidget);
    // Filename (minus extension) is offered as the suggested plan name.
    expect(find.text('received_plan'), findsOneWidget);
  });

  testWidgets('a shared .json plan file imports directly into the database', (
    tester,
  ) async {
    await pumpTrigger(
      tester,
      extension: '.json',
      suggestedPlanName: 'received_plan',
      displayName: 'received_plan.json',
      content: '''
{
  "schema_version": 1,
  "id": "plan-1",
  "name": "Shared Plan",
  "weeks": [
    {
      "week_number": 1,
      "sessions": [
        {
          "day": "Mon",
          "session_name": "Push Day",
          "exercises": [
            {
              "order": 1,
              "exercise_id": "EX_BP",
              "exercise_name": "Bench Press",
              "sets": 4,
              "reps": "8-10"
            }
          ]
        }
      ]
    }
  ]
}
''',
    );

    expect(find.text('Plan imported.'), findsOneWidget);
    final plans = await db.planDao.getAllPlans();
    expect(plans.map((p) => p.name), contains('Shared Plan'));
  });

  testWidgets(
    'a malformed shared .json file fails cleanly instead of crashing',
    (tester) async {
      await pumpTrigger(
        tester,
        extension: '.json',
        suggestedPlanName: 'broken',
        displayName: 'broken.json',
        content: '{not valid json',
      );

      expect(find.text('Could not read this plan file.'), findsOneWidget);
    },
  );

  testWidgets(
    'a shared .$backupFileExtension file asks for confirmation before restoring',
    (tester) async {
      await pumpTrigger(
        tester,
        extension: '.$backupFileExtension',
        suggestedPlanName: 'backup',
        displayName: 'backup.$backupFileExtension',
        content: 'irrelevant - dialog appears before reading',
      );

      // The destructive-restore confirmation must appear before anything is
      // decrypted or imported - this is a full-device wipe-and-restore.
      expect(find.text('Restore from backup?'), findsOneWidget);

      // Dismiss the dialog so handleSharedContent's pending Future resolves
      // instead of being left suspended when the test ends.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('an unrecognized file type shows a friendly message', (
    tester,
  ) async {
    await pumpTrigger(
      tester,
      extension: '.png',
      suggestedPlanName: 'photo',
      displayName: 'photo.png',
      content: 'not actually a plan file',
    );

    expect(
      find.text("Training App doesn't recognize photo.png."),
      findsOneWidget,
    );
  });
}
