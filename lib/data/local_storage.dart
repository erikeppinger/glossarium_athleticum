import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _random = Random();

/// Every attachment path in this file is built through here rather than raw
/// string interpolation. `fileName` isn't always a name this app generated
/// itself - `restoreExerciseImage` (lib/export/exercise_json.dart) feeds a
/// plan/backup file's own `image_path` field straight into these functions,
/// and that file can come from an untrusted source (a shared plan, an
/// "Open with" import). Without this, a crafted `image_path` like
/// `"../../../../databases/training_app.sqlite"` would let a malicious plan
/// file overwrite or read arbitrary files inside the app's own sandboxed
/// storage on import/export. `p.basename` strips any directory component -
/// including a leading `/` (Windows: any leading `\` too) `p.join` won't
/// backtrack past - so the resolved path always stays inside [dir]
/// regardless of what [fileName] actually contains.
String _attachmentPath(Directory dir, String fileName) =>
    p.join(dir.path, p.basename(fileName));

/// Subdirectory (under the app's documents directory) where in-app media
/// attachments will live once Phase 4+ implements them. Kept as a single
/// well-known location now so "delete all data" can reliably wipe it later
/// without needing to enumerate scattered file paths - Phase 4+'s media
/// feature must write attachments under [getAttachmentsDirectory] for that
/// guarantee to keep holding.
const attachmentsDirName = 'attachments';

Future<Directory> getAttachmentsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory('${docs.path}/$attachmentsDirName');
}

/// Deletes the attachments directory and everything in it, if it exists.
/// Part of "delete all data" leaving zero residual files.
///
/// [directory] is injectable for testing - real callers omit it and get the
/// actual platform directory via [getAttachmentsDirectory].
Future<void> deleteAllAttachments({Directory? directory}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

/// Copies [sourcePath] into the attachments directory under a collision-proof
/// name and returns that *filename* - not a full path.
///
/// Only the filename is stored in the database because the app's sandbox
/// directory changes across reinstalls and OS upgrades; a stored absolute
/// path would silently stop resolving. Callers pair this with
/// [resolveAttachmentPath] at display time.
Future<String> saveAttachment(
  String sourcePath, {
  Directory? directory,
  String? fileName,
}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final extension = sourcePath.contains('.')
      ? sourcePath.substring(sourcePath.lastIndexOf('.'))
      : '';
  // The microsecond timestamp alone isn't actually collision-proof - on a
  // coarser system clock (observed under Windows when many tests save an
  // attachment in quick succession), two calls in the same tick produce the
  // same name. A random suffix closes that gap without needing a real UUID
  // dependency just for this.
  final name =
      fileName ??
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}$extension';

  await File(sourcePath).copy(_attachmentPath(dir, name));
  return name;
}

/// Turns a stored attachment filename back into an absolute path for display.
Future<String> resolveAttachmentPath(
  String fileName, {
  Directory? directory,
}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  return _attachmentPath(dir, fileName);
}

/// Removes a single attachment, ignoring one that's already gone - a missing
/// file and a deleted file are the same outcome from the caller's side.
Future<void> deleteAttachment(
  String fileName, {
  Directory? directory,
}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  final file = File(_attachmentPath(dir, fileName));
  if (await file.exists()) await file.delete();
}

/// Reads an attachment's raw bytes back, for embedding into a plan/backup
/// export - null (not a thrown error) when the file is missing, same
/// "missing is not exceptional" philosophy as [AttachmentImage]'s fallback.
Future<List<int>?> readAttachmentBytes(
  String fileName, {
  Directory? directory,
}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  final file = File(_attachmentPath(dir, fileName));
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

/// Writes [bytes] directly under [fileName] in the attachments directory -
/// the import-side counterpart to [readAttachmentBytes], used when restoring
/// an image that travelled as embedded bytes in a plan/backup export rather
/// than being copied from a picked file on this device.
Future<void> saveAttachmentBytes(
  List<int> bytes,
  String fileName, {
  Directory? directory,
}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  await File(_attachmentPath(dir, fileName)).writeAsBytes(bytes);
}
