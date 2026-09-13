import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/exercise_library/exercise_library_screen.dart';
import 'features/execution/execution_screen.dart';
import 'features/execution/rest_timer_controller.dart';
import 'features/notifications/notification_service.dart' show restTimerSkipActionId;
import 'features/notifications/reminder_coordinator.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/whats_new_content.dart';
import 'features/onboarding/whats_new_screen.dart';
import 'features/plans/plan_list_screen.dart';
import 'features/settings/app_preferences.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/sharing/incoming_share_handler.dart';
import 'features/today/today_screen.dart';
import 'logic/reminder_payload.dart';

/// Which bottom-nav tab is showing - a provider (not just `HomeScreen`'s own
/// local state) so a screen nested inside one tab (e.g. `TodayScreen`'s
/// "This week" card) can switch to a different tab without needing a
/// callback threaded all the way down from `HomeScreen` itself.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  StreamSubscription<List<SharedMediaFile>>? _sharedFilesSub;
  StreamSubscription<String>? _notificationTapSub;
  StreamSubscription<String>? _notificationActionSub;

  // Settings deliberately isn't one of these - it's a rarely-used
  // destination, so it lives behind a gear action in each tab's app bar
  // (see settingsAppBarAction) rather than taking up a slot of the
  // bottom bar's width.
  //
  // Today is the app's default landing screen (index 0) rather than
  // Exercise Library - "what do I do right now" is a more useful first
  // thing to see than a browsable list. Every other index shifted down
  // one when this was added (2026-09-10) - see _handleNotificationPayload
  // below, which hardcodes the Progress tab's index and had to move with it.
  static const _screens = [
    TodayScreen(),
    ExerciseLibraryScreen(),
    PlanListScreen(),
    CalendarScreen(),
    ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // receive_sharing_intent only has an Android/iOS implementation - calling
    // it on desktop (Windows) would hit a MissingPluginException, since no
    // platform channel handler is registered there at all.
    if (Platform.isAndroid || Platform.isIOS) {
      _sharedFilesSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _onSharedFiles,
      );
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _onSharedFiles(files);
        ReceiveSharingIntent.instance.reset();
      });
    }
    final notificationService = ref.read(notificationServiceProvider);
    _notificationTapSub = notificationService.onNotificationTap.listen(
      _handleNotificationPayload,
    );
    // The rest timer's "Skip" notification action - fires without opening
    // the app, so this is the only place that ever sees it. Reuses the same
    // skip() the in-app Skip button/banner call, so both paths stay in sync.
    _notificationActionSub = notificationService.onNotificationAction.listen((
      actionId,
    ) {
      if (actionId == restTimerSkipActionId) {
        ref.read(restTimerControllerProvider.notifier).skip();
      }
    });
    // A tap that launched the app cold never reaches onNotificationTap above
    // (that only fires while the plugin/app process is already alive) - see
    // NotificationService.consumeLaunchPayload.
    notificationService.consumeLaunchPayload().then((payload) {
      if (payload != null) _handleNotificationPayload(payload);
    });
    // Re-derive pending reminders on every launch: a day has passed since
    // some were scheduled, and a reinstall/restore clears the OS's copy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      resyncReminders(ref);
      final prefs = ref.read(appPreferencesProvider);
      if (!prefs.hasSeenOnboarding) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const OnboardingScreen(),
          ),
        );
      } else if (prefs.lastSeenWhatsNewRevision < currentWhatsNewRevision) {
        // Deliberately `else if`, not a second independent check - a
        // brand-new install's own onboarding tour already covers everything
        // currently in whatsNewItems, and its own _finish() stamps this
        // revision immediately for exactly that reason, so this branch is
        // only ever reached by an *existing* device that's been updated to
        // a build with new entries.
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const WhatsNewScreen(),
          ),
        );
      }
    });
  }

  void _handleNotificationPayload(String raw) {
    final payload = parseReminderPayload(raw);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (payload) {
        case WorkoutReminderPayload(:final planSessionId):
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ExecutionScreen(planSessionId: planSessionId),
            ),
          );
        case WeeklyDigestPayload():
        case PlanReportPayload():
          // Progress moved from index 3 to 4 when the Today tab was
          // inserted at index 0 (2026-09-10) - update this if the tab
          // order ever changes again.
          ref.read(homeTabIndexProvider.notifier).state = 4;
        case null:
          break;
      }
    });
  }

  void _onSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    // A plan/backup share is always a single file; ignore any extras.
    final path = files.first.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      handleSharedFile(context, ref, path);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sharedFilesSub?.cancel();
    _notificationTapSub?.cancel();
    _notificationActionSub?.cancel();
    super.dispose();
  }

  // Reported live (2026-09-09): leaving an in-progress session via "Leave"
  // (switching to a different tab, the session's own screen popped but its
  // in-memory state deliberately kept alive - see execution_screen.dart's
  // _InProgressSession doc comment) and then backgrounding/killing the app
  // from there lost all progress anyway, even though the exact same scenario
  // while ExecutionScreen was still the visible screen was already fixed.
  // That earlier fix put the autosave-on-backgrounding hook on
  // ExecutionScreen's own WidgetsBindingObserver, which stops receiving
  // lifecycle callbacks the instant that screen's route is popped - so a
  // session left and then killed from elsewhere was never actually
  // autosaved. Centralizing the hook here instead - HomeScreen is mounted
  // for the entire life of the app - means the safety net follows whichever
  // session activeInProgressSessionIdProvider currently points to,
  // regardless of whether that session's own screen happens to still be on
  // screen, still be pushed-but-hidden, or already popped.
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
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabIndexProvider);
    return Scaffold(
      // RestTimerOverlay now floats above the whole app instead (see
      // main.dart's MaterialApp.builder), so it isn't hidden on every
      // screen reached by pushing a route on top of this one.
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

/// The gear that opens Settings, shown in every top-level tab's app bar.
/// Settings is a rarely-visited destination, so it doesn't earn a slot in
/// the bottom navigation bar alongside the four everyday tabs.
Widget settingsAppBarAction(BuildContext context) => IconButton(
  icon: const Icon(Icons.settings),
  tooltip: 'Settings',
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const SettingsScreen()),
  ),
);
