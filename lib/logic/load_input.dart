import 'equipment_matching.dart';

/// What the weight column of a logged set should be for one exercise.
enum LoadInput {
  /// A normal weight field.
  weight,

  /// A bodyweight exercise that can still be loaded (vest, dip belt): an
  /// optional field for the extra weight only, "BW" when left empty.
  addedWeight,

  /// Nothing to weigh - warm-ups, mobility, stretches, holds for time.
  none,
}

const _noLoadCategoryWords = ['warm', 'mobility', 'stretch', 'cool'];

/// The weight field's label - "Added (kg)" for a bodyweight exercise, since
/// the number entered is only the extra load on top of the body.
String weightFieldLabel(LoadInput input, {required bool lbs}) {
  final unit = lbs ? 'lbs' : 'kg';
  return input == LoadInput.addedWeight ? 'Added ($unit)' : 'Weight ($unit)';
}

/// Picks the weight input for an exercise from its library entry and,
/// where that's thin (plan-imported custom exercises often have no
/// equipment filled in), from the plan's own prescription. Measurement
/// type alone can't decide this: many bodyweight warm-ups in real data
/// carry the generic "Weight x Reps".
LoadInput loadInputFor({
  required String equipment,
  required String category,
  required String measurementType,
  String prescribedWeight = '',
}) {
  final prescribedBodyweight = RegExp(
    r'^\s*(bw|body\s*weight)\s*$',
    caseSensitive: false,
  ).hasMatch(prescribedWeight);

  // Cardio done for time or distance (jump rope, rowing, battle ropes) has
  // nothing to weigh whatever equipment it uses - unless the plan names a
  // load (a weighted-vest run). Loaded carries and sled work live in their
  // own categories and keep their weight field.
  final typeMentionsLoad = RegExp(
    r'weight|load',
    caseSensitive: false,
  ).hasMatch(measurementType);
  final prescriptionNamesLoad = RegExp(
    r'\d\s*(kg|lbs?)\b',
    caseSensitive: false,
  ).hasMatch(prescribedWeight);
  if (category.toLowerCase().contains('cardio') &&
      !typeMentionsLoad &&
      !prescriptionNamesLoad) {
    return LoadInput.none;
  }
  if (!isBodyweightOnly(equipment) && !prescribedBodyweight) {
    return LoadInput.weight;
  }

  // A prescribed load ("10kg", or a bare "10") always gets a visible field:
  // otherwise the set row's pre-filled weight would be saved unseen.
  final prescribedLoad = RegExp(
    r'^\s*\d+(\.\d+)?\s*(kg|lbs?)?\s*$',
    caseSensitive: false,
  ).hasMatch(prescribedWeight);
  if (prescribedLoad) return LoadInput.addedWeight;

  final lowerCategory = category.toLowerCase();
  final lowerMeasurement = measurementType.toLowerCase();
  final measuresLoad =
      lowerMeasurement.contains('weight') ||
      lowerMeasurement.contains('load') ||
      lowerMeasurement.contains('reps');
  if (_noLoadCategoryWords.any(lowerCategory.contains) || !measuresLoad) {
    return LoadInput.none;
  }
  return LoadInput.addedWeight;
}
