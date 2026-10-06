import 'units.dart';

/// What one set of an exercise counts: repetitions, how long it was held
/// or done for, or how far it went. Decides which field a set row shows
/// and which `LoggedSets` column the number is saved to.
enum SetMeasure { reps, time, distance }

final _clock = RegExp(r'\b(\d{1,2}):(\d{2})\b');
final _time = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(s|sec|secs|second|seconds|min|mins|minute|minutes)\b',
  caseSensitive: false,
);
final _distance = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(m|meter|meters|metre|metres|km)\b',
  caseSensitive: false,
);

double _number(String raw) => double.parse(raw.replaceAll(',', '.'));

/// "45 sec" -> 45, "1 min" -> 60, "1:30" -> 90; null when [text] names no
/// duration.
double? parseDurationSec(String text) {
  final clock = _clock.firstMatch(text);
  if (clock != null) {
    return int.parse(clock.group(1)!) * 60.0 + int.parse(clock.group(2)!);
  }
  final match = _time.firstMatch(text);
  if (match == null) return null;
  final value = _number(match.group(1)!);
  return match.group(2)!.toLowerCase().startsWith('m') ? value * 60 : value;
}

/// "250m" -> 250, "1.5 km" -> 1500; null when [text] names no distance.
double? parseDistanceMeters(String text) {
  final match = _distance.firstMatch(text);
  if (match == null) return null;
  final value = _number(match.group(1)!);
  return match.group(2)!.toLowerCase() == 'km' ? value * 1000 : value;
}

final _leadingAmount = RegExp(
  r'^\s*(\d{1,2}:\d{2}|\d+(?:[.,]\d+)?\s*[a-z]+)',
  caseSensitive: false,
);
final _loadMention = RegExp(r'\d\s*(kg|lbs?)\b|%|rpe', caseSensitive: false);

/// The part of a prescription that states what a set counts: the reps
/// column when it starts with an amount ("30 sec", "50m"), or the weight
/// column when it names no load at all ("45 sec", "60 sec each side").
/// A cue riding along with a rep count or a load - "8 (2 sec pause)",
/// "60kg, 3s eccentric", "100kg, 2m rest" - is not what's counted.
String _countedPart(String reps, String weight) => [
  if (_leadingAmount.hasMatch(reps)) reps,
  if (!_loadMention.hasMatch(weight)) weight,
].join(' ');

/// The plan's own prescription wins - "45 sec" or "250m" stated as the
/// amount is unambiguous - and the library's measurement type decides the
/// rest. A measurement type naming weight, reps or load ("Weight x Reps",
/// "Time or Reps", "Max Load or Time") stays reps-based; only a pure
/// "Time" or a distance-first type switches.
SetMeasure setMeasureFor({
  required String measurementType,
  String prescribedReps = '',
  String prescribedWeight = '',
}) {
  final prescription = _countedPart(prescribedReps, prescribedWeight);
  if (parseDurationSec(prescription) != null) return SetMeasure.time;
  if (parseDistanceMeters(prescription) != null) return SetMeasure.distance;

  final type = measurementType.toLowerCase();
  if (type.contains('weight') || type.contains('rep') || type.contains('load')) {
    return SetMeasure.reps;
  }
  if (type.contains('distance')) return SetMeasure.distance;
  if (type.contains('time')) return SetMeasure.time;
  return SetMeasure.reps;
}

/// The prescribed seconds or metres for [measure], if the prescription
/// states one - what a new set row pre-fills.
double? prescribedAmount(
  SetMeasure measure, {
  String prescribedReps = '',
  String prescribedWeight = '',
}) {
  final prescription = _countedPart(prescribedReps, prescribedWeight);
  return switch (measure) {
    SetMeasure.time => parseDurationSec(prescription),
    SetMeasure.distance => parseDistanceMeters(prescription),
    SetMeasure.reps => null,
  };
}

/// A set's duration: "45s", "1:30 min".
String formatSetDuration(double seconds) {
  final total = seconds.round();
  if (total < 60) return '${total}s';
  final remainder = total % 60;
  return remainder == 0
      ? '${total ~/ 60} min'
      : '${total ~/ 60}:${remainder.toString().padLeft(2, '0')} min';
}

/// A set's distance: "250 m", "1.5 km".
String formatSetDistance(double meters) => formatDistanceMeters(meters);
