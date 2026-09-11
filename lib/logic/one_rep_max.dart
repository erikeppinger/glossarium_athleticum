import 'progression.dart' show ProgressionHistoryEntry;

/// Estimates a one-rep max from a lighter set's weight and reps, using the
/// Epley equation: `1RM = weight * (1 + reps / 30)`.
///
/// Epley's formula originated not from a peer-reviewed derivation but from
/// a poundage chart published in a University of Nebraska resistance-
/// training manual (Epley, 1985) - it's since been repeatedly compared
/// against other estimation equations in the sports-science literature and
/// is widely used, but it's still an estimate, not a measured max. It's
/// most accurate for sets of roughly 3-10 reps; above that, fatigue and
/// technique breakdown add noise, and at very low rep counts (2-3) it
/// tends to *overestimate*. See [oneRepMaxScienceNote] for the in-app
/// explanation shown alongside every displayed value.
double? estimateOneRepMax({required double weightKg, required int reps}) {
  if (weightKg <= 0 || reps <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

/// The highest estimated 1RM across a full history of logged sessions -
/// not just the most recent one, since an older heavier/higher-rep session
/// can still represent the lifter's best-known effort.
double? bestEstimatedOneRepMax(List<ProgressionHistoryEntry> history) {
  double? best;
  for (final entry in history) {
    final estimate = estimateOneRepMax(weightKg: entry.weight, reps: entry.reps);
    if (estimate != null && (best == null || estimate > best)) {
      best = estimate;
    }
  }
  return best;
}

/// Shown behind an info icon next to every "Estimated 1RM" display, per a
/// direct request that this project's own convention (cite the actual
/// method behind any training-science number, see progression.dart's
/// progressionScienceNote) apply here too rather than showing a bare
/// number with no explanation of where it came from.
const oneRepMaxScienceNote =
    'Estimated using the Epley formula: 1RM = weight x (1 + reps / 30). '
    'This traces back to a poundage chart in a 1985 University of Nebraska '
    'resistance-training manual (Boyd Epley), not a peer-reviewed '
    'derivation - but it has since been the most widely used and validated '
    'of the common 1RM-estimation formulas. It is most accurate for sets '
    'of roughly 3-10 reps; above that, fatigue and technique breakdown add '
    'noise, and at very low rep counts it tends to overestimate slightly. '
    'This is an estimate from your logged sets, not a substitute for an '
    'actually-tested max.';
