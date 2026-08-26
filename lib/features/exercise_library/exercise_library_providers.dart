import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final exerciseCategoryFilterProvider = StateProvider<String?>((ref) => null);

final exerciseCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.exerciseDao.getAllExercises();
  final categories = all.map((e) => e.category).toSet().toList()..sort();
  return categories;
});

final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final category = ref.watch(exerciseCategoryFilterProvider);
  return db.exerciseDao.search(query: query, category: category);
});
