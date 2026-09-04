import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/muscle_group_colors.dart';
import 'app_preferences.dart';

/// Palette picker showing each option's actual swatches rather than just its
/// name - the whole point of the colour-vision-deficiency options is that
/// only the person choosing can tell which one they can separate, so the
/// choice has to be made by looking, not by reading a label.
class ColorPaletteScreen extends ConsumerWidget {
  const ColorPaletteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appPreferencesProvider).colorPalette;

    return Scaffold(
      appBar: AppBar(title: const Text('Colour palette')),
      body: ListView(
        // The last palette card was getting covered by the Android system
        // navigation bar (gesture bar / 3-button nav) - a plain fixed bottom
        // padding doesn't account for that inset, since Scaffold draws
        // content edge-to-edge behind system bars by default. Add the
        // bar's actual height on top of the usual padding instead of
        // guessing a fixed extra amount.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Muscle areas are colour-coded across the exercise library, plans, '
            'and sessions. Pick whichever set you can tell apart most easily - '
            'the area name is always shown as text too, so nothing is hidden '
            'if two colours look alike to you.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final palette in AppColorPalette.values) ...[
            _PaletteCard(
              palette: palette,
              selected: palette == selected,
              onSelected: () => ref
                  .read(appPreferencesProvider.notifier)
                  .setColorPalette(palette),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final AppColorPalette palette;
  final bool selected;
  final VoidCallback onSelected;

  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      palette.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                palette.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Every area, labelled - so the preview is the real thing the
              // user will be reading, not an abstract colour strip.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final area in MuscleArea.values)
                    _Swatch(
                      color: colorForArea(area, palette),
                      label: area.label,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;

  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    // Pick the text colour by contrast so labels stay readable on both the
    // pale pastel swatches and the near-black monochrome ones.
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: onColor),
      ),
    );
  }
}
