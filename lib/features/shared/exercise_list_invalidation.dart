import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../execution/execution_screen.dart' show exerciseLookupProvider;
import '../exercise_library/exercise_library_providers.dart';
import '../plans/plan_providers.dart' show allExercisesForMatchingProvider;

/// Refreshes every cached copy of the exercise library. They're one-shot
/// FutureProviders that never notice a database write on their own, so any
/// code that adds, edits or deletes exercises must call this - otherwise,
/// for example, a plan-spreadsheet import keeps matching against the list
/// from before a plan-file import until the app restarts.
void invalidateExerciseListProviders(WidgetRef ref) {
  ref.invalidate(filteredExercisesProvider);
  ref.invalidate(exerciseCategoriesProvider);
  ref.invalidate(creatorFilterOptionsProvider);
  ref.invalidate(libraryEquipmentTagsProvider);
  ref.invalidate(allExercisesForMatchingProvider);
  ref.invalidate(exerciseLookupProvider);
}
