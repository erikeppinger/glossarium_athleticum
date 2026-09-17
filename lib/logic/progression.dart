/// Pure auto-progression logic (Phase 2). Deliberately isolated from Drift/DB
/// types so it stays trivially unit-testable: input is a plain history list,
/// output is a plain suggestion - no database, no Flutter, no async.
///
/// Reported directly by the user: earlier versions of this file implemented
/// what's sometimes called "gym bro science" - add a fixed amount of weight
/// the instant a single session hits a rep target, no matter how the set
/// actually felt or whether it was a one-off good day. This version follows
/// specific, cited resistance-training research instead. See
/// [progressionScienceNote] for the plain-language explanation shown in the
/// app itself (History screen, next to "Suggested next session").
library;

import 'units.dart';

enum ExperienceLevel { beginner, intermediate, advanced }

/// Per-level load-increase percentage, applied to the *current* working
/// weight (not a fixed kilogram amount) once progression is actually earned
/// - see [progressionScienceNote]. All three values sit inside the "2-10%"
/// range the ACSM position stand ties to load increases at the point of
/// progression (Ratamess et al., 2009, "Progression Models in Resistance
/// Training for Healthy Adults," Medicine & Science in Sports & Exercise,
/// 41(3), 687-708) - that source ties the exact percentage to how much
/// muscle mass an exercise trains (small vs. large muscle groups), which
/// this app doesn't currently categorize exercises by. Experience level is
/// used here as a practical proxy instead: it's well established elsewhere
/// in the same literature that less experienced lifters progress faster and
/// more reliably than experienced ones, so beginners sit toward the top of
/// the cited range and advanced lifters toward the bottom.
const Map<ExperienceLevel, double> _progressionPercent = {
  ExperienceLevel.beginner: 0.075,
  ExperienceLevel.intermediate: 0.05,
  ExperienceLevel.advanced: 0.025,
};

/// A computed increase/decrease is rounded to the nearest half-kilogram
/// (exact percentage math essentially never lands on a real plate/pin
/// increment) and never suggested below this floor - a "increase by 0.3kg"
/// suggestion isn't actionable on most equipment.
const _minPracticalIncrementKg = 0.5;

/// Fraction knocked off the working weight when [_isPlateaued] - a modest
/// deload rather than an indefinite repeat of a weight that has stopped
/// working. Deloading (a planned, temporary reduction in load or volume) is
/// standard practice in strength/physique coaching for managing accumulated
/// fatigue once progress stalls - see the review of coach practice in Bell
/// et al., "'You can't shoot another bullet until you've reloaded the gun':
/// Coaches' perceptions, practices and experiences of deloading in strength
/// and physique sports" (2023). Evidence on how much a deload itself
/// improves subsequent progress is genuinely mixed (a single-week deload has
/// been shown to produce similar hypertrophy but *smaller* strength gains
/// than continuing straight through in at least one controlled trial), so
/// this is offered as one reasonable, low-risk option for a real stall, not
/// a guaranteed fix.
const _deloadFraction = 0.10;

/// Fraction knocked off the working weight after a break longer than
/// [longLayoffThresholdDays] - see that constant's doc comment for why this
/// specific number of days was chosen, and [progressionScienceNote] for the
/// plain-language version. Unlike [_deloadFraction], there isn't a specific
/// meta-analytic percentage to cite for exactly how much strength is lost by
/// a given layoff length (it varies enormously by muscle group, training
/// age, and layoff cause) - this reuses the same conservative, practical
/// figure as a deload rather than inventing a falsely precise number.
const _longLayoffReductionFraction = 0.10;

/// A number of days with no logged session for an exercise after which the
/// suggestion backs off to "repeat last weight" rather than progressing -
/// picking back up after a break shouldn't jump straight to the next
/// increment. Previously set to 10 days, which was arbitrary and, per the
/// actual detraining literature, too aggressive: a meta-analysis of training
/// cessation (Bosquet et al., 2013, cited via the review in Mujika &
/// Padilla's detraining work) found maximal force declined at a similar,
/// unremarkable rate for cessation periods under 7 and 7-14 days, and only
/// became a *significant* decline after roughly three weeks off. 21 days
/// reflects that threshold instead of a round-number guess.
const missedSessionThresholdDays = 21;

/// Beyond this much longer a break, the suggestion doesn't just repeat the
/// last weight - it actively reduces it (see [_longLayoffReductionFraction])
/// since a month-plus layoff is well past the point the detraining
/// literature associates with a measurable strength decline.
const longLayoffThresholdDays = 42;

/// One past logged session's result for a single exercise, reduced to the
/// numbers that matter for progression: the top (heaviest) working weight
/// used, the fewest reps performed at that weight (the hardest set at that
/// weight drives the call, not the easiest - see
/// `SessionLogDao.getProgressionHistory`'s own doc comment), and, if
/// recorded, the highest RPE among those same sets. [date] is used only to
/// detect a gap since the last session.
class ProgressionHistoryEntry {
  final DateTime date;
  final double weight;
  final int reps;

