import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/exercise_library/exercise_library_screen.dart';
import 'features/plans/plan_list_screen.dart';
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

  static const _screens = [
    ExerciseLibraryScreen(),
    PlanListScreen(),
    CalendarScreen(),
    SettingsScreen(),
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
      body: IndexedStack(index: _index, children: _screens),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
