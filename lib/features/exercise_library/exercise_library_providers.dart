import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../logic/equipment_matching.dart';
import '../../logic/muscle_group_colors.dart';
import '../settings/app_preferences.dart';

/// Whether the "My equipment" filter is currently applied - opt-in per
/// session, same shape as [exerciseAreaFilterProvider], not gated on
/// whether `AppPreferences.availableEquipment` has ever been set.
final exerciseEquipmentFilterEnabledProvider = StateProvider<bool>(
  (ref) => false,
);

/// Every distinct equipment tag mentioned anywhere in the library (see
/// `lib/logic/equipment_matching.dart`), for the onboarding equipment
/// picker and the Settings "Available equipment" editor - derived from the
/// actual seeded/custom data rather than a hand-maintained duplicate list,
/// so a newly added exercise's equipment is pickable without a code change.
final libraryEquipmentTagsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.exerciseDao.getAllExercises();
  final tags = <String>{};
  for (final e in all) {
    tags.addAll(equipmentTags(e.equipment));
  }
  final sorted = tags.toList()..sort();
  return sorted;
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final exerciseCategoryFilterProvider = StateProvider<String?>((ref) => null);
final exerciseCreatorFilterProvider = StateProvider<String?>((ref) => null);

/// Filters by the same [MuscleArea] the library list's own colour stripe
/// already derives per exercise (`areaForExercise`) - not a stored column,
/// so this is applied as a plain Dart filter after the DB query rather than
/// a WHERE clause, matching how [MuscleAreaStripe] itself gets its value.
final exerciseAreaFilterProvider = StateProvider<MuscleArea?>((ref) => null);

final exerciseCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.exerciseDao.getAllExercises();
  final categories = all.map((e) => e.category).toSet().toList()..sort();
  return categories;
});

/// Every `plan:<name>`/`author:<name>` value currently in the library, for
/// the creator filter row - "Own" is always offered and isn't in this list.
final creatorFilterOptionsProvider = FutureProvider<List<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.exerciseDao.getCreatorFilterOptions();
});

final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final category = ref.watch(exerciseCategoryFilterProvider);
  final creator = ref.watch(exerciseCreatorFilterProvider);
  final area = ref.watch(exerciseAreaFilterProvider);
  var results = await db.exerciseDao.search(
    query: query,
    category: category,
    creator: creator,
  );
  if (area != null) {
    results = results
        .where(
          (e) =>
              areaForExercise(
                muscleGroups: e.muscleGroups,
                category: e.category,
                movementPattern: e.movementPattern,
              ) ==
              area,
        )
        .toList();
  }
  final equipmentFilterEnabled = ref.watch(
    exerciseEquipmentFilterEnabledProvider,
  );
  if (equipmentFilterEnabled) {
    final owned = ref.watch(appPreferencesProvider).availableEquipment;
    results = results
        .where((e) => isDoableWithEquipment(e.equipment, owned))
        .toList();
  }
  return results;
});
