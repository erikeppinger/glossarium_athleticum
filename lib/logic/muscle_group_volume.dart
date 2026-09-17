/// Pure logic for "sets per muscle group per week" (2026-09-18 addition,
/// prompted by a new ACSM overview of reviews - see
/// [muscleGroupVolumeScienceNote]). Deliberately DB/Flutter-free, matching
/// this project's `lib/logic/` convention.
library;

/// Splits a free-text `Exercises.muscleGroups` value into its individual
/// named groups. The seed library joins multiple groups with "&" (e.g.
/// "Shoulders & Upper Back" - see seed-data/strongman_exercise_database.csv),
/// while `create_exercise_screen.dart`'s own hint text tells a user typing a
/// custom exercise to use commas instead ("Chest, Triceps"). Splitting on
/// both means a muscle-group tally isn't silently wrong for whichever half
/// of the library happens to use the convention this parser didn't expect.
/// A `Set` dedupes an accidental repeat (e.g. "Shoulders & Shoulders").
List<String> parseMuscleGroups(String raw) {
  return raw
      .split(RegExp(r'[,&]'))
      .map((g) => g.trim())
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList();
}

/// One muscle group's tallied set count for a period.
class MuscleGroupVolume {
  final String muscleGroup;
  final int setCount;

  const MuscleGroupVolume({required this.muscleGroup, required this.setCount});
}

/// Tallies logged sets per muscle group from a flat list of (an exercise's
/// raw `muscleGroups` text, how many sets were logged for it in the period).
/// A compound exercise's sets count toward *every* muscle group it lists -
/// e.g. a bench press set counts for both "Chest" and "Triceps" - matching
/// how real training-volume accounting treats a compound lift touching more
/// than one muscle group, not a bug. Sorted highest-volume first.
List<MuscleGroupVolume> tallyMuscleGroupVolume(
  Iterable<({String muscleGroupsRaw, int setsLogged})> entries,
) {
  final totals = <String, int>{};
  for (final entry in entries) {
    for (final group in parseMuscleGroups(entry.muscleGroupsRaw)) {
      totals[group] = (totals[group] ?? 0) + entry.setsLogged;
    }
  }
  final result = [
    for (final e in totals.entries)
      MuscleGroupVolume(muscleGroup: e.key, setCount: e.value),
  ]..sort((a, b) => b.setCount.compareTo(a.setCount));
  return result;
}

/// The set-count range a 2026 ACSM overview of reviews ties to enhanced
/// hypertrophy - see [muscleGroupVolumeScienceNote]. Used only to colour/
/// label a muscle group's row (e.g. "below the general guideline"), never to
/// gate or hide anything - a muscle group under 10 sets/week is still shown,
/// just not flagged as in the cited range yet.
const recommendedWeeklySetsMin = 10;
const recommendedWeeklySetsPlateau = 20;

/// Shown behind an info icon next to the Progress tab's "This week's sets by
/// muscle group" card, matching this project's convention of citing the
/// actual source behind any training-science number (see
/// `progression.dart`'s `progressionScienceNote`).
const muscleGroupVolumeScienceNote =
    'Weekly training volume - the number of sets a muscle group gets across '
    'a week, not how it\'s split across sessions - is one of the more '
    'consistent drivers of muscle growth in the research.\n\n'
    'A 2026 American College of Sports Medicine overview of reviews '
    '(Currier et al., "Resistance Training Prescription for Muscle '
    'Function, Hypertrophy, and Physical Performance in Healthy Adults," '
    'Medicine & Science in Sports & Exercise 58(4)) found hypertrophy '
    'enhanced by at least 10 sets per muscle group per week, with benefits '
    'continuing up to roughly 18-20 sets/week before returns level off. '
    'Training frequency - how many separate sessions that volume is spread '
    'across - mattered far less once weekly volume was accounted for.\n\n'
    'A set counts toward every muscle group its exercise lists, so a '
    'compound lift like a bench press adds to both chest and triceps at '
    'once, the same way real training volume is normally counted.\n\n'
    'This is a general guideline from group-level research, not a '
    'personalized prescription - more sets isn\'t automatically better '
    'forever, and how much volume any one person can actually recover from '
    'varies.';
