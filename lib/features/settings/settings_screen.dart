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
import '../../security/backup_encryption.dart';
import '../exercise_library/exercise_library_providers.dart';

const _backupFileExtension = 'tabackup';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final passphrase = await _promptPassphrase(
      context,
      title: 'Choose a backup passphrase',
      helperText: "You'll need this exact passphrase to restore the backup.",
    );
    if (passphrase == null || passphrase.isEmpty) return;

    final db = ref.read(appDatabaseProvider);
    final backupJson = await buildBackupJson(db);
    final envelope = await encryptBackup(jsonEncode(backupJson), passphrase);

    final fileName =
        'training-app-backup-${DateTime.now().toIso8601String().substring(0, 10)}.$_backupFileExtension';
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(envelope)),
      type: FileType.custom,
      allowedExtensions: [_backupFileExtension],
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
      allowedExtensions: [_backupFileExtension],
    );
    if (file == null) return;

    if (!context.mounted) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Restore from backup?',
      message:
          'This replaces everything currently on this device with the '
          "backup's contents. This can't be undone.",
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;

    if (!context.mounted) return;
    final passphrase = await _promptPassphrase(
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
    final confirmed = await _confirmDestructiveAction(
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

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data deleted.')));
  }

  Future<String?> _promptPassphrase(
    BuildContext context, {
    required String title,
    String? helperText,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Passphrase',
            helperText: helperText,
            helperMaxLines: 3,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDestructiveAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
