import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/seed/exercise_seed_loader.dart';

const _sampleCsv = '''
Exercise ID,Exercise Name,Category,Movement Pattern,Muscle Group(s),Equipment,Difficulty,Measurement Type,Description / Cues,Safety Notes,Video Reference
EX001,Band Pull-Apart,Warm-up,Mobility,Shoulders & Upper Back,Resistance Band,Beginner,Weight x Reps,"Light activation, 2-3 sets of 15-20.","Keep elbows soft, avoid shrugging.",https://example.com/1
EX002,Hip Circles,Warm-up,Mobility,Hips & Glutes,None (Bodyweight),Beginner,Time,Dynamic hip mobility.,Move within a pain-free range.,https://example.com/2
,,,,,,,,,,
''';

void main() {
  test('parses each data row into a companion with the right fields', () {
    final entries = parseExerciseSeedCsv(_sampleCsv);
    expect(entries, hasLength(2));

    final first = entries[0];
    expect(first.id.value, 'EX001');
    expect(first.name.value, 'Band Pull-Apart');
    expect(first.category.value, 'Warm-up');
    expect(first.measurementType.value, 'Weight x Reps');
    expect(first.isCustom.value, false);
  });

  test('splits "&"-joined muscle groups into a normalized comma list', () {
    final entries = parseExerciseSeedCsv(_sampleCsv);
    expect(entries[0].muscleGroups.value, 'Shoulders, Upper Back');
    expect(entries[1].muscleGroups.value, 'Hips, Glutes');
  });

  test('skips fully blank rows', () {
    final entries = parseExerciseSeedCsv(_sampleCsv);
    expect(entries.map((e) => e.id.value), ['EX001', 'EX002']);
  });

  test('empty file (header only) yields no entries', () {
    const headerOnly =
        'Exercise ID,Exercise Name,Category,Movement Pattern,Muscle Group(s),Equipment,Difficulty,Measurement Type,Description / Cues,Safety Notes,Video Reference\n';
    expect(parseExerciseSeedCsv(headerOnly), isEmpty);
  });
}
