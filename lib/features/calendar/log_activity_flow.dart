import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database_provider.dart';
import '../../import/gpx_import.dart';
import '../progress/progress_providers.dart';
import '../shared/numeric_input_formatters.dart';
import 'calendar_screen.dart' show adHocActivitiesProvider;

/// A handful of common activities, quick-pickable rather than always typing
/// a name - "Other" still allows any free text.
const _commonActivities = ['Walk', 'Run', 'Bike', 'Swim', 'Yoga', 'Hike'];

enum _LogMethod { manual, gpx }

/// Shows the "Log manually / Import GPX file" choice, then the matching
/// entry flow, and writes the result as an ad-hoc activity - extracted out
/// of `calendar_screen.dart` (which used to own this privately) so both the
/// Calendar tab and the Today dashboard's "Log activity" quick action call
/// the exact same flow rather than maintaining two copies.
Future<void> showLogActivityFlow(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) async {
  final choice = await showModalBottomSheet<_LogMethod>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Log manually'),
            onTap: () => Navigator.of(context).pop(_LogMethod.manual),
          ),
          ListTile(
            leading: const Icon(Icons.route_outlined),
            title: const Text('Import GPX file'),
            subtitle: const Text(
              'From a GPS watch, phone app, or bike computer',
            ),
            onTap: () => Navigator.of(context).pop(_LogMethod.gpx),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case _LogMethod.manual:
      await _logActivity(context, ref, day, initial: null);
    case _LogMethod.gpx:
      await _importGpx(context, ref, day);
  }
}

Future<void> _logActivity(
  BuildContext context,
  WidgetRef ref,
  DateTime day, {
  required _ActivityInput? initial,
}) async {
  final input = await showDialog<_ActivityInput>(
    context: context,
    builder: (context) => _LogActivityDialog(day: day, initial: initial),
  );
  if (input == null) return;

  final db = ref.read(appDatabaseProvider);
  await db.sessionLogDao.createAdHocActivity(
    id: const Uuid().v4(),
    loggedAt: input.day,
    activityName: input.activityName,
    durationSec: input.durationMinutes == null
        ? null
        : input.durationMinutes! * 60,
    distance: input.distanceKm == null ? null : input.distanceKm! * 1000,
    notes: input.notes.isEmpty ? null : input.notes,
  );
  // One-shot FutureProviders - won't notice this write on their own (same
  // gotcha as execution_screen.dart's _finishSession).
  ref.invalidate(adHocActivitiesProvider);
  invalidateProgressProviders(ref);

  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('${input.activityName} logged.')));
}

/// Picks a .gpx file, parses it, and hands the result to the same
/// [_LogActivityDialog] used for manual entry - pre-filled rather than
/// saved straight away, so the user can still name/correct it (a GPX
/// track often has no name at all, or one that doesn't mean anything out
/// of context, e.g. a device's auto-generated "Activity").
Future<void> _importGpx(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['gpx'],
  );
  if (file == null || !context.mounted) return;

  final GpxActivity parsed;
  try {
    parsed = parseGpx(utf8.decode(await file.readAsBytes()));
  } on GpxParseException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }
  if (!context.mounted) return;

  await _logActivity(
    context,
    ref,
    parsed.startTime ?? day,
    initial: _ActivityInput(
      day: parsed.startTime ?? day,
      activityName: parsed.name ?? '',
      durationMinutes: parsed.durationSec == null
          ? null
          : parsed.durationSec! / 60,
      distanceKm: parsed.distanceMeters / 1000,
    ),
  );
}

class _ActivityInput {
  final DateTime day;
  final String activityName;
  final double? durationMinutes;
  final double? distanceKm;
  final String notes;

  const _ActivityInput({
    required this.day,
    required this.activityName,
    this.durationMinutes,
    this.distanceKm,
    this.notes = '',
  });
}

class _LogActivityDialog extends StatefulWidget {
  final DateTime day;
  final _ActivityInput? initial;

  const _LogActivityDialog({required this.day, this.initial});

  @override
  State<_LogActivityDialog> createState() => _LogActivityDialogState();
}

class _LogActivityDialogState extends State<_LogActivityDialog> {
  late final _nameController = TextEditingController(
    text: widget.initial?.activityName ?? '',
  );
  late final _durationController = TextEditingController(
    text: widget.initial?.durationMinutes == null
        ? ''
        : _trimZeros(widget.initial!.durationMinutes!),
  );
  late final _distanceController = TextEditingController(
    text: widget.initial?.distanceKm == null
        ? ''
        : _trimZeros(widget.initial!.distanceKm!),
  );
  final _notesController = TextEditingController();

  /// Pre-filled numbers (e.g. from a parsed GPX file) shouldn't show a
  /// trailing ".0" the user never typed.
  String _trimZeros(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log activity for ${DateFormat.yMMMd().format(widget.day)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final activity in _commonActivities)
                  ActionChip(
                    label: Text(activity),
                    onPressed: () => setState(() {
                      _nameController.text = activity;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'e.g. Walk',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: integerInputFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInputFormatters,
                    decoration: const InputDecoration(labelText: 'Distance (km)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // A plain FilledButton here would only check the controller's text
        // once, at the dialog's first build, then never again - a known
        // gotcha (see CLAUDE.md) with any TextEditingController-derived
        // enabled state.
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) => FilledButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _submit,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      _ActivityInput(
        day: widget.day,
        activityName: _nameController.text.trim(),
        durationMinutes: double.tryParse(_durationController.text.trim()),
        distanceKm: double.tryParse(_distanceController.text.trim()),
        notes: _notesController.text.trim(),
      ),
    );
  }
}
