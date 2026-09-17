import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/onboarding/onboarding_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';

// Reported live: the top-right "Skip" button - meant to exit the whole
// onboarding tour - looked, from the experience-level page, like it should
// only skip *that step*. Renamed to "Skip tour" and given the
// experience-level page its own "Skip this step" (just advances one page,
// same as "Next" without picking a level) so the two are no longer
// conflated.
void main() {
  // _finish() (both "Skip tour" and the final "Get started") awaits
  // AppPreferencesNotifier.setHasSeenOnboarding, which touches
  // shared_preferences - without a mock, that call has nothing to respond
  // to and the test hangs until the runner's timeout instead of failing
  // fast (see app_preferences_test.dart for the same setUp).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // OnboardingScreen calls Navigator.of(context).pop() to close itself (see
  // _finish()) - matches how home_screen.dart actually opens it (pushed via
  // Navigator.push), so pop() has a real underlying route to reveal. Pumping
  // it directly as MaterialApp.home would make pop() a no-op on the only
  // route in the stack.
  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
                child: const Text('start'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    '"Skip this step" on the experience-level page advances to the next page, not out of onboarding',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      // Advance from the static tour pages to the experience-level page.
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('How experienced are you?'), findsOneWidget);

      await tester.tap(find.text('Skip this step'));
      await tester.pumpAndSettle();

      expect(
        find.text('How experienced are you?'),
        findsNothing,
        reason: 'moved on to the next (equipment) page',
      );
      expect(
        find.text('What equipment do you have?'),
        findsOneWidget,
        reason: 'skipping a single step must not exit onboarding entirely',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('"Skip tour" exits onboarding entirely from any page', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('start'), findsOneWidget, reason: 'back underneath');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'skipping via either path still leaves the default experience level in place',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final notifier = AppPreferencesNotifier();
      await notifier.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      ),
                      child: const Text('start'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();

      expect(notifier.state.experienceLevel, ExperienceLevel.intermediate);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'the equipment page offers a "Bodyweight" chip, selectable like any '
    'other equipment tag (regression: bodyweight-only training had no real '
    'option to select, only an implicit "leave everything blank")',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // A library with only equipment-requiring exercises - "Bodyweight"
      // must still appear as a synthetic choice, not one scraped from data.
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_BARBELL',
          name: 'Back Squat',
          category: 'Main Lift',
          movementPattern: 'Squat',
          muscleGroups: 'Legs',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
        ),
      );
      final notifier = AppPreferencesNotifier();
      await notifier.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      ),
                      child: const Text('start'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('What equipment do you have?'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);

      await tester.tap(find.text('Bodyweight'));
      await tester.pumpAndSettle();

      expect(notifier.state.availableEquipment, {'Bodyweight'});

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
