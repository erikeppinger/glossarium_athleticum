import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../export/plan_export.dart' show encryptedPlanFileExtension;
import '../../home_screen.dart' show settingsAppBarAction;
import '../../security/backup_encryption.dart';
import '../settings/backup_dialogs.dart';
import '../settings/templates_screen.dart';
import 'plan_actions.dart';
import 'plan_builder_screen.dart';
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
          final archived = ref.watch(archivedPlansProvider).valueOrNull ?? [];
          if (plans.isEmpty && archived.isEmpty) {
            return const Center(
              child: Text(
                'No plans yet. Build one from the Exercise Library, or '
                'import one from a spreadsheet.',
              ),
            );
          }
          return ListView(
            children: [
              if (plans.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No active plans. Restore one below, or import a new one.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final plan in plans)
                ListTile(
                  title: Text(plan.name),
                  // Notes aren't shown here at all, even as a preview - the
                  // plan list is a flat scan-down list of names, not a place
                  // to read free text, and a per-plan note (however short)
                  // read as visual noise between rows. The full text has its
                  // own dedicated, readable home on the plan detail screen.
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlanDetailScreen(planId: plan.id),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Plan options',
                    onPressed: () => showPlanActions(context, ref, plan),
                  ),
                ),
              if (archived.isNotEmpty) ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Archived',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                for (final plan in archived)
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(plan.name),
                    subtitle: const Text('Archived - nothing was deleted'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlanDetailScreen(planId: plan.id),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Plan options',
                      onPressed: () => showPlanActions(context, ref, plan),
                    ),
                  ),
              ],
              const SizedBox(height: 88),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showImportOptions(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
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
              leading: const Icon(Icons.fitness_center),
              title: const Text('Build a new plan'),
              subtitle: const Text('Add exercises from your library, from scratch'),
              onTap: () => Navigator.of(context).pop(_ImportSource.build),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('From spreadsheet (.csv or .xlsx)'),
              subtitle: const Text('Excel/Sheets export, or the plan template'),
              onTap: () => Navigator.of(context).pop(_ImportSource.spreadsheet),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('From plan file (.json)'),
              subtitle: const Text("Exported from this app's Plan screen"),
              onTap: () => Navigator.of(context).pop(_ImportSource.json),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('From encrypted plan file (.tplan)'),
              subtitle: const Text("A plan shared with its own passphrase"),
              onTap: () =>
                  Navigator.of(context).pop(_ImportSource.encryptedJson),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Need a blank template first?'),
              subtitle: const Text('Get the spreadsheet/text template to fill in'),
              onTap: () => Navigator.of(context).pop(_ImportSource.template),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ImportSource.build:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PlanBuilderScreen()),
        );
      case _ImportSource.template:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TemplatesScreen()),
        );
      case _ImportSource.spreadsheet:
        await _importFromSpreadsheet(context);
      case _ImportSource.json:
        await _importFromJson(context, ref);
      case _ImportSource.encryptedJson:
        await _importFromEncryptedJson(context, ref);
    }
  }

  Future<void> _importFromSpreadsheet(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final isXlsx = file.name.toLowerCase().endsWith('.xlsx');
    final suggestedName = file.name.replaceAll(RegExp(r'\.(csv|xlsx)$'), '');

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => isXlsx
            ? PlanImportScreen(
                xlsxBytes: bytes,
                suggestedPlanName: suggestedName,
              )
            : PlanImportScreen(
                csvContent: utf8.decode(bytes),
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

  Future<void> _importFromEncryptedJson(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [encryptedPlanFileExtension],
    );
    if (file == null) return;

    if (!context.mounted) return;
    final passphrase = await promptPassphrase(
      context,
      title: 'Enter the plan file\'s passphrase',
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final envelope = utf8.decode(await file.readAsBytes());
    if (!context.mounted) return;

    try {
      final decrypted = await decryptBackup(envelope, passphrase);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      if (!context.mounted) return;
      await importOrSyncPlanJson(context, ref, json);
    } on BackupDecryptionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

enum _ImportSource { build, spreadsheet, json, encryptedJson, template }
