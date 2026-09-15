import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/plate_calculator.dart';
import '../../logic/units.dart';
import '../settings/app_preferences.dart';
import '../shared/numeric_input_formatters.dart';

/// A starting menu of common plate sizes offered as toggleable chips, beyond
/// whatever `AppPreferences.availablePlatesKg` already has selected - not
/// every gym stocks every standard size (reported live: some skip 25kg
/// entirely, others stock unusual sizes like 40kg), so this is deliberately
/// wider than `standardPlatesKg` itself, which is only the *default
/// selection*, not the full menu of things someone could turn on.
const _commonPlateMenuKg = [50.0, 40.0, 25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25, 0.5];
const _commonPlateMenuLbs = [100.0, 55.0, 45.0, 35.0, 25.0, 10.0, 5.0, 2.5, 1.25];

/// Full-screen entry point, reached from the Exercise Library toolbar - a
/// thin `Scaffold` around [PlateCalculatorForm], which carries the actual
/// logic. See [showPlateCalculatorSheet] for the other entry point (a modal
/// sheet, reached mid-session without leaving [ExecutionScreen]) - both
/// share this exact same form rather than each keeping their own copy.
class PlateCalculatorScreen extends StatelessWidget {
  const PlateCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plate calculator')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PlateCalculatorForm(),
      ),
    );
  }
}

/// Opens the same [PlateCalculatorForm] as a modal bottom sheet - requested
/// directly so a lifter doesn't have to leave an in-progress session (and
/// its rest timer/unsaved sets) just to work out plate math. `isScrollControlled`
/// + `DraggableScrollableSheet` so the sheet can grow tall enough for the
/// form plus an open keyboard without either clipping content or covering
/// the whole screen by default.
Future<void> showPlateCalculatorSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plate calculator',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const PlateCalculatorForm(),
          ],
        ),
      ),
    ),
  );
}

/// Given a target weight and a bar weight, shows which plates to load per
/// side - a standalone utility with no DB/session dependency, reusing
/// [WeightUnit]/[kgToDisplay]/[displayToKg]/[formatWeightNumber] from
/// `lib/logic/units.dart` rather than duplicating conversion math. Which
/// plates are actually available to calculate with is user-editable (see
/// `AppPreferences.availablePlatesKg`/`availablePlatesLbs`) rather than
/// always the fixed standard set - asked for directly, since not every gym
/// has the same plates on hand.
///
/// A plain `Column` rather than a `ListView`/`Scaffold` of its own, so
/// either host (the full screen above, or the bottom sheet) can supply its
/// own scaffolding/scroll behavior around the same form.
class PlateCalculatorForm extends ConsumerStatefulWidget {
  const PlateCalculatorForm({super.key});

  @override
  ConsumerState<PlateCalculatorForm> createState() =>
      _PlateCalculatorFormState();
}

