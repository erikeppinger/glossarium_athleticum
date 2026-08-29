import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/local_storage.dart';

/// Plain `test()`, not `testWidgets()` - real dart:io after pumpWidget hangs
/// on this machine (see CLAUDE.md).
void main() {
  late Directory tempRoot;
  late Directory attachments;
  late File source;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('attachment_test');
    attachments = Directory('${tempRoot.path}/attachments');
    source = File('${tempRoot.path}/photo.jpg');
    await source.writeAsString('pretend-jpeg-bytes');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('saveAttachment copies the file and returns just a filename', () async {
    final name = await saveAttachment(source.path, directory: attachments);

    expect(
      name,
      isNot(contains(Platform.pathSeparator)),
      reason: 'only the filename is stored - sandbox paths change across '
          'reinstalls, so an absolute path would stop resolving',
    );
    expect(name, endsWith('.jpg'), reason: 'the extension is preserved');
    expect(await File('${attachments.path}/$name').exists(), isTrue);
  });

  test('the copy survives the source being deleted', () async {
    final name = await saveAttachment(source.path, directory: attachments);
    await source.delete();

    final copied = File('${attachments.path}/$name');
    expect(await copied.exists(), isTrue);
    expect(await copied.readAsString(), 'pretend-jpeg-bytes');
  });

  test('creates the attachments directory if it does not exist yet', () async {
    expect(await attachments.exists(), isFalse);
    await saveAttachment(source.path, directory: attachments);
    expect(await attachments.exists(), isTrue);
  });

  test('two saves of the same source do not collide', () async {
    final first = await saveAttachment(source.path, directory: attachments);
    final second = await saveAttachment(source.path, directory: attachments);

    expect(first, isNot(second));
    expect(await File('${attachments.path}/$first').exists(), isTrue);
    expect(await File('${attachments.path}/$second').exists(), isTrue);
  });

  test('resolveAttachmentPath rebuilds a usable absolute path', () async {
    final name = await saveAttachment(source.path, directory: attachments);
    final path = await resolveAttachmentPath(name, directory: attachments);

    expect(await File(path).exists(), isTrue);
  });

  test('deleteAttachment removes one file and leaves others', () async {
    final keep = await saveAttachment(source.path, directory: attachments);
    final remove = await saveAttachment(source.path, directory: attachments);

    await deleteAttachment(remove, directory: attachments);

    expect(await File('${attachments.path}/$remove').exists(), isFalse);
    expect(await File('${attachments.path}/$keep').exists(), isTrue);
  });

  test('deleting a missing attachment is a no-op, not an error', () async {
    await expectLater(
      deleteAttachment('never-existed.jpg', directory: attachments),
      completes,
    );
  });

  test('deleteAllAttachments clears everything', () async {
    await saveAttachment(source.path, directory: attachments);
    await saveAttachment(source.path, directory: attachments);

    await deleteAllAttachments(directory: attachments);

    expect(await attachments.exists(), isFalse);
  });
}
