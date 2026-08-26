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
      home: const _Startup(),
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
