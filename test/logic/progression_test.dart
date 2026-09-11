import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/progression.dart';
import 'package:training_app/logic/units.dart';

ProgressionHistoryEntry entry(
  DateTime date,
  double weight,
  int reps, {
  double? rpe,
}) => ProgressionHistoryEntry(date: date, weight: weight, reps: reps, rpe: rpe);

void main() {
  final now = DateTime(2026, 8, 26);

  group('suggestNextSet', () {
    test('empty history returns no suggestion', () {
      final result = suggestNextSet(
        history: const [],
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.suggestedWeight, isNull);
      expect(result.suggestedReps, isNull);
      expect(result.rationale, contains('No history'));
    });

    test('beating the target once (not yet twice in a row) repeats the weight', () {
      // The core "2-for-2 rule" fix: a single good session must not, on its
      // own, trigger a permanent weight increase - see the ACSM citation in
      // suggestNextSet's own doc comment.
      final history = [entry(now.subtract(const Duration(days: 3)), 60, 9)];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.suggestedWeight, 60.0);
      expect(result.suggestedReps, 8);
      expect(result.rationale, contains('beat'));
      expect(result.rationale, contains('once more'));
    });

    test('hitting exactly the target (not exceeding it) repeats the weight', () {
      final history = [entry(now.subtract(const Duration(days: 3)), 60, 8)];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.suggestedWeight, 60.0);
      expect(result.rationale, contains('hit'));
      expect(result.rationale, contains('aim to beat'));
    });

    test(
      'beating the target on two consecutive sessions at the same weight '
      'progresses, sized by level as a percentage of current weight',
      () {
        final history = [
          entry(now.subtract(const Duration(days: 10)), 60, 10),
          entry(now.subtract(const Duration(days: 3)), 60, 10),
        ];

        final beginner = suggestNextSet(
          history: history,
          level: ExperienceLevel.beginner,
          now: now,
        );
        final intermediate = suggestNextSet(
          history: history,
          level: ExperienceLevel.intermediate,
          now: now,
        );
        final advanced = suggestNextSet(
          history: history,
          level: ExperienceLevel.advanced,
          now: now,
        );

        expect(beginner.suggestedWeight, 64.5); // 60 * 1.075
        expect(intermediate.suggestedWeight, 63.0); // 60 * 1.05
        expect(advanced.suggestedWeight, 61.5); // 60 * 1.025
        expect(beginner.suggestedReps, 8);
        expect(beginner.rationale, contains('two sessions in a row'));
      },
    );

    test(
      'a near-failure RPE on the qualifying session caps the increase at the '
      'smallest tier regardless of experience level',
      () {
        final history = [
          entry(now.subtract(const Duration(days: 10)), 60, 10),
          entry(now.subtract(const Duration(days: 3)), 60, 10, rpe: 9.5),
        ];
        final result = suggestNextSet(
          history: history,
          level: ExperienceLevel.beginner,
          now: now,
        );
        expect(result.suggestedWeight, 61.5); // advanced-tier 2.5%, not 7.5%
        expect(result.rationale, contains('near-failure'));
      },
    );

    test('a moderate RPE does not cap the increase', () {
      final history = [
        entry(now.subtract(const Duration(days: 10)), 60, 10),
        entry(now.subtract(const Duration(days: 3)), 60, 10, rpe: 7.0),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.beginner,
        now: now,
      );
      expect(result.suggestedWeight, 64.5);
      expect(result.rationale, isNot(contains('near-failure')));
    });

    test('an increase below the practical floor is rounded up to it', () {
      final history = [
        entry(now.subtract(const Duration(days: 10)), 2.0, 10),
        entry(now.subtract(const Duration(days: 3)), 2.0, 10),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.advanced,
        now: now,
      );
      // 2.0 * 2.5% = 0.05, floored to the 0.5kg practical minimum.
      expect(result.suggestedWeight, 2.5);
    });

    test('the computed increase is rounded to the nearest half-kilogram', () {
      final history = [
        entry(now.subtract(const Duration(days: 10)), 57, 10),
        entry(now.subtract(const Duration(days: 3)), 57, 10),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      // 57 * 5% = 2.85, rounds to 3.0.
      expect(result.suggestedWeight, 60.0);
    });

    test("missing target reps (but not plateaued) repeats the same weight", () {
      final history = [
        entry(now.subtract(const Duration(days: 10)), 60, 6),
        entry(now.subtract(const Duration(days: 3)), 60, 6),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.suggestedWeight, 60.0);
      expect(result.suggestedReps, 8);
      expect(result.rationale, contains("didn't hit"));
    });

    test(
      'plateaued history (3+ sessions at same weight, missing target) '
      'suggests a deload rather than an indefinite repeat',
      () {
        final history = [
          entry(now.subtract(const Duration(days: 20)), 60, 6),
          entry(now.subtract(const Duration(days: 13)), 60, 7),
          entry(now.subtract(const Duration(days: 6)), 60, 6),
        ];
        final result = suggestNextSet(
          history: history,
          level: ExperienceLevel.intermediate,
          now: now,
        );
        expect(result.suggestedWeight, 54.0); // 60 * (1 - 10%)
        expect(result.rationale, contains('stall'));
        expect(result.rationale, contains('deload'));
      },
    );

    test('the deload amount is also rounded to the nearest half-kilogram', () {
      final history = [
        entry(now.subtract(const Duration(days: 20)), 57, 6),
        entry(now.subtract(const Duration(days: 13)), 57, 7),
        entry(now.subtract(const Duration(days: 6)), 57, 6),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      // 57 * 0.9 = 51.3, rounds to 51.5.
      expect(result.suggestedWeight, 51.5);
    });

    test('two sessions missing target at the same weight is not yet a plateau', () {
      // Only 2 data points - the plateau window wants 3+ before concluding
      // it's stuck, so a single repeat shouldn't trigger the deload message.
      final history = [
        entry(now.subtract(const Duration(days: 13)), 60, 6),
        entry(now.subtract(const Duration(days: 6)), 60, 6),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.rationale, isNot(contains('deload')));
      expect(result.suggestedWeight, 60.0);
    });

    test('a weight change resets the plateau window', () {
      final history = [
        entry(now.subtract(const Duration(days: 27)), 55, 6),
        entry(now.subtract(const Duration(days: 20)), 55, 6),
        entry(now.subtract(const Duration(days: 13)), 60, 6), // weight bumped
        entry(now.subtract(const Duration(days: 6)), 60, 6),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      // Only 2 of the last 3 entries are at the current weight (60), so this
      // isn't a 3-session plateau yet.
      expect(result.rationale, isNot(contains('deload')));
    });

    test(
      'a gap longer than missedSessionThresholdDays (but not yet a long '
      'layoff) suggests repeating the last weight, not reducing it',
      () {
        final history = [entry(now.subtract(const Duration(days: 30)), 60, 8)];
        final result = suggestNextSet(
          history: history,
          level: ExperienceLevel.beginner,
          now: now,
        );
        expect(result.suggestedWeight, 60.0);
        expect(result.rationale, contains('days since your last session'));
      },
    );

    test(
      'a long layoff (past longLayoffThresholdDays) suggests a reduced '
      'weight, not just a repeat',
      () {
        final history = [entry(now.subtract(const Duration(days: 50)), 60, 8)];
        final result = suggestNextSet(
          history: history,
          level: ExperienceLevel.beginner,
          now: now,
        );
        expect(result.suggestedWeight, 54.0); // 60 * (1 - 10%)
        expect(result.rationale, contains('days since your last session'));
        expect(result.rationale, contains('strength loss'));
      },
    );

    test('a gap exactly at missedSessionThresholdDays does not count as missed', () {
      final history = [
        entry(
          now.subtract(const Duration(days: missedSessionThresholdDays)),
          60,
          8,
        ),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.beginner,
        now: now,
      );
      expect(result.rationale, isNot(contains('days since')));
      expect(result.suggestedWeight, 60.0);
    });

    test(
      'a gap exactly at longLayoffThresholdDays does not trigger the '
      'reduced-weight branch, only the plain repeat',
      () {
        final history = [
          entry(
            now.subtract(const Duration(days: longLayoffThresholdDays)),
            60,
            8,
          ),
        ];
        final result = suggestNextSet(
          history: history,
          level: ExperienceLevel.beginner,
          now: now,
        );
        expect(result.suggestedWeight, 60.0);
        expect(result.rationale, contains('days since your last session'));
        expect(result.rationale, isNot(contains('strength loss')));
      },
    );

    test('unsorted history is sorted internally before use', () {
      final history = [
        entry(now.subtract(const Duration(days: 3)), 65, 9), // most recent
        entry(now.subtract(const Duration(days: 10)), 60, 4),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      // Should react to the most recent entry (65kg, beat target once), not
      // whichever happens to be last in the input list - and since the
      // session before it was at a different weight, this only counts as
      // the first time beating target at 65kg.
      expect(result.suggestedWeight, 65.0);
      expect(result.rationale, contains('beat'));
    });
  });

  group('isPersonalRecord', () {
    test('anything is a PR against empty prior history', () {
      expect(isPersonalRecord(50, []), isTrue);
    });

    test('strictly greater than the prior max is a PR', () {
      expect(isPersonalRecord(61, [55, 60]), isTrue);
    });

    test('equal to the prior max (a tie) is not a new PR', () {
      expect(isPersonalRecord(60, [55, 60]), isFalse);
    });

    test('less than the prior max is not a PR', () {
      expect(isPersonalRecord(58, [55, 60]), isFalse);
    });

    // Regression test: a list literal like `[55, 60]` above infers as
    // `List<num>`, which never reproduced the real crash - execution_screen
    // .dart actually passes a concrete `List<double>` (weights read back
    // from the DB plus this session's own logged weights), and calling
    // `.reduce()` against an `Iterable<num>`-typed parameter backed by a
    // `List<double>` at runtime threw "type '(num, num) => num' is not a
    // subtype of type '(double, double) => double'" - reproduced live by
    // logging a second set in execution mode on an emulator, which got
    // stuck on "pending" forever since the exception fired before
    // `form.logged` was ever set. Force the same reification here.
    test('works against a real List<double>, not just a num literal list', () {
      final priorWeights = List<double>.from([55.0, 60.0]);
      expect(isPersonalRecord(61.0, priorWeights), isTrue);
      expect(isPersonalRecord(60.0, priorWeights), isFalse);
    });
  });

  group('suggestion wording respects the weight unit', () {
    final history = [
      entry(DateTime(2026, 8, 13), 60, 10),
      entry(DateTime(2026, 8, 20), 60, 10),
    ];

    test('defaults to kilograms', () {
      final suggestion = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: DateTime(2026, 8, 22),
      );
      expect(suggestion.rationale, contains('63kg'));
    });

    test('converts and names pounds when that unit is selected', () {
      // Regression: this used to hard-code "kg" and skip conversion, so a
      // user training in pounds got a kilogram number labelled "kg".
      final suggestion = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: DateTime(2026, 8, 22),
        unit: WeightUnit.lbs,
      );
      expect(suggestion.rationale, contains('lbs'));
      expect(
        suggestion.rationale,
        isNot(contains('kg')),
        reason: 'a lbs user should never see kg in the advice',
      );
      // 63 kg is about 138.9 lbs.
      expect(suggestion.rationale, contains('138.9'));
    });

    test('the suggested weight itself stays in kilograms', () {
      final suggestion = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: DateTime(2026, 8, 22),
        unit: WeightUnit.lbs,
      );
      expect(
        suggestion.suggestedWeight,
        63.0,
        reason: 'storage stays in kg; only the wording is localised',
      );
    });
  });
}
