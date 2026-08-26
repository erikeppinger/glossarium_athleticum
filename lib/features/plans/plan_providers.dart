import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';

final plansListProvider = StreamProvider<List<Plan>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.watchAllPlans();
});

final allExercisesForMatchingProvider = FutureProvider<List<Exercise>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.exerciseDao.getAllExercises();
});