class _PlateCalculatorFormState
    extends ConsumerState<PlateCalculatorForm> {
  late final TextEditingController _targetController;
  late final TextEditingController _barController;
  WeightUnit? _lastSeededUnit;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController();
    _barController = TextEditingController();
  }

  @override
  void dispose() {
    _targetController.dispose();
    _barController.dispose();
    super.dispose();
  }

  void _seedBarWeightIfEmpty(WeightUnit unit) {
    // Only seed once per unit change (and only while the field's still
    // untouched) - a default bar weight is a convenience, not something
    // that should stomp on a value the user already typed.
    if (_lastSeededUnit == unit) return;
    _lastSeededUnit = unit;
    if (_barController.text.trim().isEmpty) {
      _barController.text = formatWeightNumber(
        unit == WeightUnit.lbs ? 45 : 20,
      );
    }
  }

  Future<void> _togglePlate(
    WeightUnit unit,
    List<double> current,
    double size,
    bool selected,
  ) async {
    final updated = selected
        ? [...current, size]
        : current.where((p) => p != size).toList();
    final notifier = ref.read(appPreferencesProvider.notifier);
    if (unit == WeightUnit.lbs) {
      await notifier.setAvailablePlatesLbs(updated);
    } else {
      await notifier.setAvailablePlatesKg(updated);
    }
  }

  Future<void> _addCustomPlate(WeightUnit unit, List<double> current) async {
    final size = await showDialog<double>(
      context: context,
      builder: (context) => _AddPlateDialog(unit: unit),
    );
    if (size == null || size <= 0 || current.contains(size)) return;
    await _togglePlate(unit, current, size, true);
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(appPreferencesProvider).weightUnit;
    _seedBarWeightIfEmpty(unit);
    final unitLabel = unit == WeightUnit.lbs ? 'lbs' : 'kg';
    final availablePlates = unit == WeightUnit.lbs
        ? ref.watch(appPreferencesProvider).availablePlatesLbs
        : ref.watch(appPreferencesProvider).availablePlatesKg;
    final commonMenu = unit == WeightUnit.lbs
        ? _commonPlateMenuLbs
        : _commonPlateMenuKg;
    // Anything selected that isn't part of the common menu (a custom size
    // someone added, e.g. an odd gym-specific 40kg plate) still needs its
    // own chip, or there'd be no way to see it's on, let alone remove it.
    final customSelected = availablePlates
        .where((p) => !commonMenu.contains(p))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final target = double.tryParse(_targetController.text.trim());
    final bar = double.tryParse(_barController.text.trim());
    // calculatePlateLoad's greedy algorithm relies on largest-first order -
    // AppPreferences stores plain unordered edits, so sort right before use
    // rather than trying to keep every mutation pre-sorted.
    final sortedAvailablePlates = [...availablePlates]
      ..sort((a, b) => b.compareTo(a));
    final result = (target != null && bar != null)
        ? calculatePlateLoad(
            targetWeight: target,
            barWeight: bar,
            availablePlates: sortedAvailablePlates,
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: decimalInputFormatters,
            decoration: InputDecoration(
              labelText: 'Target weight ($unitLabel)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _barController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: decimalInputFormatters,
            decoration: InputDecoration(
              labelText: 'Bar weight ($unitLabel)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text(
            'Which plates do you have?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Not every gym has every size - turn off what you don\'t have, '
            'or add one that\'s missing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in commonMenu)
                FilterChip(
                  label: Text('${formatPlateWeight(size)}$unitLabel'),
                  selected: availablePlates.contains(size),
                  onSelected: (selected) => _togglePlate(
                    unit,
                    availablePlates,
                    size,
                    selected,
                  ),
                ),
              for (final size in customSelected)
                InputChip(
                  label: Text('${formatPlateWeight(size)}$unitLabel'),
                  // A custom plate is always "on" the moment it's added -
                  // the only way off is deleting it outright, there's no
                  // separate toggle state the way the common-menu
                  // FilterChips have. Reported live (2026-09-15): without
                  // `selected: true`, this chip renders in InputChip's
                  // plain/unfilled default look, reading as "not chosen"
                  // even though it's already included in every calculation
                  // - the visual state didn't match the actual state.
                  selected: true,
                  onDeleted: () =>
                      _togglePlate(unit, availablePlates, size, false),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add plate'),
                onPressed: () => _addCustomPlate(unit, availablePlates),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (result == null)
            const Text('Enter a target and bar weight to see the plates.')
          else if (availablePlates.isEmpty)
            const Text('Turn on at least one plate size above.')
          else
            _PlateResultCard(result: result, unitLabel: unitLabel),
      ],
    );
  }
}

/// Owns its own controller (disposed in its own `State.dispose()`, once the
/// route is actually removed) rather than one created inline by the caller
/// and disposed right after `showDialog`'s Future resolves - that races the
/// dialog's own exit transition, which keeps rebuilding the same `TextField`
/// for a few frames while it animates out (see `execution_screen.dart`'s
/// `_NotePromptDialog`, the first place this project hit exactly this bug).
class _AddPlateDialog extends StatefulWidget {
  final WeightUnit unit;

  const _AddPlateDialog({required this.unit});

  @override
  State<_AddPlateDialog> createState() => _AddPlateDialogState();
}

class _AddPlateDialogState extends State<_AddPlateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a plate size'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: decimalInputFormatters,
        decoration: InputDecoration(
          labelText: 'Weight (${widget.unit == WeightUnit.lbs ? 'lbs' : 'kg'})',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(double.tryParse(_controller.text.trim())),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _PlateResultCard extends StatelessWidget {
  final PlateLoadResult result;
  final String unitLabel;

  const _PlateResultCard({required this.result, required this.unitLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Per side', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result.platesPerSide.isEmpty)
              const Text('No plates needed - the bar alone is enough.')
            else
              Text(
                result.platesPerSide
                    .map(
                      (p) =>
                          '${formatPlateWeight(p.size)}×${p.count}',
                    )
                    .join(', '),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 16),
            Text(
              'Total: ${formatPlateWeight(result.loadedWeight)}$unitLabel',
            ),
            if (result.shortfall > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Closest reachable with these plates - "
                  '${formatPlateWeight(result.shortfall)}$unitLabel short '
                  'of your target.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
