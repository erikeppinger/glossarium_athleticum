import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_screen.dart' show settingsAppBarAction;
import 'plan_detail_screen.dart';
import 'plan_import_screen.dart';
import 'plan_providers.dart';
import 'plan_sync_handler.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: [settingsAppBarAction(context)],
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text('No plans yet. Import one from a spreadsheet.'),
            );
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                title: Text(plan.name),
                subtitle: plan.notes.isEmpty ? null : Text(plan.notes),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlanDetailScreen(planId: plan.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showImportOptions(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Import plan'),
      ),
    );
  }

  Future<void> _showImportOptions(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_ImportSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('From spreadsheet (.csv)'),
              subtitle: const Text('Excel/Sheets export, or the plan template'),
              onTap: () => Navigator.of(context).pop(_ImportSource.spreadsheet),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('From plan file (.json)'),
              subtitle: const Text("Exported from this app's Plan screen"),
              onTap: () => Navigator.of(context).pop(_ImportSource.json),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ImportSource.spreadsheet:
        await _importFromSpreadsheet(context);
      case _ImportSource.json:
        await _importFromJson(context, ref);
    }
  }

  Future<void> _importFromSpreadsheet(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final csvContent = utf8.decode(bytes);
    final suggestedName = file.name.replaceAll(RegExp(r'\.csv$'), '');

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanImportScreen(
          csvContent: csvContent,
          suggestedPlanName: suggestedName,
        ),
      ),
    );
  }

  Future<void> _importFromJson(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    if (!context.mounted) return;
    await importOrSyncPlanJson(context, ref, json);
  }
}

enum _ImportSource { spreadsheet, json }
