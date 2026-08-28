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
