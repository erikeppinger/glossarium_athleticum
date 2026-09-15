import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/execution/rest_timer_controller.dart'
    show activeInProgressSessionIdProvider;
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

// Reported live: backgrounding the app mid-workout could lose the entire
// session if Android then killed the process - nothing was ever written to
// the database until "Finish session", so the in-memory-only
// _InProgressSession (see execution_screen.dart) was the sole copy of
// everything logged so far. Split into two tests, each proving one half of
// the fix independently: (1) backgrounding the app autosaves a draft that
// stays invisible to real history, and (2) a session reopened with an
// existing draft (standing in for "the process was already killed and
// relaunched" - a fresh ExecutionScreen instance with no prior in-memory
// state at all) restores its checked-off sets instead of starting blank.
//
// The autosave-on-backgrounding hook itself lives on home_screen.dart's own
// always-mounted app-lifecycle observer, not on ExecutionScreen (see
// autosaveInProgressSessionDraft's doc comment - moved there 2026-09-10 so a
// session left via "Leave" and then backgrounded from a different tab still
// gets autosaved, which it didn't while this lived on ExecutionScreen's own
// observer). This test mirrors just that observer's wiring rather than
// building the real HomeScreen, which pulls in all four tabs simultaneously
// (including PlanListScreen's StreamProvider) and risks the documented
// "Timer still pending" widget-test gotcha for no benefit here.
class _AutosaveObserver extends ConsumerStatefulWidget {
  final Widget child;

  const _AutosaveObserver({required this.child});

  @override
  ConsumerState<_AutosaveObserver> createState() => _AutosaveObserverState();
}

class _AutosaveObserverState extends ConsumerState<_AutosaveObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final sessionId = ref.read(activeInProgressSessionIdProvider);
      if (sessionId != null) {
        unawaited(autosaveInProgressSessionDraft(ref, sessionId));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  Finder loggedSetIndicator() => find.byTooltip('Undo - edit this set again');

  Future<int> seedSession(AppDatabase db) async {
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
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
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
              sets: 1,
              reps: '8',
              weightIntensity: '60kg',
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    return details!.sessions.single.session.id;
  }

  Widget wrap(AppDatabase db, int sessionId) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(
      home: _AutosaveObserver(
        child: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ExecutionScreen(planSessionId: sessionId),
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

  testWidgets(
    'backgrounding the app autosaves a checked-off set as a draft, '
    'invisible to real workout history',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(loggedSetIndicator(), findsOneWidget);

      // Same callback Android sends before killing a backgrounded app.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.pump();

      final draftSets = await db.sessionLogDao.getDraftSets(sessionId);
      expect(
        draftSets,
        hasLength(1),
        reason: 'the checked-off set should have been autosaved as a draft',
      );
      expect(
        await db.sessionLogDao.getWorkoutHistory(),
        isEmpty,
        reason: 'a draft must stay invisible to real workout history',
      );
      expect(
        await db.sessionLogDao.getPeriodSummary(
          start: DateTime(2000),
          end: DateTime(2100),
        ),
        isA<PeriodSummary>().having(
          (p) => p.totalVolume,
          'totalVolume',
          0,
        ),
        reason: 'a draft must not count toward Progress totals either',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'logging a set autosaves it as a draft immediately, with no lifecycle '
    'event at all',
    (tester) async {
      // Reported live (2026-09-10): logging a set, choosing "Leave", then
      // pressing back enough times to fully exit the app could carry the
      // Activity from `paused` straight into `detached` within
      // milliseconds (confirmed via adb/logcat on a real emulator run),
      // tearing down the Flutter engine before the *backgrounding-triggered*
      // autosave (see the test above) had any real chance to finish its own
      // DB round-trip - so the "session in progress" indicator silently
      // never came back on the next cold start, even though nothing else
      // about the workout was lost. Fixed by saving the draft the moment a
      // set is actually logged (`_logSet`), not only when the app happens to
      // background - this test never fires a lifecycle event at all, to
      // prove the draft is already correct independent of that race
      // entirely.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(loggedSetIndicator(), findsOneWidget);

      expect(
        await db.sessionLogDao.getDraftSets(sessionId),
        hasLength(1),
        reason:
            'the draft should already reflect the logged set with no '
            'backgrounding lifecycle event involved at all',
      );

      // Undoing it should re-sync the draft too, not leave a stale entry
      // behind that a later restore could incorrectly bring back.
      await tester.tap(loggedSetIndicator());
      await tester.pumpAndSettle();

      expect(
        await db.sessionLogDao.getDraftSets(sessionId),
        isEmpty,
        reason: 'undoing the set should clear it from the draft too',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'leaving a session (not finishing) and backgrounding the app from '
    'elsewhere still autosaves its checked-off set as a draft',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(loggedSetIndicator(), findsOneWidget);

      // Leave without finishing - the in-memory _InProgressSession survives
      // (see its own doc comment) but ExecutionScreen's own widget/State is
      // popped and disposed, along with whatever used to observe app
      // lifecycle changes directly on it.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // Reported live (2026-09-10): backgrounding the app from here (a
      // different tab, in the real app) used to lose the whole session
      // anyway, since the autosave hook lived on ExecutionScreen's own
      // now-disposed observer rather than somewhere that outlives it.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.pump();

      final draftSets = await db.sessionLogDao.getDraftSets(sessionId);
      expect(
        draftSets,
        hasLength(1),
        reason:
            'a left-but-unfinished session should still be autosaved once '
            "backgrounded, even though its own screen isn't mounted anymore",
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'reopening a session with an existing draft restores its checked-off '
    'sets, and finishing normally afterward still works',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      // Stands in for "the process was killed and relaunched" - a draft
      // already sitting in the database with no ExecutionScreen ever having
      // been built in this test at all, let alone its in-memory state.
      await db.sessionLogDao.saveDraft(
        planSessionId: sessionId,
        loggedAt: DateTime.now(),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(
        loggedSetIndicator(),
        findsOneWidget,
        reason: 'the existing draft should restore the checked-off set',
      );

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(
        await db.sessionLogDao.getWorkoutHistory(),
        hasLength(1),
        reason: 'finishing normally after a restore should still work',
      );
      expect(
        await db.sessionLogDao.getDraftSets(sessionId),
        isEmpty,
        reason: 'the draft should be cleared once a real log exists',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'a manually-added set beyond the plan\'s own prescription also restores '
    'from an existing draft, not just the prescribed sets',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      // seedSession prescribes exactly 1 set for EX_BP - setNumber 2 here
      // stands in for one added manually via "+ Add set" and then checked
      // off before the process was killed. Reported live (2026-09-10):
      // _formsFor only ever creates as many forms as the plan's own
      // prescription, so a drafted set past that count had no form to
      // restore into and simply vanished instead of coming back checked.
      await db.sessionLogDao.saveDraft(
        planSessionId: sessionId,
        loggedAt: DateTime.now(),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 65),
        ],
      );

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(
        loggedSetIndicator(),
        findsNWidgets(2),
        reason:
            'both the prescribed set and the manually-added extra set '
            'should have restored as checked off',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
