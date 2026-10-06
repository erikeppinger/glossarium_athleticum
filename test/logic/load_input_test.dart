import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/load_input.dart';

void main() {
  LoadInput of(
    String equipment,
    String category,
    String measurementType, {
    String prescribedWeight = '',
  }) => loadInputFor(
    equipment: equipment,
    category: category,
    measurementType: measurementType,
    prescribedWeight: prescribedWeight,
  );

  test('loaded equipment keeps a normal weight field', () {
    expect(of('Barbell', 'Main Lift', 'Weight x Reps'), LoadInput.weight);
    expect(of('Dumbbell', 'Accessory', 'Weight x Reps'), LoadInput.weight);
    expect(of('Handles', 'Grip & Core', 'Time'), LoadInput.weight);
  });

  test('bodyweight warm-ups get no weight field, whatever the measurement', () {
    // Real data: warm-ups often carry the generic "Weight x Reps".
    expect(of('None (Bodyweight)', 'Warm-up', 'Weight x Reps'), LoadInput.none);
    expect(of('None (Bodyweight)', 'Mobility', 'Reps'), LoadInput.none);
    expect(of('Bodyweight', 'Stretching', 'Weight x Reps'), LoadInput.none);
  });

  test('bodyweight timed or distance work gets no weight field', () {
    expect(of('None (Bodyweight)', 'Core', 'Time'), LoadInput.none);
    expect(of('None (Bodyweight)', 'Conditioning', 'Distance'), LoadInput.none);
  });

  test('other bodyweight exercises get the optional added-weight field', () {
    expect(of('None (Bodyweight)', 'Bodyweight', 'Weight x Reps'),
        LoadInput.addedWeight);
    expect(of('None (Bodyweight)', 'Accessory', 'Reps'), LoadInput.addedWeight);
  });

  test('cardio for time or distance has no weight field, whatever the kit', () {
    expect(of('Jump Rope', 'Cardio', 'Time'), LoadInput.none);
    expect(of('Rowing Machine', 'Cardio', 'Distance'), LoadInput.none);
    expect(of('Battle Ropes', 'Cardio', 'Time', prescribedWeight: '30 sec'),
        LoadInput.none);
    // ...unless the plan names a load, or the type is load-based.
    expect(of('Weight Vest', 'Cardio', 'Distance', prescribedWeight: '10kg'),
        LoadInput.weight);
    expect(of('Kettlebell', 'Cardio', 'Weight x Reps'), LoadInput.weight);
    // Sled/carry work isn't "Cardio" and keeps its field.
    expect(of('Sled', 'Conditioning', 'Distance or Time'), LoadInput.weight);
  });

  test('a bodyweight warm-up prescribed with a load keeps a weight field', () {
    // A trainer's "Bodyweight Squat @ 10kg" (vest) must not hide the field
    // while its pre-filled 10 gets saved unseen.
    expect(
      of('None (Bodyweight)', 'Warm-up', 'Weight x Reps',
          prescribedWeight: '10kg'),
      LoadInput.addedWeight,
    );
  });

  test('a "Bodyweight" prescription counts when equipment is blank', () {
    // Custom exercises created during a plan import have no equipment.
    expect(of('', 'Custom', 'Weight x Reps', prescribedWeight: 'Bodyweight'),
        LoadInput.addedWeight);
    expect(of('', 'Custom', 'Weight x Reps', prescribedWeight: 'BW'),
        LoadInput.addedWeight);
    expect(of('', 'Warm-up', 'Weight x Reps', prescribedWeight: 'bodyweight'),
        LoadInput.none);
    expect(of('', 'Custom', 'Weight x Reps'), LoadInput.weight);
    expect(of('', 'Custom', 'Weight x Reps', prescribedWeight: '60kg'),
        LoadInput.weight);
  });
}
