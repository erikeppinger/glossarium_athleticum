import 'package:flutter/material.dart';

import '../../logic/muscle_group_colors.dart';

/// A short vertical colour bar marking an exercise's muscle area. Used as a
/// `ListTile.leading` in the exercise library, plan detail, and execution
/// screens so the same area is the same colour everywhere.
///
/// Deliberately a stripe rather than a filled row or a coloured text style:
/// it survives both light and dark themes without contrast problems, and it
/// never competes with the text next to it.
class MuscleAreaStripe extends StatelessWidget {
  final MuscleArea area;
  final AppColorPalette palette;
  final double height;

  const MuscleAreaStripe({
    super.key,
    required this.area,
    required this.palette,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${area.label} exercise',
      child: Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(
          color: colorForArea(area, palette),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// A second, independent colour bar naming who an exercise came from -
/// library / own / imported-from-a-plan / credited-to-an-author. Meant to
/// sit right next to [MuscleAreaStripe]: the two answer different questions
/// (what does this train vs who made it) and shouldn't be conflated into one
/// bar's colour.
class ProvenanceStripe extends StatelessWidget {
  final ExerciseProvenance provenance;
  final double height;

  const ProvenanceStripe({
    super.key,
    required this.provenance,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: provenance.label,
      child: Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(
          color: colorForProvenance(provenance),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// A small filled chip naming the muscle area, for places with room for a
/// label - the colour is redundant with the text, never a substitute.
class MuscleAreaChip extends StatelessWidget {
  final MuscleArea area;
  final AppColorPalette palette;

  const MuscleAreaChip({
    super.key,
    required this.area,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForArea(area, palette);
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        area.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: onColor),
      ),
    );
  }
}
