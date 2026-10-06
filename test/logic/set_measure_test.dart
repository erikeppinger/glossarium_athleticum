import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/set_measure.dart';

void main() {
  group('parseDurationSec', () {
    test('reads seconds, minutes and m:ss', () {
      expect(parseDurationSec('45 sec'), 45);
      expect(parseDurationSec('30s'), 30);
      expect(parseDurationSec('1 min'), 60);
      expect(parseDurationSec('1.5 minutes'), 90);
      expect(parseDurationSec('1:30'), 90);
      expect(parseDurationSec('60 sec each side'), 60);
    });

    test('ignores text that names no duration', () {
      expect(parseDurationSec('8-10'), isNull);
      expect(parseDurationSec('60kg'), isNull);
      expect(parseDurationSec('250m'), isNull);
      expect(parseDurationSec('Bodyweight'), isNull);
    });
  });

  group('parseDistanceMeters', () {
    test('reads metres and kilometres', () {
      expect(parseDistanceMeters('250m'), 250);
      expect(parseDistanceMeters('50 meters'), 50);
      expect(parseDistanceMeters('1.5 km'), 1500);
      expect(parseDistanceMeters('2,5km'), 2500);
    });

    test('does not mistake minutes for metres', () {
      expect(parseDistanceMeters('5 min'), isNull);
      expect(parseDistanceMeters('45 sec'), isNull);
      expect(parseDistanceMeters('60kg'), isNull);
    });
  });

  group('setMeasureFor', () {
    test('a time or distance prescription decides it', () {
      expect(
        setMeasureFor(measurementType: 'Weight x Reps', prescribedWeight: '45 sec'),
        SetMeasure.time,
      );
      expect(
        setMeasureFor(measurementType: 'Weight x Reps', prescribedReps: '30 sec'),
        SetMeasure.time,
      );
      expect(
        setMeasureFor(measurementType: '', prescribedWeight: '250m'),
        SetMeasure.distance,
      );
    });

    test('otherwise the measurement type does', () {
      expect(setMeasureFor(measurementType: 'Time'), SetMeasure.time);
      expect(setMeasureFor(measurementType: 'Distance'), SetMeasure.distance);
      expect(setMeasureFor(measurementType: 'Distance or Time'), SetMeasure.distance);
      expect(setMeasureFor(measurementType: 'Weight x Reps'), SetMeasure.reps);
      expect(setMeasureFor(measurementType: 'Time or Reps'), SetMeasure.reps);
      expect(setMeasureFor(measurementType: 'Max Load or Time'), SetMeasure.reps);
      expect(setMeasureFor(measurementType: ''), SetMeasure.reps);
    });

    test('a tempo or pause cue inside a rep prescription stays reps', () {
      expect(
        setMeasureFor(
          measurementType: 'Weight x Reps',
          prescribedReps: '8',
          prescribedWeight: '60kg, 3s eccentric',
        ),
        SetMeasure.reps,
      );
      expect(
        setMeasureFor(
          measurementType: 'Weight x Reps',
          prescribedReps: '8 (2 sec pause)',
          prescribedWeight: '60kg',
        ),
        SetMeasure.reps,
      );
      expect(
        setMeasureFor(
          measurementType: 'Weight x Reps',
          prescribedReps: '5',
          prescribedWeight: '100kg, 2m rest',
        ),
        SetMeasure.reps,
      );
    });

    test('a hold qualified with "each side" is still a hold', () {
      expect(
        setMeasureFor(
          measurementType: 'Weight x Reps',
          prescribedReps: '1',
          prescribedWeight: '60 sec each side',
        ),
        SetMeasure.time,
      );
    });

    test('a carry with a load and a distance is a distance set', () {
      expect(
        setMeasureFor(
          measurementType: 'Distance or Time',
          prescribedReps: '50m',
          prescribedWeight: '60kg',
        ),
        SetMeasure.distance,
      );
    });

    test('a normal rep prescription keeps a timed type timed', () {
      expect(
        setMeasureFor(measurementType: 'Time', prescribedReps: '3'),
        SetMeasure.time,
      );
    });
  });

  test('prescribedAmount pre-fills the right number', () {
    expect(
      prescribedAmount(SetMeasure.time, prescribedReps: '1', prescribedWeight: '45 sec'),
      45,
    );
    expect(prescribedAmount(SetMeasure.distance, prescribedWeight: '1 km'), 1000);
    expect(prescribedAmount(SetMeasure.reps, prescribedWeight: '45 sec'), isNull);
    expect(prescribedAmount(SetMeasure.time, prescribedReps: '3'), isNull);
  });

  test('formatting', () {
    expect(formatSetDuration(45), '45s');
    expect(formatSetDuration(60), '1 min');
    expect(formatSetDuration(90), '1:30 min');
    expect(formatSetDistance(250), '250 m');
    expect(formatSetDistance(1500), '1.5 km');
  });
}
