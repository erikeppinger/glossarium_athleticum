import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plan_detail_screen.dart';
import 'plan_import_screen.dart';
import 'plan_providers.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
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
        onPressed: () => _importFromSpreadsheet(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Import from spreadsheet'),
      ),
    );
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
}
