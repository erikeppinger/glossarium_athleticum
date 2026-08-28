import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/muscle_group_colors.dart';

void main() {
  group('areaForExercise', () {
    test('classifies the seed library\'s muscle-group wording', () {
      expect(
        areaForExercise(muscleGroups: 'Posterior Chain, Back'),
        MuscleArea.legs,
        reason: 'legs must win over the "back" substring in "posterior chain"',
      );
      expect(areaForExercise(muscleGroups: 'Chest'), MuscleArea.chest);
      expect(areaForExercise(muscleGroups: 'Quads, Glutes'), MuscleArea.legs);
      expect(areaForExercise(muscleGroups: 'Shoulders'), MuscleArea.shoulders);
      expect(areaForExercise(muscleGroups: 'Lats, Upper Back'), MuscleArea.back);
    });

    test('classifies German wording from the imported plan', () {
      expect(areaForExercise(muscleGroups: 'Beine'), MuscleArea.legs);
      expect(areaForExercise(muscleGroups: 'Waden'), MuscleArea.legs);
      expect(areaForExercise(muscleGroups: 'Brust'), MuscleArea.chest);
    });

    test('cardio wins over any muscle wording it appears with', () {
      expect(
        areaForExercise(category: 'Conditioning', muscleGroups: 'Legs'),
        MuscleArea.cardio,
      );
    });

    test('falls back to other rather than guessing', () {
      expect(areaForExercise(), MuscleArea.other);
      expect(areaForExercise(muscleGroups: 'Wrist'), MuscleArea.other);
    });

    test('can classify from category or movement pattern alone', () {
      expect(areaForExercise(movementPattern: 'Squat'), MuscleArea.legs);
      expect(areaForExercise(category: 'Grip & Core'), MuscleArea.arms);
    });
  });

  group('colorForArea', () {
    test('every area has a colour in every palette', () {
      for (final palette in AppColorPalette.values) {
        for (final area in MuscleArea.values) {
          expect(
            () => colorForArea(area, palette),
            returnsNormally,
            reason: '$area missing from $palette',
          );
        }
      }
    });

    test('colours within a palette are distinct', () {
      for (final palette in AppColorPalette.values) {
        final colors = [
          for (final area in MuscleArea.values) colorForArea(area, palette),
        ];
        expect(
          colors.toSet(),
          hasLength(colors.length),
          reason: '$palette reuses a colour for two different areas',
        );
      }
    });

    test('the monochrome palette really has no hue', () {
      for (final area in MuscleArea.values) {
        final c = colorForArea(area, AppColorPalette.monochrome);
        expect(
          {c.r, c.g, c.b},
          hasLength(1),
          reason: '$area is not a true grey in the monochrome palette',
        );
      }
    });

    test('monochrome lightness steps are far enough apart to tell apart', () {
      // Sorted by luminance, adjacent entries must differ enough that they
      // don't read as the same shade.
      final lums = [
        for (final area in MuscleArea.values)
          colorForArea(area, AppColorPalette.monochrome).computeLuminance(),
      ]..sort();
      for (var i = 1; i < lums.length; i++) {
        expect(
          lums[i] - lums[i - 1],
          greaterThan(0.01),
          reason: 'two monochrome shades are nearly identical',
        );
      }
    });

    test('every palette label and description is non-empty', () {
      for (final palette in AppColorPalette.values) {
        expect(palette.label, isNotEmpty);
        expect(palette.description, isNotEmpty);
      }
    });
  });
}
