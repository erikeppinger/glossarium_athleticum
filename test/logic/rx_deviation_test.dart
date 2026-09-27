import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/logic/rx_deviation.dart';

PlanExercise _rx({
  int sets = 4,
  String reps = '8',
  String weightIntensity = '40kg',
}) {
  return PlanExercise(
    id: 1,
    sessionId: 1,
    order: 1,
    exerciseId: 'ex-1',
    exerciseName: 'Bench Press',
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    notes: '',
    videoUrl: '',
    embeddingAllowed: false,
  );
}

LoggedSet _set({
  int setNumber = 1,
  int? reps,
  double? weight,
  double? rpe,
  String? notes,
}) {
  return LoggedSet(
    id: setNumber,
    sessionLogId: 'log-1',
    exerciseId: 'ex-1',
    setNumber: setNumber,
    reps: reps,
    weight: weight,
    rpe: rpe,
    isPr: false,
    notes: notes,
  );
}

void main() {
  group('computeRxDeviations', () {
    test('an exercise done exactly as prescribed has no flags', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 3, reps: '8', weightIntensity: '40kg'),
        actual: [
          _set(setNumber: 1, reps: 8, weight: 40),
          _set(setNumber: 2, reps: 8, weight: 40),
          _set(setNumber: 3, reps: 8, weight: 40),
        ],
      );
      expect(flags, isEmpty);
    });

    test('no prescription (ad-hoc mid-session addition) never flags', () {
      final flags = computeRxDeviations(
        prescription: null,
        actual: [_set(reps: 5)],
      );
      expect(flags, isEmpty);
    });

    test('fewer sets than prescribed is flagged', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 4),
        actual: [_set(setNumber: 1, reps: 8, weight: 40)],
      );
      expect(flags.map((f) => f.kind), contains(RxDeviationKind.fewerSets));
      expect(flags.first.label, '1 of 4 sets logged');
    });

    test('reps below target on a set is flagged, matching sets are not', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 2, reps: '8'),
        actual: [
          _set(setNumber: 1, reps: 8, weight: 40),
          _set(setNumber: 2, reps: 6, weight: 40),
        ],
      );
      expect(
        flags.where((f) => f.kind == RxDeviationKind.belowTarget).map((f) => f.label),
        contains('Under rep target on 1 set'),
      );
    });

    test('weight below a confidently-parsed kg target is flagged', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1, weightIntensity: '40kg'),
        actual: [_set(reps: 8, weight: 35)],
      );
      expect(
        flags.where((f) => f.kind == RxDeviationKind.belowTarget).map((f) => f.label),
        contains('Under weight target on 1 set'),
      );
    });

    test('a percentage prescription is never compared as a raw kg number', () {
      // "70%" resolves to some real kg figure at logging time via the
      // percentage-prescription machinery, but the *prescription text*
      // itself is "70%" - comparing 70 directly against a logged weight in
      // kg would be comparing incompatible units and could easily produce a
      // false "under target" flag.
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1, weightIntensity: '70%'),
        actual: [_set(reps: 8, weight: 45)],
      );
      expect(flags.where((f) => f.kind == RxDeviationKind.belowTarget), isEmpty);
    });

    test('a bodyweight/no-weight exercise is never flagged for weight', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1, weightIntensity: 'Bodyweight'),
        actual: [_set(reps: 15, weight: null)],
      );
      expect(flags.where((f) => f.kind == RxDeviationKind.belowTarget), isEmpty);
    });

    test('a time/distance exercise is never flagged for reps', () {
      // Prescription text is a placeholder like "1" for a duration/distance
      // exercise - the logged sets have null reps, which must never be
      // compared against that placeholder number.
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1, reps: '1', weightIntensity: '60 sec'),
        actual: [_set(reps: null, weight: null)],
      );
      expect(flags, isEmpty);
    });

    test('a near-failure RPE is flagged', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1),
        actual: [_set(reps: 8, weight: 40, rpe: 9.5)],
      );
      expect(flags.map((f) => f.kind), contains(RxDeviationKind.nearFailure));
    });

    test('a trainee note is surfaced as its own flag regardless of the rest', () {
      final flags = computeRxDeviations(
        prescription: _rx(sets: 1),
        actual: [_set(reps: 8, weight: 40, notes: 'Left shoulder felt off')],
        noteText: 'Left shoulder felt off',
      );
      expect(
        flags.where((f) => f.kind == RxDeviationKind.hasNote).map((f) => f.label),
        contains('Left shoulder felt off'),
      );
    });
  });

  group('leadingNumber', () {
    test('reads the first plain number out of free text', () {
      expect(leadingNumber('10 each leg'), 10);
      expect(leadingNumber('1'), 1);
      expect(leadingNumber('no number here'), isNull);
    });
  });

  group('parsePrescribedWeightKg', () {
    test('reads a confident "Nkg" figure', () {
      expect(parsePrescribedWeightKg('40kg'), 40);
      expect(parsePrescribedWeightKg('40.5 kg'), 40.5);
    });

    test('declines to guess for anything else', () {
      expect(parsePrescribedWeightKg('70%'), isNull);
      expect(parsePrescribedWeightKg('RPE 8'), isNull);
      expect(parsePrescribedWeightKg('Bodyweight'), isNull);
      expect(parsePrescribedWeightKg('250m'), isNull);
    });
  });
}
