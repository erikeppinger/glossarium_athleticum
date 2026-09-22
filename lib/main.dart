import 'dart:ui' show AppExitResponse, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database_provider.dart';
import 'data/seed/exercise_seed_loader.dart';
import 'features/execution/rest_timer_controller.dart';
import 'features/execution/rest_timer_overlay.dart';
import 'features/settings/app_preferences.dart';
import 'home_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: TrainingApp()));
}

/// Lets code outside the routed widget tree push/pop routes on the app's
/// real `Navigator` - specifically `rest_timer_overlay.dart`'s `_openSession`
/// (used by both the rest-timer chip's "tap to return" and the resume
/// banner's "tap to resume"). Both live inside `MaterialApp.builder`'s own
/// `Stack`, as a *sibling* of `child` (the actual routed content) rather
/// than a descendant of it - so `Navigator.of(context)` from either widget's
/// own `BuildContext` has no Navigator ancestor to find at all. Reported
/// live (2026-09-10): tapping either one silently did nothing; the crash
/// (`Null check operator used on a null value` inside `Navigator.of`) only
/// showed up in a full `flutter run` log, not the release APK's own
/// (much terser) on-device logcat output.
final navigatorKey = GlobalKey<NavigatorState>();

final _startupProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await ref.read(appPreferencesProvider.notifier).load();
  // Skipped once someone has deliberately deleted the built-in library (see
  // AppPreferences.standardLibraryDismissed's own doc comment) - normally
  // this reseed runs unconditionally on every start specifically so it
  // survives things like a plain data-clear, which would otherwise silently
  // undo that choice the next time the app opens.
  if (!ref.read(appPreferencesProvider).standardLibraryDismissed) {
    await seedExerciseLibrary(db);
  }
  // Restores the "a session is still open" marker after a genuine process
  // kill, without needing the session's own ExecutionScreen to be reopened
  // first (e.g. by tapping a still-live rest-timer notification) - reported
  // live (2026-09-09): a plain cold start from the launcher showed no sign
  // a session was ever in progress, even though its autosaved draft (see
  // home_screen.dart's app-lifecycle observer) was sitting safely in the
  // database the whole time. activeInProgressSessionIdProvider itself is
  // purely in-memory and always starts null on a fresh process, so this is
  // the one place that reconnects it to what the database actually knows -
  // still needed for the lifecycle-triggered autosave in home_screen.dart,
  // even with the dedicated "session in progress" notification/banner
  // removed (2026-09-11 - redundant with the rest timer's own notification
  // whenever both were up at once, and not worth the clutter otherwise).
  final activeDraftSessionId = await db.sessionLogDao
      .getActiveDraftPlanSessionId();
  if (activeDraftSessionId != null) {
    ref.read(activeInProgressSessionIdProvider.notifier).state =
        activeDraftSessionId;
  }
  // Same reasoning as the marker above, for the rest timer's own countdown -
  // see RestTimerController.restoreIfAny's doc comment. Independent of
  // whether a draft was found above: a rest timer surviving without its
  // session's draft (or vice versa) shouldn't be possible in practice, but
  // this doesn't need to assume that to be correct either way.
  await ref.read(restTimerControllerProvider.notifier).restoreIfAny();
});

class TrainingApp extends ConsumerStatefulWidget {
  const TrainingApp({super.key});

  @override
  ConsumerState<TrainingApp> createState() => _TrainingAppState();
}

class _TrainingAppState extends ConsumerState<TrainingApp> {
  // Windows only: nothing sends the OS-level "please exit" request through
  // Flutter's own onExitRequested/AppExitResponse channel on that platform -
  // confirmed by reading the framework's own doc comment on
  // ServicesBinding.handleRequestAppExit ("Currently this is only supported
  // on macOS and Linux"). The native side (windows/runner/flutter_window.cpp)
  // now supplies the missing trigger itself, intercepting WM_CLOSE (the
  // window's own X button, and Alt+F4) and sending the exact same
  // "flutter/platform" / "System.requestAppExit" message the engine would
  // send natively on macOS/Linux - so this listener needs no platform check
  // of its own, it simply never fires on Android (nothing there sends this
  // either, and Android's own back-button/task-kill behavior is unrelated).
  //
  // Reported live (2026-09-11): clicking Windows' native X button while a
  // session had unsaved sets closed the app instantly with no prompt at all,
  // silently discarding them - `PopScope`'s own "Leave without finishing?"
  // guard only ever ran for in-app back-navigation, never for a window-close
  // request, since those are two completely unrelated code paths.
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        final guard = ref.read(executionScreenCloseGuardProvider);
        if (guard == null) return AppExitResponse.exit;
        final canExit = await guard();
        return canExit ? AppExitResponse.exit : AppExitResponse.cancel;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appPreferencesProvider).themeMode;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Training App',
      // Only the Settings > Units & display section is actually migrated to
      // AppLocalizations so far (see CLAUDE.md) - the pipeline stays wired
      // up so that section (and anything migrated later) still works, but
      // the app is pinned to English regardless of device locale for now:
      // with most of the app still unmigrated and the German strings not
      // yet reviewed for quality, a device set to German saw a jarring mix
      // of a few (imperfect) German strings and everything else in English.
      // Remove this once translations are actually ready to ship.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      scrollBehavior: const _GlowScrollBehavior(),
      // Floats the rest-timer/resume-session chip above *every* screen, not
      // just the four bottom-nav tabs - it used to live inside HomeScreen's
      // own build instead, which meant it never appeared on Settings or any
      // other screen reached by pushing a route on top (reported live). See
      // RestTimerOverlay's own doc comment for how it still hides itself
      // while ExecutionScreen specifically is on top.
      builder: (context, child) =>
          Stack(children: [?child, const RestTimerOverlay()]),
      home: const _Startup(),
    );
  }
}

// Material 3's default Android overscroll effect visually stretches the
// whole scrollable (including its text) when pulled past its bounds - easy
// to mistake for a layout bug. Use the classic glow indicator instead.
class _GlowScrollBehavior extends MaterialScrollBehavior {
  const _GlowScrollBehavior();

  // Flutter's default desktop `ScrollBehavior` only allows touch/stylus to
  // drag-scroll, not a plain mouse click-drag - every scrollable in the app
  // would otherwise only respond to the scroll wheel or dragging the
  // scrollbar thumb itself on Windows, which reads as broken to anyone used
  // to click-dragging a list (common on touchpads without a distinct wheel).
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.secondary,
      child: child,
    );
  }
}

class _Startup extends ConsumerWidget {
  const _Startup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(_startupProvider);
    return startup.when(
      data: (_) => const HomeScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Startup failed: $error')),
      ),
    );
  }
}
