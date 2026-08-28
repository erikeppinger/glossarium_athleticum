import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/exercise_library/exercise_library_screen.dart';
import 'features/execution/rest_timer_overlay.dart';
import 'features/notifications/reminder_coordinator.dart';
import 'features/plans/plan_list_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/sharing/incoming_share_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;
  StreamSubscription<List<SharedMediaFile>>? _sharedFilesSub;

  // Settings deliberately isn't one of these - it's a rarely-used
  // destination, so it lives behind a gear action in each tab's app bar
  // (see settingsAppBarAction) rather than taking up a fifth of the
  // bottom bar's width.
  static const _screens = [
    ExerciseLibraryScreen(),
    PlanListScreen(),
    CalendarScreen(),
    ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _sharedFilesSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _onSharedFiles,
    );
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _onSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    });
    // Re-derive pending reminders on every launch: a day has passed since
    // some were scheduled, and a reinstall/restore clears the OS's copy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) resyncReminders(ref);
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
    _sharedFilesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          const RestTimerOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
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
