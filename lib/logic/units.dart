/// Display unit for weight values. All weight is stored in the DB in
/// kilograms regardless of this setting - it only controls conversion at
/// input/display boundaries (see `lib/features/execution/execution_screen.dart`
/// and `lib/features/history/history_screen.dart`).
enum WeightUnit { kg, lbs }

const _kgPerLb = 0.45359237;

double kgToDisplay(double kg, WeightUnit unit) =>
    unit == WeightUnit.lbs ? kg / _kgPerLb : kg;

double displayToKg(double value, WeightUnit unit) =>
    unit == WeightUnit.lbs ? value * _kgPerLb : value;

/// Formats a plain number (no unit suffix) - for pre-filling an editable
/// weight field, where appending "kg"/"lbs" to the text itself would break
/// re-parsing the user's edits.
String formatWeightNumber(double value) {
  final isWhole = value == value.roundToDouble();
  return isWhole ? value.toInt().toString() : value.toStringAsFixed(1);
}

String formatWeightInUnit(double kg, WeightUnit unit) {
  final converted = kgToDisplay(kg, unit);
  return '${formatWeightNumber(converted)}${unit == WeightUnit.lbs ? 'lbs' : 'kg'}';
}

// --- Lengths (body measurements) -------------------------------------------
//
// Circumferences are stored in centimetres and converted for display the same
// way weights are. Someone who picked pounds has signalled a preference for
// imperial units and will expect inches.

const _cmPerInch = 2.54;

String lengthUnitLabel(WeightUnit unit) =>
    unit == WeightUnit.lbs ? 'in' : 'cm';

double cmToDisplay(double cm, WeightUnit unit) =>
    unit == WeightUnit.lbs ? cm / _cmPerInch : cm;

double displayToCm(double value, WeightUnit unit) =>
    unit == WeightUnit.lbs ? value * _cmPerInch : value;

String formatLengthInUnit(double cm, WeightUnit unit) {
  final converted = cmToDisplay(cm, unit);
  return '${formatWeightNumber(converted)}${lengthUnitLabel(unit)}';
}

// --- Ad-hoc activity duration/distance --------------------------------------
//
// Meters is the stored unit for every `distance` column in this app (see
// `LoggedSets.distance`), regardless of the kg/lbs weight-unit preference -
// there's no separate metric/imperial distance setting, so these always
// format the same way.

String formatDurationSec(double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours h' : '$hours h $remainder min';
}

String formatDistanceMeters(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km'
    : '${meters.toStringAsFixed(0)} m';

/// Formats a time of day as either "HH:MM" (24-hour) or "H:MM AM/PM" -
/// see `lib/features/settings/app_preferences.dart`'s `ClockFormat` for why
/// this is a user choice rather than always following locale. Takes plain
/// hour/minute ints (not `TimeOfDay`) to keep this file Flutter-free, same
/// as every other formatter here.
String formatTimeOfDay(int hour, int minute, {required bool use24Hour}) {
  final m = minute.toString().padLeft(2, '0');
  if (use24Hour) {
    return '${hour.toString().padLeft(2, '0')}:$m';
  }
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'AM' : 'PM';
  return '$hour12:$m $period';
}
