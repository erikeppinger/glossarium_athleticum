/// Lets a plan's free-text `weightIntensity` field carry "70%" instead of
/// a flat number, resolved at prescription/execution time against the
/// exercise's current best estimated 1RM (see `lib/logic/one_rep_max.dart`)
/// rather than a separately-maintained "training max" - reuses history
/// that's already tracked instead of adding a new maintained value.
library;

/// Whether [weightIntensity] (trimmed) is a plain percentage like "70%" or
/// "70.5 %" - a leading number, optional whitespace, then a trailing '%'
/// and nothing else. Anything else (a flat "60kg", a range, free text) is
/// not a percentage prescription and is left to parse as it always has.
bool isPercentagePrescription(String weightIntensity) {
  return RegExp(r'^\d+(\.\d+)?\s*%$').hasMatch(weightIntensity.trim());
}

/// The numeric percentage out of a string already confirmed by
/// [isPercentagePrescription], or null if it isn't one.
double? parsePercentage(String weightIntensity) {
  final trimmed = weightIntensity.trim();
  if (!isPercentagePrescription(trimmed)) return null;
  return double.tryParse(trimmed.substring(0, trimmed.length - 1).trim());
}

/// Resolves a percentage prescription against a known 1RM - null-safe, so
/// a percentage prescription on an exercise with no logged history yet
/// simply has nothing to resolve to (the caller shows a "no history yet"
/// fallback rather than a wrong number).
double? resolvePercentageWeight({
  required double percent,
  required double? estimatedOneRepMaxKg,
}) {
  if (estimatedOneRepMaxKg == null || estimatedOneRepMaxKg <= 0) return null;
  return estimatedOneRepMaxKg * (percent / 100);
}
