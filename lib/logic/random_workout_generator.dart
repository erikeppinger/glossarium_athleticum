import 'dart:math';

import '../data/app_database.dart' show Exercise;
import '../data/daos/exercise_dao.dart' show ownExercisesFilter;
import 'equipment_matching.dart';
import 'muscle_group_colors.dart';

/// Sentinel for [WorkoutBucketSpec.source]/[generateRandomWorkout]'s source
/// filter: the seed/built-in library only (`!isCustom`) - the one grouping
/// `ExerciseDao.search`'s own `creator` filter has no value for, since
/// every one of its existing sentinels is about *custom* exercises.
const seedLibraryFilter = '__seed__';

/// One row of the generator: "N exercises from [category]/[areas]". Both
/// filters are optional and independent - set neither for "any category, any
/// muscle area" (rare, would just grab N random exercises), set one or both
/// to narrow it. [label] is purely for display (the four defaults are named
/// after what the user actually asked for - Warm-up/Legs/Upper Body/Core -
/// but a custom bucket can be labelled anything).
class WorkoutBucketSpec {
  final String label;
  final int count;
  final String? category;
  final Set<MuscleArea> areas;

  const WorkoutBucketSpec({
    required this.label,
    required this.count,
    this.category,
    this.areas = const {},
  });

  WorkoutBucketSpec withCount(int newCount) => WorkoutBucketSpec(
    label: label,
    count: newCount,
    category: category,
    areas: areas,
  );
}

/// One bucket's actual result - [exercises] may be shorter than
/// [WorkoutBucketSpec.count] if the filtered library simply doesn't have
/// enough matches (or enough *unused* ones - see [generateRandomWorkout]'s
/// own note on cross-bucket deduplication). Never padded or substituted with
/// a near-miss; a shortfall is reported, not silently hidden.
class GeneratedBucket {
  final WorkoutBucketSpec spec;
  final List<Exercise> exercises;

  const GeneratedBucket({required this.spec, required this.exercises});

  int get shortfall => spec.count - exercises.length;
}

class GeneratedWorkout {
  final List<GeneratedBucket> buckets;

  const GeneratedWorkout({required this.buckets});

  List<Exercise> get allExercises => [
    for (final b in buckets) ...b.exercises,
  ];

  bool get hasAnyShortfall => buckets.any((b) => b.shortfall > 0);
}

/// True when [exercise] belongs to the library grouping named by [source] -
/// the same "which library" buckets `exercise_library_screen.dart`'s own
/// creator filter row already uses ([ownExercisesFilter], `plan:<name>`,
/// `author:<name>`), plus [seedLibraryFilter] for "built-in only". `null`
/// means no source filter at all.
bool matchesSource(Exercise exercise, String? source) {
  if (source == null) return true;
  if (source == seedLibraryFilter) return !exercise.isCustom;
  if (source == ownExercisesFilter) {
    return exercise.isCustom &&
        exercise.sourcePlanName == null &&
        exercise.author == null;
  }
  if (source.startsWith('plan:')) {
    return exercise.sourcePlanName == source.substring('plan:'.length);
  }
  if (source.startsWith('author:')) {
    return exercise.author == source.substring('author:'.length);
  }
  return true;
}

/// Picks [WorkoutBucketSpec.count] random exercises per bucket out of
/// [library], applying each bucket's own category/muscle-area filters (an
/// exercise's area comes from [areaForExercise], the same heuristic the
/// Exercise Library's own area filter and colour stripe already use - not a
/// stored column) plus the shared [equipmentOwned]/[source] filters that
/// apply to every bucket alike.
///
/// The same exercise is never picked twice *across* buckets, even if it
/// would match more than one bucket's filters (e.g. a "Legs" bucket and a
/// broader "any area" bucket both matching a squat variation) - buckets are
/// filled in the order given, so an earlier bucket's picks are unavailable
/// to a later one. [random] is injectable so this is deterministic in tests;
/// real callers can just omit it.
GeneratedWorkout generateRandomWorkout({
  required List<Exercise> library,
  required List<WorkoutBucketSpec> buckets,
  Set<String> equipmentOwned = const {},
  bool requireOwnedEquipment = false,
  String? source,
  Random? random,
}) {
  final rng = random ?? Random();
  final used = <String>{};

  final baseline = library.where((e) {
    if (!matchesSource(e, source)) return false;
    if (requireOwnedEquipment &&
        !isDoableWithEquipment(e.equipment, equipmentOwned)) {
      return false;
    }
    return true;
  }).toList();

  final result = <GeneratedBucket>[];
  for (final spec in buckets) {
    var candidates = baseline.where((e) => !used.contains(e.id)).toList();
    if (spec.category != null) {
      candidates = candidates.where((e) => e.category == spec.category).toList();
    }
    if (spec.areas.isNotEmpty) {
      candidates = candidates
          .where(
            (e) => spec.areas.contains(
              areaForExercise(
                muscleGroups: e.muscleGroups,
                category: e.category,
                movementPattern: e.movementPattern,
              ),
            ),
          )
          .toList();
    }
    candidates.shuffle(rng);
    final picked = candidates.take(spec.count).toList();
    used.addAll(picked.map((e) => e.id));
    result.add(GeneratedBucket(spec: spec, exercises: picked));
  }
  return GeneratedWorkout(buckets: result);
}
