import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../export/library_export.dart';
import '../../security/backup_encryption.dart';
import '../settings/backup_dialogs.dart';

enum ExerciseExportAction { shareJson, shareEncrypted, saveJson, saveEncrypted }

/// Shows the same export-action sheet used for a multi-exercise selection,
/// scoped to whatever [exercises] the caller hands in - one exercise from
/// the detail screen's own share action, or several from the library's
/// "select exercises to export" flow. Shared so both entry points stay in
/// lockstep instead of drifting into two slightly different export flows.
///
/// Returns whether the user actually picked one of the four actions, as
/// opposed to dismissing the sheet - the library's selection mode uses this
/// to decide whether to clear the selection afterward (dismissing the sheet
/// should leave the user free to keep picking exercises).
Future<bool> showExerciseExportSheet(
  BuildContext context,
  WidgetRef ref,
  List<Exercise> exercises,
) async {
  if (exercises.isEmpty) return false;

  final action = await showModalBottomSheet<ExerciseExportAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share (.json)'),
            onTap: () =>
                Navigator.of(context).pop(ExerciseExportAction.shareJson),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Share encrypted (.tlibrary)'),
            onTap: () =>
                Navigator.of(context).pop(ExerciseExportAction.shareEncrypted),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Save (.json)'),
            onTap: () =>
                Navigator.of(context).pop(ExerciseExportAction.saveJson),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Save encrypted (.tlibrary)'),
            onTap: () =>
                Navigator.of(context).pop(ExerciseExportAction.saveEncrypted),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return false;

  await exportExercises(context, ref, exercises, action);
  return true;
}

/// The actual export/share work for [exercises], independent of how the
/// caller chose [action] - reused by [showExerciseExportSheet] and callable
/// directly if a future caller ever wants to skip the sheet.
Future<void> exportExercises(
  BuildContext context,
  WidgetRef ref,
  List<Exercise> exercises,
  ExerciseExportAction action,
) async {
  final db = ref.read(appDatabaseProvider);
  final json = await buildLibraryJson(db, exercisesOverride: exercises);
  if (!context.mounted) return;
  final plainJson = jsonEncode(json);

  final fileNameBase = _exerciseExportFileNameBase(exercises);
  final shareText = exercises.length == 1
      ? exercises.single.name
      : '${exercises.length} exercises';

  final String contents;
  final String fileName;
  final String extension;
  if (action == ExerciseExportAction.shareEncrypted ||
      action == ExerciseExportAction.saveEncrypted) {
    final passphrase = await promptPassphrase(
      context,
      title: 'Choose a passphrase',
      helperText:
          "You'll need this exact passphrase to import this library "
          'elsewhere.',
    );
    if (passphrase == null || passphrase.isEmpty) return;
    contents = await encryptBackup(plainJson, passphrase);
    fileName = '$fileNameBase.$encryptedLibraryFileExtension';
    extension = encryptedLibraryFileExtension;
  } else {
    contents = plainJson;
    fileName = '$fileNameBase.json';
    extension = 'json';
  }
  if (!context.mounted) return;

  if (action == ExerciseExportAction.saveJson ||
      action == ExerciseExportAction.saveEncrypted) {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri == null ? 'Export cancelled.' : 'Saved.')),
    );
  } else {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(contents);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  }
}

/// A filename that says what's actually in the file rather than a generic
/// name - the exercise's own name for one, a plain "exercises_selection"
/// for several (concatenating every name would get unwieldy past two or
/// three).
String _exerciseExportFileNameBase(List<Exercise> exercises) {
  if (exercises.length == 1) {
    final slug = exercises.single.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'exercise' : slug;
  }
  return 'exercises_selection';
}
