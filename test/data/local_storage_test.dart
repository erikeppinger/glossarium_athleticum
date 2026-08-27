import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:training_app/data/local_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attachments_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deleteAllAttachments removes every file, leaving zero residual files', () async {
    final nested = Directory(p.join(tempDir.path, 'photos'));
    await nested.create(recursive: true);
    await File(p.join(tempDir.path, 'video1.mp4')).writeAsBytes([1, 2, 3]);
    await File(p.join(nested.path, 'photo1.jpg')).writeAsBytes([4, 5, 6]);

    await deleteAllAttachments(directory: tempDir);

    expect(await tempDir.exists(), isFalse);
  });

  test('deleteAllAttachments on a non-existent directory is a no-op, not an error', () async {
    final missing = Directory(p.join(tempDir.path, 'never_created'));
    await deleteAllAttachments(directory: missing);
    expect(await missing.exists(), isFalse);
  });
}
