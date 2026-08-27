import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../export/plan_export.dart';
import '../calendar/calendar_screen.dart';
import '../execution/execution_screen.dart';

final _planDetailsProvider = FutureProvider.family<PlanDetails?, String>(
  (ref, planId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getPlanDetails(planId);
  },
);

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(_planDetailsProvider(planId));
    final dateFormat = DateFormat.yMMMd();
    final loadedDetails = detailsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          if (loadedDetails != null)
            PopupMenuButton<_ExportFormat>(
              icon: const Icon(Icons.share),
              onSelected: (format) => _exportPlan(context, loadedDetails, format),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ExportFormat.csv,
                  child: Text('Export as spreadsheet (.csv)'),
                ),
                PopupMenuItem(
                  value: _ExportFormat.json,
                  child: Text('Export as plan file (.json)'),
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
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExecutionScreen(
                                  planSessionId: session.session.id,
                                ),
                              ),
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
    ref.invalidate(_planDetailsProvider(planId));
    ref.invalidate(scheduledSessionsProvider);
  }

  Future<void> _exportPlan(
    BuildContext context,
    PlanDetails details,
    _ExportFormat format,
  ) async {
    final safeName = details.plan.name.replaceAll(RegExp(r'[^\w\- ]'), '_');
    final String contents;
    final String fileName;
    final List<String> allowedExtensions;
    switch (format) {
      case _ExportFormat.csv:
        contents = planToCsv(details);
        fileName = '$safeName.csv';
        allowedExtensions = ['csv'];
      case _ExportFormat.json:
        contents = jsonEncode(planToJson(details));
        fileName = '$safeName.json';
        allowedExtensions = ['json'];
    }

    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Export cancelled.' : 'Exported.')),
    );
  }
}

enum _ExportFormat { csv, json }
