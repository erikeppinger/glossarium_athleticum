import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../logic/units.dart';
import '../settings/app_preferences.dart';
import '../shared/app_date_picker.dart';
import '../shared/numeric_input_formatters.dart';
import '../shared/screen_padding.dart';

final bodyMeasurementsProvider = FutureProvider<List<BodyMeasurement>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.bodyMeasurementDao.getAll();
});

/// Bodyweight and circumference tracking - the trainee's body over time,
/// as opposed to the per-exercise performance history in `history_screen.dart`.
class BodyMeasurementsScreen extends ConsumerWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    final unit = ref.watch(appPreferencesProvider).weightUnit;

    return Scaffold(
      appBar: AppBar(title: const Text('Body measurements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _record(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
      body: measurementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (measurements) {
          if (measurements.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No measurements yet.\nTap Record to log your first one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Newest-first from the DAO; the chart wants oldest-first.
          final withWeight = [
            for (final m in measurements.reversed)
              if (m.weightKg != null) m,
          ];

          return ListView(
            padding: screenListPadding(context),
            children: [
              if (withWeight.length >= 2) ...[
                Text(
                  'Bodyweight over time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _WeightChart(measurements: withWeight, unit: unit),
                ),
                const SizedBox(height: 24),
              ],
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              for (final m in measurements)
                _MeasurementTile(
                  measurement: m,
                  unit: unit,
                  onEdit: () => _record(context, ref, m),
                  onDelete: () => _delete(context, ref, m),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement? existing,
  ) async {
    final unit = ref.read(appPreferencesProvider).weightUnit;
    final weekStart = ref.read(appPreferencesProvider).weekStart;
    final result = await showDialog<_MeasurementInput>(
      context: context,
      builder: (context) => _RecordMeasurementDialog(
        existing: existing,
        unit: unit,
        weekStart: weekStart,
      ),
    );
    if (result == null) return;

    final db = ref.read(appDatabaseProvider);
    await db.bodyMeasurementDao.upsert(
      id: existing?.id ?? const Uuid().v4(),
      measuredAt: result.measuredAt,
      weightKg: result.weightKg,
      bodyFatPercent: result.bodyFatPercent,
      chestCm: result.chestCm,
      waistCm: result.waistCm,
      hipsCm: result.hipsCm,
      thighCm: result.thighCm,
      armCm: result.armCm,
      notes: result.notes,
    );
    ref.invalidate(bodyMeasurementsProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete measurement?'),
        content: Text(
          'Delete the entry from ${DateFormat.yMMMd().format(m.measuredAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(appDatabaseProvider);
    await db.bodyMeasurementDao.deleteMeasurement(m.id);
    ref.invalidate(bodyMeasurementsProvider);
  }
}

class _WeightChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final WeightUnit unit;

  const _WeightChart({required this.measurements, required this.unit});

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final m in measurements) kgToDisplay(m.weightKg!, unit),
    ];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Bodyweight moves in a narrow band, so a 0-based axis would flatten the
    // line into uselessness - pad around the actual range instead.
    final pad = ((maxValue - minValue) * 0.25).clamp(1.0, double.infinity);

    // The list of individual entries is rendered separately below this
    // chart (see _MeasurementTile), but fl_chart itself has no text
    // alternative, so a screen reader would otherwise get nothing at all
    // from this specific widget. minValue/maxValue are already in display
    // units (derived from `values` above), unlike the raw kg on the DB row -
    // formatWeightNumber (no further conversion) is the correct formatter here.
    final unitLabel = unit == WeightUnit.lbs ? 'lbs' : 'kg';
    final summary =
        'Weight over time chart. Latest: '
        '${formatWeightInUnit(measurements.last.weightKg!, unit)}. '
        'Range: ${formatWeightNumber(minValue)} to '
        '${formatWeightNumber(maxValue)} $unitLabel.';

    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: LineChart(
          LineChartData(
            minY: minValue - pad,
            maxY: maxValue + pad,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 44),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: false,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final BodyMeasurement measurement;
  final WeightUnit unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeasurementTile({
    required this.measurement,
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String len(double cm) => formatLengthInUnit(cm, unit);
    final parts = <String>[
      if (measurement.weightKg != null)
        formatWeightInUnit(measurement.weightKg!, unit),
      if (measurement.bodyFatPercent != null)
        '${measurement.bodyFatPercent}% bf',
      if (measurement.chestCm != null) 'chest ${len(measurement.chestCm!)}',
      if (measurement.waistCm != null) 'waist ${len(measurement.waistCm!)}',
      if (measurement.hipsCm != null) 'hips ${len(measurement.hipsCm!)}',
      if (measurement.thighCm != null) 'thigh ${len(measurement.thighCm!)}',
      if (measurement.armCm != null) 'arm ${len(measurement.armCm!)}',
    ];

    return ListTile(
      title: Text(DateFormat.yMMMd().format(measurement.measuredAt)),
      subtitle: Text(
        [
          if (parts.isNotEmpty) parts.join(' • '),
          if (measurement.notes.isNotEmpty) measurement.notes,
        ].join('\n'),
      ),
      onTap: onEdit,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
    );
  }
}

class _MeasurementInput {
  final DateTime measuredAt;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? thighCm;
  final double? armCm;
  final String notes;

  const _MeasurementInput({
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.thighCm,
    this.armCm,
    this.notes = '',
  });
}

class _RecordMeasurementDialog extends StatefulWidget {
  final BodyMeasurement? existing;
  final WeightUnit unit;
  final WeekStart weekStart;

  const _RecordMeasurementDialog({
    required this.existing,
    required this.unit,
    required this.weekStart,
  });

  @override
  State<_RecordMeasurementDialog> createState() =>
      _RecordMeasurementDialogState();
}

class _RecordMeasurementDialogState extends State<_RecordMeasurementDialog> {
  late DateTime _date = widget.existing?.measuredAt ?? DateTime.now();

  late final _weightController = TextEditingController(
    text: widget.existing?.weightKg == null
        ? ''
        : formatWeightNumber(
            kgToDisplay(widget.existing!.weightKg!, widget.unit),
          ),
  );
  late final _bodyFatController = _numController(
    widget.existing?.bodyFatPercent,
  );
  // Lengths are stored in cm but shown in the user's unit, same as weights.
  late final _chestController = _lengthController(widget.existing?.chestCm);
  late final _waistController = _lengthController(widget.existing?.waistCm);
  late final _hipsController = _lengthController(widget.existing?.hipsCm);
  late final _thighController = _lengthController(widget.existing?.thighCm);
  late final _armController = _lengthController(widget.existing?.armCm);

  TextEditingController _lengthController(double? cm) => TextEditingController(
    text: cm == null ? '' : formatWeightNumber(cmToDisplay(cm, widget.unit)),
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes ?? '',
  );

  static TextEditingController _numController(double? value) =>
      TextEditingController(
        text: value == null ? '' : formatWeightNumber(value),
      );

  late final _controllers = [
    _weightController,
    _bodyFatController,
    _chestController,
    _waistController,
    _hipsController,
    _thighController,
    _armController,
    _notesController,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// At least one actual measurement - an entry with only a date recorded
  /// would just be noise in the history list.
  bool get _canSave =>
      _controllers.take(7).any((c) => double.tryParse(c.text.trim()) != null);

  @override
  Widget build(BuildContext context) {
    final weightLabel = widget.unit == WeightUnit.lbs
        ? 'Bodyweight (lbs)'
        : 'Bodyweight (kg)';

    return AlertDialog(
      title: const Text('Record measurement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat.yMMMd().format(_date)),
              onTap: _pickDate,
            ),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimalInputFormatters,
              decoration: InputDecoration(labelText: weightLabel),
            ),
            TextField(
              controller: _bodyFatController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimalInputFormatters,
              decoration: const InputDecoration(labelText: 'Body fat (%)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Circumferences (${lengthUnitLabel(widget.unit)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(child: _cmField(_chestController, 'Chest')),
                const SizedBox(width: 8),
                Expanded(child: _cmField(_waistController, 'Waist')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _cmField(_hipsController, 'Hips')),
                const SizedBox(width: 8),
                Expanded(child: _cmField(_thighController, 'Thigh')),
              ],
            ),
            _cmField(_armController, 'Arm'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: Listenable.merge(_controllers),
          builder: (context, _) => FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _cmField(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: decimalInputFormatters,
    decoration: InputDecoration(labelText: label),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      weekStart: widget.weekStart,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim());

  /// Reads a length field back into centimetres for storage.
  double? _parseLength(TextEditingController c) {
    final typed = _parse(c);
    return typed == null ? null : displayToCm(typed, widget.unit);
  }

  void _save() {
    final typedWeight = _parse(_weightController);
    Navigator.of(context).pop(
      _MeasurementInput(
        measuredAt: _date,
        // Bodyweight is entered in the user's display unit but stored in kg,
        // matching how logged sets are handled.
        weightKg: typedWeight == null
            ? null
            : displayToKg(typedWeight, widget.unit),
        bodyFatPercent: _parse(_bodyFatController),
        chestCm: _parseLength(_chestController),
        waistCm: _parseLength(_waistController),
        hipsCm: _parseLength(_hipsController),
        thighCm: _parseLength(_thighController),
        armCm: _parseLength(_armController),
        notes: _notesController.text.trim(),
      ),
    );
  }
}
