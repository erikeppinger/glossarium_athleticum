import 'package:flutter/material.dart';

import '../../data/daos/plan_dao.dart';
import '../shared/numeric_input_formatters.dart';

/// The sets/reps/weight/rest/notes fields for prescribing one exercise
/// within a plan session - shared by `add_exercise_to_plan_screen.dart`,
/// `plan_builder_screen.dart`, and adding an exercise to an existing
/// session from `edit_session_screen.dart`, which all need exactly the
/// same small form. The caller owns the controllers (same pattern every
/// other form in this app already uses - see `add_exercise_to_plan_screen.dart`
/// itself, or `create_exercise_screen.dart`), typically wrapping the
/// [ExercisePrescriptionFields] widget in a `ListenableBuilder` if a submit
/// button's enabled state depends on [ExercisePrescriptionControllers.isValid].
class ExercisePrescriptionControllers {
  final sets = TextEditingController(text: '3');
  final reps = TextEditingController(text: '8-10');
  final weight = TextEditingController();
  final rest = TextEditingController(text: '90');
  final notes = TextEditingController();

  late final all = [sets, reps, weight, rest, notes];

  bool get isValid =>
      int.tryParse(sets.text.trim()) != null && reps.text.trim().isNotEmpty;

  PlanExerciseInput toInput({
    required int order,
    required String? exerciseId,
    required String exerciseName,
  }) => PlanExerciseInput(
    order: order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: int.parse(sets.text.trim()),
    reps: reps.text.trim(),
    weightIntensity: weight.text.trim(),
    restSec: int.tryParse(rest.text.trim()),
    notes: notes.text.trim(),
  );

  void dispose() {
    for (final controller in all) {
      controller.dispose();
    }
  }
}

class ExercisePrescriptionFields extends StatelessWidget {
  final ExercisePrescriptionControllers controllers;

  const ExercisePrescriptionFields({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers.sets,
                keyboardType: TextInputType.number,
                inputFormatters: integerInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers.reps,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  hintText: 'e.g. 8-10',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers.weight,
                decoration: const InputDecoration(
                  labelText: 'Weight/Intensity',
                  hintText: 'e.g. 60kg',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers.rest,
                keyboardType: TextInputType.number,
                inputFormatters: integerInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Rest (sec)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controllers.notes,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

/// A dialog wrapping [ExercisePrescriptionFields] for "I just picked an
/// exercise from the library, now fill in sets/reps/etc." - shared by
/// `plan_builder_screen.dart` (building a new plan) and
/// `edit_session_screen.dart` (adding an exercise to an existing one).
/// Owns and disposes its own controllers.
class PrescribeExerciseDialog extends StatefulWidget {
  final String exerciseName;
  final String? exerciseId;

  const PrescribeExerciseDialog({
    super.key,
    required this.exerciseName,
    required this.exerciseId,
  });

  @override
  State<PrescribeExerciseDialog> createState() =>
      _PrescribeExerciseDialogState();
}

class _PrescribeExerciseDialogState extends State<PrescribeExerciseDialog> {
  final _controllers = ExercisePrescriptionControllers();

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exerciseName),
      content: SingleChildScrollView(
        child: ExercisePrescriptionFields(controllers: _controllers),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_controllers.isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sets must be a number, and reps is required.'),
                ),
              );
              return;
            }
            Navigator.of(context).pop(
              _controllers.toInput(
                order: 0, // renumbered by the caller once it's saved
                exerciseId: widget.exerciseId,
                exerciseName: widget.exerciseName,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
