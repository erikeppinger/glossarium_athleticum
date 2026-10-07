import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../export/plan_export.dart';
import '../../security/backup_encryption.dart';
import '../calendar/calendar_screen.dart';
import '../execution/start_session_helper.dart';
import '../notifications/reminder_coordinator.dart';
import '../settings/app_preferences.dart';
import '../settings/backup_dialogs.dart';
import '../shared/app_date_picker.dart';
import '../../logic/week_label.dart';
import '../shared/numeric_input_formatters.dart';
import 'edit_session_screen.dart';
import 'plan_providers.dart';

/// A session card's exercise list used to just join every exercise name with
/// ", " - fine for a handful of exercises, but a plan with dozens (e.g. an
/// imported spreadsheet with one row per exercise) turned the subtitle into
/// an unreadable wall of text spanning many lines. Capped to the first few
/// names plus a "+N more" count instead.
String _exerciseSummary(List<PlanExercise> exercises) {
  const shown = 3;
  if (exercises.length <= shown) {
    return exercises.map((e) => e.exerciseName).join(', ');
  }
  final names = exercises.take(shown).map((e) => e.exerciseName).join(', ');
  return '$names, +${exercises.length - shown} more';
}

class PlanDetailScreen extends ConsumerStatefulWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  String get planId => widget.planId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Matches a session on its name, day, week, or any exercise it contains -
  /// a 30+ session plan is otherwise a long flat scroll.
  bool _matches(PlanSessionDetails session) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (session.session.sessionName.toLowerCase().contains(q)) return true;
    if (session.session.day.toLowerCase().contains(q)) return true;
    if ('week ${session.session.weekNumber}'.contains(q)) return true;
    return session.exercises.any(
      (e) => e.exerciseName.toLowerCase().contains(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(planDetailsProvider(planId));
    final dateFormat = DateFormat.yMMMd();
    final loadedDetails = detailsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          if (loadedDetails != null)
            PopupMenuButton<_PlanExportAction>(
              icon: const Icon(Icons.share),
              onSelected: (action) =>
                  _handleExportAction(context, loadedDetails, action),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PlanExportAction.shareCsv,
                  child: Text('Share as spreadsheet (.csv)'),
                ),
                PopupMenuItem(
                  value: _PlanExportAction.shareJson,
                  child: Text('Share as plan file (.json)'),
                ),
                PopupMenuItem(
                  value: _PlanExportAction.shareJsonEncrypted,
                  child: Text('Share as encrypted plan file (.tplan)'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _PlanExportAction.saveCsv,
                  child: Text('Save as spreadsheet (.csv)'),
                ),
                PopupMenuItem(
                  value: _PlanExportAction.saveJson,
                  child: Text('Save as plan file (.json)'),
                ),
                PopupMenuItem(
                  value: _PlanExportAction.saveJsonEncrypted,
                  child: Text('Save as encrypted plan file (.tplan)'),
                ),
              ],
            ),
        ],
      ),
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Plan not found.'));
          }
          final visible = details.sessions.where(_matches).toList();
          final showWeek = showsWeekNumber(
            details.sessions.map((s) => s.session.weekNumber),
          );
          return ListView(
            // Android draws this body behind the navigation bar; without the
            // inset, the last session card's buttons sit underneath it.
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(details.plan.name, style: Theme.of(context).textTheme.headlineSmall),
              // Purely free text (see Plans.createdBy's own doc comment) -
              // shown right under the title so it's clear at a glance whose
              // plan this is once it's been handed off as a file and
              // imported onto someone else's device.
              if (details.plan.createdBy?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'by ${details.plan.createdBy}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (details.plan.archivedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Archived',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              // A readable home for the plan's own notes (edited via the
              // plan list's "⋮ > Notes" action) - previously the only places
              // this text ever showed were a one-line list-row preview and
              // the action sheet itself, never anywhere meant for actually
              // reading it.
              if (details.plan.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Notes',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(details.plan.notes),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Only worth the space once a plan is long enough to scroll.
              if (details.sessions.length >= 8)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search sessions or exercises',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No sessions match that search.')),
                ),
              for (final session in visible)
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          joinSessionLabel([
                            if (showWeek)
                              'Week ${session.session.weekNumber}',
                            // "Any" is the internal placeholder for a session
                            // with no fixed weekday; showing it reads as
                            // though the user chose it.
                            if (session.session.day != 'Any')
                              session.session.day,
                            session.session.sessionName,
                          ]),
                        ),
                        subtitle: Text(
                          _exerciseSummary(session.exercises),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // One chip per scheduled date, each independently
                      // startable/movable/removable - a session can now sit
                      // on several dates at once rather than just one.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (session.dates.isEmpty)
                              Text(
                                'Not scheduled',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            for (final date in session.dates)
                              InputChip(
                                avatar: const Icon(
                                  Icons.play_arrow,
                                  size: 18,
                                ),
                                label: Text(dateFormat.format(date)),
                                onPressed: () =>
                                    startSessionWithMoveToTodayPrompt(
                                      context,
                                      ref,
                                      session.session,
                                      date,
                                    ),
                                deleteIcon: const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                ),
                                onDeleted: () => _showDateActions(
                                  context,
                                  ref,
                                  session.session,
                                  date,
                                ),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add date'),
                              onPressed: () =>
                                  _addDate(context, ref, session.session),
                            ),
                          ],
                        ),
                      ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.repeat),
                            tooltip: 'Duplicate to other weeks',
                            onPressed: () => _duplicateToWeeks(
                              context,
                              ref,
                              session.session,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit session',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditSessionScreen(
                                  sessionId: session.session.id,
                                  planId: planId,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Clones this session's exercises into new sessions at each week in a
  /// range - so a block that repeats across a program's weeks (e.g. the
  /// same "Push Day" every week for 6 weeks) doesn't have to be re-entered
  /// by hand for every repeat.
  Future<void> _duplicateToWeeks(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
  ) async {
    final range = await showDialog<(int, int)>(
      context: context,
      builder: (context) => _WeekRangeDialog(startWeek: session.weekNumber + 1),
    );
    if (range == null) return;
    final (from, to) = range;
    final weeks = [for (var w = from; w <= to; w++) w];

    final db = ref.read(appDatabaseProvider);
    final result = await db.planDao.duplicateSessionToWeeks(
      sessionId: session.id,
      weekNumbers: weeks,
    );
    if (!context.mounted) return;
    ref.invalidate(planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);

    final message = result.skipped == 0
        ? 'Duplicated to ${result.added} week(s).'
        : 'Duplicated to ${result.added} week(s) - skipped ${result.skipped} '
              'that already had this session.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addDate(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
  ) async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      weekStart: ref.read(appPreferencesProvider).weekStart,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.addSessionDate(session.id, picked);
    if (!context.mounted) return;
    ref.invalidate(planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
    // What's scheduled changed, so any pending workout reminders are stale.
    await resyncReminders(ref);
  }

  Future<void> _moveDate(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
    DateTime from,
  ) async {
    final picked = await showAppDatePicker(
      context: context,
      weekStart: ref.read(appPreferencesProvider).weekStart,
      initialDate: from,
      firstDate: DateTime(from.year - 1),
      lastDate: DateTime(from.year + 2),
    );
    if (picked == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.moveSessionDate(session.id, from: from, to: picked);
    if (!context.mounted) return;
    ref.invalidate(planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
    await resyncReminders(ref);
  }

  Future<void> _removeDate(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
    DateTime date,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this date?'),
        content: Text(
          '${session.sessionName} will no longer be scheduled for '
          '${DateFormat.yMMMd().format(date)}. Anything already logged on '
          'that date is unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.removeSessionDate(session.id, date);
    if (!context.mounted) return;
    ref.invalidate(planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
    await resyncReminders(ref);
  }

  Future<void> _showDateActions(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
    DateTime date,
  ) async {
    final choice = await showModalBottomSheet<_DateAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Move to a different date'),
              onTap: () => Navigator.of(context).pop(_DateAction.move),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove this date'),
              onTap: () => Navigator.of(context).pop(_DateAction.remove),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _DateAction.move:
        await _moveDate(context, ref, session, date);
      case _DateAction.remove:
        await _removeDate(context, ref, session, date);
    }
  }

  Future<void> _handleExportAction(
    BuildContext context,
    PlanDetails details,
    _PlanExportAction action,
  ) async {
    switch (action) {
      case _PlanExportAction.shareCsv:
        await _sharePlan(context, details, _ExportFormat.csv);
      case _PlanExportAction.shareJson:
        await _sharePlan(context, details, _ExportFormat.json);
      case _PlanExportAction.shareJsonEncrypted:
        await _sharePlan(context, details, _ExportFormat.jsonEncrypted);
      case _PlanExportAction.saveCsv:
        await _savePlan(context, details, _ExportFormat.csv);
      case _PlanExportAction.saveJson:
        await _savePlan(context, details, _ExportFormat.json);
      case _PlanExportAction.saveJsonEncrypted:
        await _savePlan(context, details, _ExportFormat.jsonEncrypted);
    }
  }

  /// Null return means the export was cancelled - either at the file picker
  /// (handled by callers already) or, for the encrypted format, at the
  /// passphrase prompt.
  Future<({String contents, String fileName})?> _renderPlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final safeName = details.plan.name.replaceAll(RegExp(r'[^\w\- ]'), '_');
    switch (format) {
      case _ExportFormat.csv:
        return (contents: planToCsv(details), fileName: '$safeName.csv');
      case _ExportFormat.json:
      case _ExportFormat.jsonEncrypted:
        // Embeds full definitions (including image bytes) for any custom
        // exercise this plan uses - a plain export previously carried only
        // an exercise's id/name, so its photo silently didn't travel with it.
        final json = await planToJsonWithImages(
          details,
          ref.read(appDatabaseProvider),
        );
        final plainJson = jsonEncode(json);
        if (format == _ExportFormat.json) {
          return (contents: plainJson, fileName: '$safeName.json');
        }

        if (!context.mounted) return null;
        final passphrase = await promptPassphrase(
          context,
          title: 'Choose a passphrase',
          helperText:
              "You'll need this exact passphrase to import this plan file "
              'elsewhere.',
        );
        if (passphrase == null || passphrase.isEmpty) return null;
        final envelope = await encryptBackup(plainJson, passphrase);
        return (
          contents: envelope,
          fileName: '$safeName.$encryptedPlanFileExtension',
        );
    }
  }

  Future<void> _savePlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final rendered = await _renderPlan(context, details, format);
    if (rendered == null || !context.mounted) return;
    final uri = await FilePicker.saveFile(
      fileName: rendered.fileName,
      bytes: Uint8List.fromList(utf8.encode(rendered.contents)),
      type: FileType.custom,
      allowedExtensions: [_extensionFor(format)],
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Export cancelled.' : 'Saved.')),
    );
  }

  String _extensionFor(_ExportFormat format) => switch (format) {
    _ExportFormat.csv => 'csv',
    _ExportFormat.json => 'json',
    _ExportFormat.jsonEncrypted => encryptedPlanFileExtension,
  };

  /// Hands the exported plan to the OS share sheet, so the user can send it
  /// via Bluetooth, WhatsApp, email, or anything else installed - rather
  /// than only being able to save it to a location the file picker exposes.
  Future<void> _sharePlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final rendered = await _renderPlan(context, details, format);
    if (rendered == null || !context.mounted) return;
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, rendered.fileName));
    await file.writeAsString(rendered.contents);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Training plan: ${details.plan.name}'),
    );
  }
}

class _WeekRangeDialog extends StatefulWidget {
  final int startWeek;

  const _WeekRangeDialog({required this.startWeek});

  @override
  State<_WeekRangeDialog> createState() => _WeekRangeDialogState();
}

class _WeekRangeDialogState extends State<_WeekRangeDialog> {
  late final _fromController = TextEditingController(text: '${widget.startWeek}');
  late final _toController = TextEditingController(text: '${widget.startWeek}');

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicate to other weeks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Copies this session\'s exercises into new sessions at each '
            'week in this range. Duplicated sessions start unscheduled.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'From week',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _toController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'To week',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final from = int.tryParse(_fromController.text.trim());
            final to = int.tryParse(_toController.text.trim());
            if (from == null || to == null || from > to) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a valid week range.')),
              );
              return;
            }
            Navigator.of(context).pop((from, to));
          },
          child: const Text('Duplicate'),
        ),
      ],
    );
  }
}

enum _DateAction { move, remove }

enum _ExportFormat { csv, json, jsonEncrypted }

enum _PlanExportAction {
  shareCsv,
  shareJson,
  shareJsonEncrypted,
  saveCsv,
  saveJson,
  saveJsonEncrypted,
}
