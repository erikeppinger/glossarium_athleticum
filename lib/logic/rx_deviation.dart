import '../data/app_database.dart' show LoggedSet, PlanExercise;
import 'set_measure.dart';
import 'skip_reason.dart';

/// What kind of thing the trainer-facing "Full training log" report is
/// flagging about one exercise's actual sets versus what the plan
/// prescribed - lets a trainer scan for exceptions instead of reading every
/// prescribed/actual line pair to spot a difference by eye.
/// [skippedForPain] is split out from [skipped] so a possible injury stands
/// out from "the machine was busy".
enum RxDeviationKind {
  fewerSets,
  belowTarget,
  nearFailure,
  hasNote,
  skipped,
  skippedForPain,
}

class RxDeviation {
  final RxDeviationKind kind;
  final String label;
  const RxDeviation(this.kind, this.label);
}

/// A light, best-effort read of the first plain number in a free-text
/// prescription field (e.g. "10 each leg" -> 10, "1" -> 1) - reps are
/// unit-less, so this is safe to use directly; weight is not (see
/// [parsePrescribedWeightKg] for why that one needs its own, stricter
/// parser instead of this).
double? leadingNumber(String text) {
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(text);
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

/// Reads a prescribed weight in kg from `PlanExercises.weightIntensity`,
/// only when the text is confidently an absolute kg figure ("40kg",
/// "40.0 kg") - never from "70%" (a percentage of estimated 1RM, not a raw
/// kg number), "RPE 8", "Bodyweight", or anything else free-text authors
/// use there. A prescription this can't confidently read as kg is treated
/// as unverifiable rather than guessed at, so a percentage or RPE-based
/// prescription never produces a false "under target" flag from comparing
/// mismatched units.
double? parsePrescribedWeightKg(String weightIntensity) {
  final match = RegExp(
    r'^(\d+(\.\d+)?)\s*kg$',
    caseSensitive: false,
  ).firstMatch(weightIntensity.trim());
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

/// Compares what was actually logged for one exercise in one session
/// against its own plan prescription, returning only what's worth a
/// trainer's attention - empty when the session went as planned, so the
/// report can stay quiet about the common case and only draw the eye to
/// exceptions. [noteText] surfaces any trainee feedback attached to one of
/// [actual]'s sets (see `LoggedSets.notes`) as its own flag, since a note is
/// exactly the kind of thing a trainer skimming a long report shouldn't
/// have to hunt for either.
List<RxDeviation> computeRxDeviations({
  required PlanExercise? prescription,
  required List<LoggedSet> actual,
  String? noteText,
}) {
  final flags = <RxDeviation>[];

  if (noteText != null && noteText.isNotEmpty) {
    flags.add(RxDeviation(RxDeviationKind.hasNote, noteText));
  }

  if (prescription == null || actual.isEmpty) return flags;

  if (actual.length < prescription.sets) {
    flags.add(
      RxDeviation(
        RxDeviationKind.fewerSets,
        '${actual.length} of ${prescription.sets} sets logged',
      ),
    );
  }

  final targetReps = leadingNumber(prescription.reps);
  if (targetReps != null) {
    final shortSets = actual
        .where((s) => s.reps != null && s.reps! < targetReps)
        .length;
    if (shortSets > 0) {
      flags.add(
        RxDeviation(
          RxDeviationKind.belowTarget,
          'Under rep target on $shortSets set${shortSets == 1 ? '' : 's'}',
        ),
      );
    }
  }

  // A hold or a carry prescribes seconds or metres rather than reps.
  final prescribedText = '${prescription.reps} ${prescription.weightIntensity}';
  final targetSec = parseDurationSec(prescribedText);
  if (targetSec != null) {
    final shortSets = actual
        .where((s) => s.durationSec != null && s.durationSec! < targetSec)
        .length;
    if (shortSets > 0) {
      flags.add(
        RxDeviation(
          RxDeviationKind.belowTarget,
          'Under time target on $shortSets set${shortSets == 1 ? '' : 's'}',
        ),
      );
    }
  }
  final targetMeters = parseDistanceMeters(prescribedText);
  if (targetMeters != null) {
    final shortSets = actual
        .where((s) => s.distance != null && s.distance! < targetMeters)
        .length;
    if (shortSets > 0) {
      flags.add(
        RxDeviation(
          RxDeviationKind.belowTarget,
          'Under distance target on $shortSets set${shortSets == 1 ? '' : 's'}',
        ),
      );
    }
  }

  final targetWeight = parsePrescribedWeightKg(prescription.weightIntensity);
  if (targetWeight != null) {
    final lightSets = actual
        .where((s) => s.weight != null && s.weight! < targetWeight)
        .length;
    if (lightSets > 0) {
      flags.add(
        RxDeviation(
          RxDeviationKind.belowTarget,
          'Under weight target on $lightSets set${lightSets == 1 ? '' : 's'}',
        ),
      );
    }
  }

  if (actual.any((s) => s.rpe != null && s.rpe! >= 9.5)) {
    flags.add(
      const RxDeviation(RxDeviationKind.nearFailure, 'Near failure (RPE 9.5+)'),
    );
  }

  return flags;
}

/// The flag for a prescribed exercise that was skipped, e.g. "Skipped -
/// Pain or injury, replaced by Dumbbell Press". [reasonKey] is a
/// `SkipReason.key` (or null when none was picked).
RxDeviation skippedDeviation({String? reasonKey, String? replacedByName}) {
  final reason = SkipReason.fromKey(reasonKey);
  final label = StringBuffer('Skipped');
  if (reason != null) label.write(' - ${reason.label}');
  if (replacedByName != null) label.write(', replaced by $replacedByName');
  return RxDeviation(
    reason == SkipReason.painOrInjury
        ? RxDeviationKind.skippedForPain
        : RxDeviationKind.skipped,
    label.toString(),
  );
}
