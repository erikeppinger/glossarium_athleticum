import 'dart:io';

import 'package:path_provider/path_provider.dart';

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
/// A no-op today (nothing writes to this directory yet, since media
/// attachments aren't built), but part of "delete all data" leaving zero
/// residual files once they are.
///
/// [directory] is injectable for testing - real callers omit it and get the
/// actual platform directory via [getAttachmentsDirectory].
Future<void> deleteAllAttachments({Directory? directory}) async {
  final dir = directory ?? await getAttachmentsDirectory();
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
