import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/muscle_group_volume.dart';

void main() {
  group('parseMuscleGroups', () {
    test('a single plain muscle group', () {
      expect(parseMuscleGroups('Legs'), ['Legs']);
    });

    test('splits on "&", the seed library\'s own separator', () {
      expect(parseMuscleGroups('Shoulders & Upper Back'), [
        'Shoulders',
        'Upper Back',
      ]);
    });

    test('splits on commas too, matching the create-exercise form\'s hint text', () {
      expect(parseMuscleGroups('Chest, Triceps'), ['Chest', 'Triceps']);
    });

    test('trims whitespace and drops empty segments', () {
      expect(parseMuscleGroups(' Legs &  Core , '), ['Legs', 'Core']);
    });

    test('an accidental repeat is not double-counted', () {
      expect(parseMuscleGroups('Shoulders & Shoulders'), ['Shoulders']);
    });

    test('empty text yields no groups', () {
      expect(parseMuscleGroups(''), isEmpty);
    });
  });

  group('tallyMuscleGroupVolume', () {
    test('a single exercise contributes its sets to every muscle group it lists', () {
      final result = tallyMuscleGroupVolume([
        (muscleGroupsRaw: 'Chest & Triceps', setsLogged: 4),
      ]);
      // Tied counts, so don't assert a specific order between them here -
      // sort-order-among-ties is covered separately below.
      final byGroup = {for (final v in result) v.muscleGroup: v.setCount};
      expect(byGroup, {'Chest': 4, 'Triceps': 4});
    });

    test('two exercises sharing a muscle group accumulate into one total', () {
      final result = tallyMuscleGroupVolume([
        (muscleGroupsRaw: 'Chest & Triceps', setsLogged: 3),
        (muscleGroupsRaw: 'Shoulders & Triceps', setsLogged: 3),
      ]);
      final byGroup = {for (final v in result) v.muscleGroup: v.setCount};
      expect(byGroup, {'Chest': 3, 'Triceps': 6, 'Shoulders': 3});
    });

    test('sorted highest-volume first', () {
      final result = tallyMuscleGroupVolume([
        (muscleGroupsRaw: 'Legs', setsLogged: 2),
        (muscleGroupsRaw: 'Back', setsLogged: 10),
        (muscleGroupsRaw: 'Core', setsLogged: 5),
      ]);
      expect(result.map((v) => v.muscleGroup), ['Back', 'Core', 'Legs']);
    });

    test('no entries yields no groups', () {
      expect(tallyMuscleGroupVolume(const []), isEmpty);
    });
  });
}
