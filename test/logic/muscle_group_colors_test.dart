import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/logic/muscle_group_colors.dart';

Exercise _exercise({
  bool isCustom = false,
  String? sourcePlanName,
  String? author,
}) => Exercise(
  id: 'x',
  name: 'Test Exercise',
  category: 'Custom',
  movementPattern: '',
  muscleGroups: '',
  equipment: '',
  difficulty: 'Beginner',
  measurementType: 'Weight x Reps',
  description: '',
  safetyNotes: '',
  videoReference: '',
  isCustom: isCustom,
  sourcePlanName: sourcePlanName,
  author: author,
  imagePath: null,
);

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

  group('provenanceForExercise', () {
    test('a seed-library exercise is always "library", regardless of fields', () {
      expect(
        provenanceForExercise(_exercise(isCustom: false)),
        ExerciseProvenance.library,
      );
    });

    test('a custom exercise with no plan/author is "own"', () {
      expect(
        provenanceForExercise(_exercise(isCustom: true)),
        ExerciseProvenance.own,
      );
    });

    test('a custom exercise created during a plan import is "fromPlan"', () {
      expect(
        provenanceForExercise(
          _exercise(isCustom: true, sourcePlanName: 'Some Plan'),
        ),
        ExerciseProvenance.fromPlan,
      );
    });

    test('a custom exercise with an author but no plan is "byAuthor"', () {
      expect(
        provenanceForExercise(_exercise(isCustom: true, author: 'Coach Erik')),
        ExerciseProvenance.byAuthor,
      );
    });

    test('sourcePlanName wins over author when both are set', () {
      // Both are set for exercises created during a plan import if the
      // template also carries an author column - the plan is the more
      // specific/traceable provenance of the two.
      expect(
        provenanceForExercise(
          _exercise(
            isCustom: true,
            sourcePlanName: 'Some Plan',
            author: 'Coach Erik',
          ),
        ),
        ExerciseProvenance.fromPlan,
      );
    });
  });

  group('colorForProvenance', () {
    test('every provenance has a distinct colour', () {
      final colors = [
        for (final p in ExerciseProvenance.values) colorForProvenance(p),
      ];
      expect(colors.toSet(), hasLength(colors.length));
    });
  });

  group('colorForCreatorValue', () {
    test('the same value always gets the same colour', () {
      expect(
        colorForCreatorValue('plan:Nine-Block Strength'),
        colorForCreatorValue('plan:Nine-Block Strength'),
      );
    });

    test('different plans get different colours, not one shared colour', () {
      // The bug this guards against: every "Plan: ..." filter chip rendered
      // identically regardless of which plan it was, because they all went
      // through colorForProvenance's single fixed "fromPlan" colour instead
      // of something keyed by the plan itself.
      final colors = {
        for (final name in [
          'plan:Nine-Block Strength',
          'plan:QA_Audit_Strength_Plan',
          'plan:bulk_unmatched_plan',
          'plan:5/3/1 for Beginners',
          'plan:Couch to 5K',
        ])
          name: colorForCreatorValue(name),
      };
      expect(
        colors.values.toSet().length,
        greaterThan(1),
        reason: 'a handful of differently-named plans all hashed to the same colour',
      );
    });

    test('is case-insensitive, so the same name is stable regardless of case', () {
      expect(
        colorForCreatorValue('plan:Push Pull Legs'),
        colorForCreatorValue('plan:push pull legs'),
      );
    });
  });
}
