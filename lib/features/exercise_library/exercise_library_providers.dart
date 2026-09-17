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

/// Same shape - opt-in per session, not gated on whether any exercise has
/// ever been favorited.
final exerciseFavoritesOnlyFilterProvider = StateProvider<bool>(
  (ref) => false,
);

/// Every distinct equipment tag mentioned anywhere in the library (see
/// `lib/logic/equipment_matching.dart`), for the onboarding equipment
/// picker and the Settings "Available equipment" editor - derived from the
/// actual seeded/custom data rather than a hand-maintained duplicate list,
/// so a newly added exercise's equipment is pickable without a code change.
/// [bodyweightEquipmentTag] is the one deliberate exception - always added
/// regardless of what the library's own data contains, see its own doc
/// comment for why.
final libraryEquipmentTagsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.exerciseDao.getAllExercises();
  final tags = <String>{bodyweightEquipmentTag};
  for (final e in all) {
    tags.addAll(equipmentTags(e.equipment));
  }
  final sorted = tags.toList()..sort();
  return sorted;
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Reported live: picking one category/area to narrow a long list, then
/// wanting to scroll "legs and back" together, meant either accepting one
/// filter at a time or re-tapping "All" and squinting through everything.
/// Both filter rows are multi-select now (empty set = "All"/no filter) - see
/// `exercise_library_screen.dart`'s `_toggle` helper, which every chip's
/// `onSelected` goes through so tapping an already-selected chip again
/// deselects it instead of requiring a separate tap on "All".
final exerciseCategoryFilterProvider = StateProvider<Set<String>>((ref) => {});
final exerciseCreatorFilterProvider = StateProvider<String?>((ref) => null);

/// Filters by the same [MuscleArea] the library list's own colour stripe
/// already derives per exercise (`areaForExercise`) - not a stored column,
/// so this is applied as a plain Dart filter after the DB query rather than
/// a WHERE clause, matching how [MuscleAreaStripe] itself gets its value.
/// Multi-select, same shape and reasoning as [exerciseCategoryFilterProvider].
final exerciseAreaFilterProvider = StateProvider<Set<MuscleArea>>((ref) => {});

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
  final categories = ref.watch(exerciseCategoryFilterProvider);
  final creator = ref.watch(exerciseCreatorFilterProvider);
  final areas = ref.watch(exerciseAreaFilterProvider);
  // Category filtering moved from `search()`'s SQL WHERE (which only ever
  // supported one exact value) to a plain Dart filter here, matching how
  // area filtering already worked - needed now that either can be a set of
  // several values rather than one.
  var results = await db.exerciseDao.search(query: query, creator: creator);
  if (categories.isNotEmpty) {
    results = results.where((e) => categories.contains(e.category)).toList();
  }
  if (areas.isNotEmpty) {
    results = results
        .where(
          (e) => areas.contains(
            areaForExercise(
              muscleGroups: e.muscleGroups,
              category: e.category,
              movementPattern: e.movementPattern,
            ),
          ),
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
  if (ref.watch(exerciseFavoritesOnlyFilterProvider)) {
    results = results.where((e) => e.isFavorite).toList();
  }
  return results;
});