  /// Rating of Perceived Exertion (RIR-based 1-10 scale; 10 = no reps left
  /// in reserve) for the hardest set at [weight], if it was recorded - not
  /// every logged set has one. See [suggestNextSet]'s use of this for why
  /// it matters even when the rep target was met.
  final double? rpe;

  const ProgressionHistoryEntry({
    required this.date,
    required this.weight,
    required this.reps,
    this.rpe,
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
///
/// The core rule - only increase weight after *exceeding* [targetReps] on
/// two consecutive sessions at the same weight, not the instant it's hit
/// once - is the ACSM position stand's own wording: "a 2-10% ... increase in
/// load be applied when the individual can perform the current workload for
/// one to two repetitions over the desired number on two consecutive
/// training sessions" (Ratamess et al., 2009). Requiring two sessions in a
/// row is what actually distinguishes this from "gym bro" progression logic:
/// a single unusually good day (better sleep, a lighter warm-up, pure luck)
/// no longer triggers a permanent weight increase on its own.
ProgressionSuggestion suggestNextSet({
  required List<ProgressionHistoryEntry> history,
  required ExperienceLevel level,
  int targetReps = 8,
  DateTime? now,
  // Only affects how weights are worded in [ProgressionSuggestion.rationale];
  // suggestedWeight stays in kilograms like every other stored weight.
  WeightUnit unit = WeightUnit.kg,
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

  if (daysSinceLast > longLayoffThresholdDays) {
    final reduced = _roundToPracticalIncrement(
      last.weight * (1 - _longLayoffReductionFraction),
    );
    return ProgressionSuggestion(
      suggestedWeight: reduced,
      suggestedReps: targetReps,
      rationale:
          "It's been $daysSinceLast days since your last session for this "
          "exercise - long enough that some strength loss is likely, so ease "
          'back in around ${formatWeight(reduced, unit)} rather than picking '
          'up right where you left off.',
    );
  }

  if (daysSinceLast > missedSessionThresholdDays) {
    return ProgressionSuggestion(
      suggestedWeight: last.weight,
      suggestedReps: targetReps,
      rationale:
          "It's been $daysSinceLast days since your last session for this "
          'exercise - repeat ${formatWeight(last.weight, unit)} to ease back in.',
    );
  }

  final previous = sorted.length >= 2 ? sorted[sorted.length - 2] : null;
  final beatTargetTwiceRunning =
      last.reps > targetReps &&
      previous != null &&
      previous.weight == last.weight &&
      previous.reps > targetReps;

  if (beatTargetTwiceRunning) {
    // A very hard last set (near-failure RPE) even while beating the rep
    // target is itself a signal to progress more cautiously - the RIR-based
    // RPE scale (Zourdos et al., 2016, "Novel Resistance Training-Specific
    // Rating of Perceived Exertion Scale Measuring Repetitions in Reserve")
    // treats 9.5-10 as essentially no reps left in reserve. Falls back to
    // the level-based percentage whenever RPE wasn't recorded.
    final nearFailure = (last.rpe ?? 0) >= 9.5;
    final percent = nearFailure
        ? _progressionPercent[ExperienceLevel.advanced]!
        : _progressionPercent[level]!;
    final increment = _roundToPracticalIncrement(last.weight * percent);
    final next = last.weight + increment;
    final rpeNote = nearFailure
        ? ' (kept small since your last set was rated as near-failure effort)'
        : '';
    return ProgressionSuggestion(
      suggestedWeight: next,
      suggestedReps: targetReps,
      rationale:
          "You've beaten $targetReps reps two sessions in a row at this "
          "weight - that's real, repeated progress rather than one good day, "
          'so try ${formatWeight(next, unit)}$rpeNote.',
    );
  }

  if (last.reps > targetReps) {
    return ProgressionSuggestion(
      suggestedWeight: last.weight,
      suggestedReps: targetReps,
      rationale:
          'You beat $targetReps reps last time - repeat '
          '${formatWeight(last.weight, unit)} once more before adding weight, '
          'so the jump is based on two good sessions, not just one.',
    );
  }

  if (last.reps == targetReps) {
    return ProgressionSuggestion(
      suggestedWeight: last.weight,
      suggestedReps: targetReps,
      rationale:
          'You hit $targetReps reps last time - repeat '
          '${formatWeight(last.weight, unit)} and aim to beat it before '
          'adding weight.',
    );
  }

  if (_isPlateaued(sorted, targetReps)) {
    final deloaded = _roundToPracticalIncrement(
      last.weight * (1 - _deloadFraction),
    );
    return ProgressionSuggestion(
      suggestedWeight: deloaded,
      suggestedReps: targetReps,
      rationale:
          "$_plateauWindow sessions in a row at ${formatWeight(last.weight, unit)} "
          "without hitting $targetReps reps - that's a genuine stall, not "
          'just a bad rep or two. Try a deload at '
          '${formatWeight(deloaded, unit)} for a session before building '
          'back up, rather than repeating a weight that has stopped working.',
    );
  }

  return ProgressionSuggestion(
    suggestedWeight: last.weight,
    suggestedReps: targetReps,
    rationale:
        "You didn't hit $targetReps reps last time - repeat "
        '${formatWeight(last.weight, unit)} before progressing.',
  );
}

/// Rounds to the nearest half-kilogram and never returns less than
/// [_minPracticalIncrementKg] - see that constant's doc comment.
double _roundToPracticalIncrement(double raw) {
  final rounded = (raw * 2).round() / 2;
  return rounded < _minPracticalIncrementKg ? _minPracticalIncrementKg : rounded;
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

/// Formats a stored (kilogram) weight for display in [unit].
///
/// Weights are stored in kilograms throughout the app and converted only at
/// display boundaries. This used to hard-code "kg" and skip the conversion,
/// which meant a user training in pounds was handed a number in the wrong
/// unit with the wrong unit named beside it.
String formatWeight(double weightKg, [WeightUnit unit = WeightUnit.kg]) =>
    formatWeightInUnit(weightKg, unit);

/// Whether [newValue] is a personal record given everything logged before it.
/// Uniform "higher is better" convention across weight/reps/duration/distance
/// - directionally correct for the strongman-style events in the seed
/// library (more weight, more distance, more time-under-load are all
/// improvements), but not universally true for every conceivable exercise
/// (e.g. a timed sprint where lower is better) - there's no per-exercise
/// "lower is better" flag in the data model yet to do better than this.
bool isPersonalRecord(num newValue, Iterable<num> priorValues) {
  if (priorValues.isEmpty) return true;
  // Not `priorValues.reduce((a, b) => a > b ? a : b)`: when the caller's
  // Iterable is reified as something narrower than num (a real List<double>
  // of logged weights, say), the closure inferred here from the *static*
  // `Iterable<num>` parameter type is `num Function(num, num)` - but
  // `reduce` dispatches against the list's *actual* runtime type parameter,
  // which requires `double Function(double, double)`. That mismatch throws
  // a TypeError at runtime (caught live: logging a second set threw this
  // from inside execution_screen.dart's `_logSet`, leaving it permanently
  // stuck on "pending" since the exception fired before `form.logged` was
  // ever set). A manual loop sidesteps the generic-callback dispatch
  // entirely - `>` on two `num`s doesn't care what the iterable reifies to.
  var best = priorValues.first;
  for (final value in priorValues.skip(1)) {
    if (value > best) best = value;
  }
  return newValue > best;
}

/// Plain-language explanation of what [suggestNextSet] is (and isn't) based
/// on, shown directly in the app (History screen, via an info action next to
/// "Suggested next session") per a direct user request: the feature should
/// say what it's based on rather than presenting an opaque number. Kept as a
/// single source of truth here so the in-app text and the reasoning behind
/// the code above can't drift apart.
const progressionScienceNote =
    "These suggestions follow published resistance-training progression "
    'guidance - they are not a personalized coaching or medical '
    'recommendation.\n\n'
    '• Weight only goes up after you exceed your target reps on two '
    'sessions in a row at the same weight, not after a single good day - '
    'the American College of Sports Medicine\'s 2009 position stand on '
    'progression models ties a load increase to performing "one to two '
    'repetitions over the desired number ... on two consecutive training '
    'sessions." The size of the increase (roughly 2-10% of your current '
    'weight, smaller for more experienced lifters) is also drawn from that '
    'same guidance.\n\n'
    '• Several sessions in a row stuck at the same weight without hitting '
    'the target is treated as a genuine plateau rather than a form issue - '
    'the suggestion is a modest, temporary weight reduction (a "deload"), '
    'matching common practice for managing accumulated fatigue in strength '
    'training, rather than repeating a weight that has stopped working.\n\n'
    "• After a break of three weeks or more, the suggested weight backs off "
    'rather than picking up where you left off, since research on training '
    'cessation shows measurable strength loss becoming likely around that '
    'point.\n\n'
    "• This app deliberately doesn't build in periodization (planned waves "
    'of heavier/lighter training blocks) - a 2026 ACSM overview of over '
    '130 systematic reviews found periodized programs are not consistently '
    'superior to simple non-periodized progression once progressive '
    'overload is applied, so keeping progression straightforward is a '
    'considered choice, not a missing feature. That same overview also '
    'confirms training to complete muscular failure isn\'t necessary for '
    "gains, matching how these suggestions never require it.\n\n"
    'Sources: Ratamess et al. (2009), "Progression Models in Resistance '
    'Training for Healthy Adults," American College of Sports Medicine '
    'position stand, Medicine & Science in Sports & Exercise 41(3); '
    'Currier et al. (2026), "Resistance Training Prescription for Muscle '
    'Function, Hypertrophy, and Physical Performance in Healthy Adults: An '
    'Overview of Reviews," American College of Sports Medicine position '
    'stand, Medicine & Science in Sports & Exercise 58(4), which updates '
    "the 2009 stand above.";
