import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../../data/seed/exercise_seed_loader.dart';
import '../../export/backup_export.dart';
import '../../import/backup_import.dart';
import '../../logic/units.dart';
import '../../security/backup_encryption.dart';
import '../exercise_library/exercise_library_providers.dart';
import 'app_preferences.dart';
import 'backup_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('Weight unit'),
            subtitle: Text(
              prefs.weightUnit == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)',
            ),
            onTap: () => _pickWeightUnit(context, ref, prefs.weightUnit),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('Week starts on'),
            subtitle: Text(
              prefs.weekStart == WeekStart.monday ? 'Monday' : 'Sunday',
            ),
            onTap: () => _pickWeekStart(context, ref, prefs.weekStart),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export full backup'),
            subtitle: const Text(
              'Every plan, custom exercise, and logged session - encrypted with a passphrase you choose.',
            ),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Restore from backup'),
            subtitle: const Text(
              'Replaces everything currently on this device.',
            ),
            onTap: () => _importBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Permanently erases every plan, exercise, and logged session on this device.',
            ),
            onTap: () => _deleteAllData(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWeightUnit(
    BuildContext context,
    WidgetRef ref,
    WeightUnit current,
  ) async {
    final choice = await showDialog<WeightUnit>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Weight unit'),
        children: [
          for (final unit in WeightUnit.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(unit),
              child: Text(unit == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)'),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setWeightUnit(choice);
  }

  Future<void> _pickWeekStart(
    BuildContext context,
    WidgetRef ref,
    WeekStart current,
  ) async {
    final choice = await showDialog<WeekStart>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Week starts on'),
        children: [
          for (final start in WeekStart.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(start),
              child: Text(start == WeekStart.monday ? 'Monday' : 'Sunday'),
            ),
        ],
      ),
    );
    if (choice == null || choice == current) return;
    await ref.read(appPreferencesProvider.notifier).setWeekStart(choice);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final passphrase = await promptPassphrase(
      context,
      title: 'Choose a backup passphrase',
      helperText: "You'll need this exact passphrase to restore the backup.",
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final db = ref.read(appDatabaseProvider);
    final backupJson = await buildBackupJson(db);
    final envelope = await encryptBackup(jsonEncode(backupJson), passphrase);

    final fileName =
        'training-app-backup-${DateTime.now().toIso8601String().substring(0, 10)}.$backupFileExtension';
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(envelope)),
      type: FileType.custom,
      allowedExtensions: [backupFileExtension],
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uri == null ? 'Export cancelled.' : 'Backup saved.',
        ),
      ),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [backupFileExtension],
    );
    if (file == null) return;

    if (!context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Restore from backup?',
      message:
          'This replaces everything currently on this device with the '
          "backup's contents. This can't be undone.",
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;

    if (!context.mounted) return;
    final passphrase = await promptPassphrase(
      context,
      title: 'Enter the backup passphrase',
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final envelope = utf8.decode(await file.readAsBytes());
    final db = ref.read(appDatabaseProvider);

    try {
      final decrypted = await decryptBackup(envelope, passphrase);
      final backupJson = jsonDecode(decrypted) as Map<String, dynamic>;
      await importBackupJson(backupJson, db);
      // The exercise library screen's providers are one-shot Futures, not
      // reactive DB streams, so they don't notice a restore's direct writes
      // on their own.
      ref.invalidate(filteredExercisesProvider);
      ref.invalidate(exerciseCategoriesProvider);
      ref.invalidate(creatorFilterOptionsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup restored.')));
    } on BackupDecryptionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on BackupJsonFormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete all data?',
      message:
          'This permanently erases every plan, exercise, and logged '
          "session on this device. This can't be undone.",
      confirmLabel: 'Delete everything',
    );
    if (!confirmed) return;

    final db = ref.read(appDatabaseProvider);
    await db.maintenanceDao.wipeAllData();
    await deleteAllAttachments();
    await seedExerciseLibrary(db);
    // Same reasoning as the restore path above - these providers need an
    // explicit nudge to notice the wipe+reseed.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data deleted.')));
  }
}
