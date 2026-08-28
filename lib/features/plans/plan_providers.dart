import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';

/// Active plans only - archived ones are surfaced separately by
/// [archivedPlansProvider] so they stay out of the way without being lost.
final plansListProvider = StreamProvider<List<Plan>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.watchActivePlans();
});

final archivedPlansProvider = StreamProvider<List<Plan>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.watchArchivedPlans();
});

final allExercisesForMatchingProvider = FutureProvider<List<Exercise>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.exerciseDao.getAllExercises();
});

/// One-shot per plan id - anything that rewrites a plan's data under an
/// *existing* id (Phase 5's sync conflict resolution, via
/// lib/import/plan_sync.dart's applyIncomingPlan) must `ref.invalidate` this
/// afterward, or the plan detail screen keeps showing what it looked like
/// before the sync. Same class of gotcha as filteredExercisesProvider/
/// exerciseCategoriesProvider, documented in CLAUDE.md.
final planDetailsProvider = FutureProvider.family<PlanDetails?, String>((
  ref,
  planId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.planDao.getPlanDetails(planId);
});
