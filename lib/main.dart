import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database_provider.dart';
import 'data/seed/exercise_seed_loader.dart';
import 'home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TrainingApp()));
}

final _startupProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await seedExerciseLibrary(db);
});

class TrainingApp extends StatelessWidget {
  const TrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      scrollBehavior: const _GlowScrollBehavior(),
      home: const _Startup(),
    );
  }
}

// Material 3's default Android overscroll effect visually stretches the
// whole scrollable (including its text) when pulled past its bounds - easy
// to mistake for a layout bug. Use the classic glow indicator instead.
class _GlowScrollBehavior extends MaterialScrollBehavior {
  const _GlowScrollBehavior();

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
