/// Pure auto-progression logic (Phase 2). Deliberately isolated from Drift/DB
/// types so it stays trivially unit-testable: input is a plain history list,
/// output is a plain suggestion - no database, no Flutter, no async.
library;

enum ExperienceLevel { beginner, intermediate, advanced }

/// Per-level weight increment applied when the lifter hits [targetReps] on
/// their last logged session. Deliberately fixed increments rather than a
/// percentage of current weight - percentages compound oddly at very
/// low/high weights and are harder to reason about in tests.
const Map<ExperienceLevel, double> _progressionIncrement = {
  ExperienceLevel.beginner: 5.0,
  ExperienceLevel.intermediate: 2.5,
  ExperienceLevel.advanced: 1.25,
};

/// A number of days with no logged session for an exercise after which the
/// suggestion backs off to "repeat last weight" rather than progressing -
/// picking back up after a break shouldn't jump straight to the next
/// increment.
const missedSessionThresholdDays = 10;

/// One past logged session's result for a single exercise, reduced to the
/// single number that matters for progression: the top set's weight and
/// reps. [date] is used only to detect a gap since the last session.
class ProgressionHistoryEntry {
  final DateTime date;
  final double weight;
  final int reps;

  const ProgressionHistoryEntry({
    required this.date,
    required this.weight,
    required this.reps,
  });
}

class ProgressionSuggestion {
  /// Null when there isn't enough history to suggest anything yet.
  final double? suggestedWeight;
  final int? suggestedReps;
  final String rationale;

  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.rationale,
  });
}

/// Suggests the next session's working weight and reps for one exercise.
///
/// [history] does not need to be pre-sorted. [targetReps] is the rep count
/// the lifter is working toward per set (defaults to 8, a common
/// hypertrophy/strength-endurance target); [now] is injectable for testing.
ProgressionSuggestion suggestNextSet({
  required List<ProgressionHistoryEntry> history,
  required ExperienceLevel level,
  int targetReps = 8,
  DateTime? now,
}) {
  if (history.isEmpty) {
    return const ProgressionSuggestion(
      suggestedWeight: null,
      suggestedReps: null,
      rationale: 'No history yet - log a session to get a suggestion.',
    );
  }

  final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
  final last = sorted.last;
  final effectiveNow = now ?? DateTime.now();
  final daysSinceLast = effectiveNow.difference(last.date).inDays;

  if (daysSinceLast > missedSessionThresholdDays) {
    return ProgressionSuggestion(
      suggestedWeight: last.weight,
      suggestedReps: targetReps,
      rationale:
          "It's been $daysSinceLast days since your last session for this "
          'exercise - repeat ${formatWeight(last.weight)} to ease back in.',
    );
  }

  if (last.reps >= targetReps) {
    final increment = _progressionIncrement[level]!;
    return ProgressionSuggestion(
      suggestedWeight: last.weight + increment,
      suggestedReps: targetReps,
      rationale:
          'You hit $targetReps+ reps last time - try '
          '${formatWeight(last.weight + increment)}.',
    );
  }

  if (_isPlateaued(sorted, targetReps)) {
    return ProgressionSuggestion(
      suggestedWeight: last.weight,
      suggestedReps: targetReps,
      rationale:
          "Progress has plateaued at ${formatWeight(last.weight)} - repeat "
          'it and focus on form and rep quality.',
    );
  }

  return ProgressionSuggestion(
    suggestedWeight: last.weight,
    suggestedReps: targetReps,
    rationale:
        "You didn't hit $targetReps reps last time - repeat "
        '${formatWeight(last.weight)} before progressing.',
  );
}

/// Plateaued: the last [_plateauWindow] sessions (at least 2, so a single
/// missed-target session isn't mistaken for a plateau) were all at the same
/// weight and none of them hit the target.
const _plateauWindow = 3;

bool _isPlateaued(List<ProgressionHistoryEntry> sortedHistory, int targetReps) {
  if (sortedHistory.length < _plateauWindow) return false;
  final recent = sortedHistory.sublist(sortedHistory.length - _plateauWindow);
  final weight = recent.last.weight;
  return recent.every((e) => e.weight == weight && e.reps < targetReps);
}

String formatWeight(double weight) {
  final isWhole = weight == weight.roundToDouble();
  return isWhole ? '${weight.toInt()}kg' : '${weight}kg';
}

/// Whether [newValue] is a personal record given everything logged before it.
/// Uniform "higher is better" convention across weight/reps/duration/distance
/// - directionally correct for the strongman-style events in the seed
/// library (more weight, more distance, more time-under-load are all
/// improvements), but not universally true for every conceivable exercise
/// (e.g. a timed sprint where lower is better) - there's no per-exercise
/// "lower is better" flag in the data model yet to do better than this.
bool isPersonalRecord(num newValue, Iterable<num> priorValues) {
  if (priorValues.isEmpty) return true;
  return newValue > priorValues.reduce((a, b) => a > b ? a : b);
}
