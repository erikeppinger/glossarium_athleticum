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
import '../calendar/calendar_screen.dart';
import '../execution/start_session_helper.dart';
import 'plan_providers.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _PlanExportAction.saveCsv,
                  child: Text('Save as spreadsheet (.csv)'),
                ),
                PopupMenuItem(
                  value: _PlanExportAction.saveJson,
                  child: Text('Save as plan file (.json)'),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(details.plan.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final session in details.sessions)
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Week ${session.session.weekNumber} • ${session.session.day} • ${session.session.sessionName}',
                        ),
                        subtitle: Text(
                          session.exercises
                              .map((e) => e.exerciseName)
                              .join(', '),
                        ),
                      ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _pickDate(context, ref, session.session),
                            child: Text(
                              session.session.assignedDate == null
                                  ? 'Assign date'
                                  : dateFormat.format(
                                      session.session.assignedDate!,
                                    ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => startSessionWithMoveToTodayPrompt(
                              context,
                              ref,
                              session.session,
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
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

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    PlanSession session,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: session.assignedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.assignSessionDate(session.id, picked);
    ref.invalidate(planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
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
      case _PlanExportAction.saveCsv:
        await _savePlan(context, details, _ExportFormat.csv);
      case _PlanExportAction.saveJson:
        await _savePlan(context, details, _ExportFormat.json);
    }
  }

  ({String contents, String fileName}) _renderPlan(
    PlanDetails details,
    _ExportFormat format,
  ) {
    final safeName = details.plan.name.replaceAll(RegExp(r'[^\w\- ]'), '_');
    return switch (format) {
      _ExportFormat.csv => (
        contents: planToCsv(details),
        fileName: '$safeName.csv',
      ),
      _ExportFormat.json => (
        contents: jsonEncode(planToJson(details)),
        fileName: '$safeName.json',
      ),
    };
  }

  Future<void> _savePlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final rendered = _renderPlan(details, format);
    final uri = await FilePicker.saveFile(
      fileName: rendered.fileName,
      bytes: Uint8List.fromList(utf8.encode(rendered.contents)),
      type: FileType.custom,
      allowedExtensions: [format == _ExportFormat.csv ? 'csv' : 'json'],
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Export cancelled.' : 'Saved.')),
    );
  }

  /// Hands the exported plan to the OS share sheet, so the user can send it
  /// via Bluetooth, WhatsApp, email, or anything else installed - rather
  /// than only being able to save it to a location the file picker exposes.
  Future<void> _sharePlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final rendered = _renderPlan(details, format);
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, rendered.fileName));
    await file.writeAsString(rendered.contents);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Training plan: ${details.plan.name}'),
    );
  }
}

enum _ExportFormat { csv, json }

enum _PlanExportAction { shareCsv, shareJson, saveCsv, saveJson }
