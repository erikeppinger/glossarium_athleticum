import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database_provider.dart';
import '../../export/backup_export.dart';
import '../../import/backup_import.dart';
import '../../security/backup_encryption.dart';
import '../exercise_library/exercise_library_providers.dart';
import '../plans/plan_import_screen.dart';
import '../plans/plan_sync_handler.dart';
import '../settings/backup_dialogs.dart';

/// Reads a file received from outside the app (Bluetooth, WhatsApp, "Open
/// with", etc.) and routes it into the same import flows used when the
/// user picks a file manually. Thin I/O wrapper around [handleSharedContent]
/// - kept separate so the actual routing logic can be tested by passing
/// content directly, without touching the filesystem.
Future<void> handleSharedFile(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final content = await File(path).readAsString();
  if (!context.mounted) return;
  await handleSharedContent(
    context,
    ref,
    extension: p.extension(path).toLowerCase(),
    suggestedPlanName: p.basenameWithoutExtension(path),
    displayName: p.basename(path),
    content: content,
  );
}

/// Routes already-read file content into the matching import flow. The
/// extension unambiguously says what the content is: full-backup exports
/// are always encrypted (`.tabackup`, never plain JSON on disk - see
/// lib/export/backup_export.dart), single-plan exports are plain `.json`,
/// and spreadsheet plans are `.csv`.
Future<void> handleSharedContent(
  BuildContext context,
  WidgetRef ref, {
  required String extension,
  required String suggestedPlanName,
  required String displayName,
  required String content,
}) async {
  switch (extension) {
    case '.csv':
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlanImportScreen(
            csvContent: content,
            suggestedPlanName: suggestedPlanName,
          ),
        ),
      );

    case '.json':
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        if (!context.mounted) return;
        await importOrSyncPlanJson(context, ref, json);
      } on FormatException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read this plan file.')),
        );
      }

    case _ when extension == '.$backupFileExtension':
      final confirmed = await confirmDestructiveAction(
        context,
        title: 'Restore from backup?',
        message:
            'This replaces everything currently on this device with the '
            "received backup's contents. This can't be undone.",
        confirmLabel: 'Restore',
      );
      if (!confirmed) return;

      if (!context.mounted) return;
      final passphrase = await promptPassphrase(
        context,
        title: 'Enter the backup passphrase',
      );
      if (passphrase == null || passphrase.isEmpty) return;

      final db = ref.read(appDatabaseProvider);
      try {
        final decrypted = await decryptBackup(content, passphrase);
        final backupJson = jsonDecode(decrypted) as Map<String, dynamic>;
        await importBackupJson(backupJson, db);
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

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Training App doesn't recognize $displayName.")),
      );
  }
}
