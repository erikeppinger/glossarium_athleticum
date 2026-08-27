import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/progression.dart';

ProgressionHistoryEntry entry(DateTime date, double weight, int reps) =>
    ProgressionHistoryEntry(date: date, weight: weight, reps: reps);

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

    test('hitting target reps suggests a weight increase, sized by level', () {
      final history = [entry(now.subtract(const Duration(days: 3)), 60, 8)];

      final beginner = suggestNextSet(
        history: history,
        level: ExperienceLevel.beginner,
        now: now,
      );
      final advanced = suggestNextSet(
        history: history,
        level: ExperienceLevel.advanced,
        now: now,
      );

      expect(beginner.suggestedWeight, 65.0);
      expect(advanced.suggestedWeight, 61.25);
      expect(beginner.suggestedReps, 8);
    });

    test('missing target reps (but not plateaued) repeats the same weight', () {
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

    test('plateaued history (3+ sessions at same weight, missing target) is flagged', () {
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
      expect(result.suggestedWeight, 60.0);
      expect(result.rationale, contains('plateaued'));
    });

    test('two sessions missing target at the same weight is not yet a plateau', () {
      // Only 2 data points - the plateau window wants 3+ before concluding
      // it's stuck, so a single repeat shouldn't trigger the plateau message.
      final history = [
        entry(now.subtract(const Duration(days: 13)), 60, 6),
        entry(now.subtract(const Duration(days: 6)), 60, 6),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.rationale, isNot(contains('plateaued')));
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
      expect(result.rationale, isNot(contains('plateaued')));
    });

    test('missed sessions (long gap) suggests repeating last weight, not progressing', () {
      final history = [entry(now.subtract(const Duration(days: 45)), 60, 8)];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.beginner,
        now: now,
      );
      // Even though reps=8 met target, the long gap takes priority over the
      // "hit target -> increase" rule.
      expect(result.suggestedWeight, 60.0);
      expect(result.rationale, contains('days since your last session'));
    });

    test('gap exactly at the threshold does not count as missed', () {
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
      expect(result.suggestedWeight, 65.0);
    });

    test('unsorted history is sorted internally before use', () {
      final history = [
        entry(now.subtract(const Duration(days: 3)), 65, 8), // most recent
        entry(now.subtract(const Duration(days: 10)), 60, 4),
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      // Should react to the most recent entry (65kg, hit target), not
      // whichever happens to be last in the input list.
      expect(result.suggestedWeight, 67.5);
    });

    test('PR tie (repeating a previous best) still progresses normally', () {
      final history = [
        entry(now.subtract(const Duration(days: 10)), 60, 8),
        entry(now.subtract(const Duration(days: 3)), 60, 8), // ties the prior best
      ];
      final result = suggestNextSet(
        history: history,
        level: ExperienceLevel.intermediate,
        now: now,
      );
      expect(result.suggestedWeight, 62.5);
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
  });
}
