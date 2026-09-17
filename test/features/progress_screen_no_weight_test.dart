import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/progress/progress_screen.dart';

// Regression coverage: a bodyweight/band/Time-type exercise (e.g. a
// resistance-band warm-up) never logs a weight, so it used to be silently
// excluded from both the exercise dashboard and the period summary entirely
// - it should now appear with reps instead of a weight figure.
void main() {
  testWidgets(
    'a no-weight exercise appears in the dashboard with reps, and '
    'contributes to a "Bodyweight reps" summary card',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // The exercise dashboard sits well down the screen's plain ListView -
      // a ListView's SliverList lazily mounts elements by viewport
      // visibility regardless of whether it's given a static `children:`
      // list, so content far enough below the fold isn't just offstage
      // (which skipOffstage: false below already accounts for), it's not
      // built into the Element tree at all yet. Enlarging the test viewport
      // avoids needing to script a scroll gesture for every interaction -
      // same fix already documented for create_exercise_screen_test.dart.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_BAND',
          name: 'Band Pull-Apart',
          category: 'Warm-up',
          movementPattern: '',
          muscleGroups: 'Back',
          equipment: 'Resistance Band',
          difficulty: 'Beginner',
          measurementType: 'Time',
        ),
      );
      final sessionId = await db.planDao.addSession(
        planId: await db.planDao.createEmptyPlan(name: 'Plan A'),
        weekNumber: 1,
        day: 'Mon',
        sessionName: 'Warm-up',
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime.now(),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BAND', setNumber: 1, reps: 15),
          LoggedSetInput(exerciseId: 'EX_BAND', setNumber: 2, reps: 15),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The exercise dashboard sits below the fold on the default test
      // viewport, so it's scrolled out of view rather than actually missing
      // - skipOffstage: false is the standard way to assert presence without
      // needing to scroll it into view first.
      expect(
        find.text('Band Pull-Apart', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('30 reps', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Bodyweight reps'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
