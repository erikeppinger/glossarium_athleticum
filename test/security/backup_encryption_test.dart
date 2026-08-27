import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/security/backup_encryption.dart';

void main() {
  const passphrase = 'correct horse battery staple';
  const plaintext = '{"schema_version":1,"plans":[]}';

  test('round-trips: encrypt then decrypt with the right passphrase', () async {
    final envelope = await encryptBackup(plaintext, passphrase);
    final decrypted = await decryptBackup(envelope, passphrase);
    expect(decrypted, plaintext);
  });

  test('two encryptions of the same plaintext produce different envelopes', () async {
    // Different random salt/nonce each time - if they matched, the salt/nonce
    // wouldn't be random, which would weaken the scheme.
    final a = await encryptBackup(plaintext, passphrase);
    final b = await encryptBackup(plaintext, passphrase);
    expect(a, isNot(equals(b)));
  });

  test('wrong passphrase fails cleanly, not with a garbage result', () async {
    final envelope = await encryptBackup(plaintext, passphrase);
    await expectLater(
      decryptBackup(envelope, 'wrong passphrase'),
      throwsA(isA<BackupDecryptionException>()),
    );
  });

  test('truncated ciphertext fails cleanly', () async {
    final envelope = await encryptBackup(plaintext, passphrase);
    final truncated = envelope.substring(0, envelope.length - 20);
    await expectLater(
      decryptBackup(truncated, passphrase),
      throwsA(isA<BackupDecryptionException>()),
    );
  });

  test('a single flipped byte in the ciphertext fails cleanly (tamper-evident)', () async {
    final envelope = await encryptBackup(plaintext, passphrase);
    // Flip one character deep in the JSON body without breaking JSON syntax -
    // corrupt a base64 payload character instead of e.g. removing a quote.
    final corruptIndex = envelope.indexOf('"ciphertext"') + 20;
    final chars = envelope.codeUnits.toList();
    chars[corruptIndex] = chars[corruptIndex] == 65 /* 'A' */ ? 66 : 65;
    final corrupted = String.fromCharCodes(chars);

    await expectLater(
      decryptBackup(corrupted, passphrase),
      throwsA(isA<BackupDecryptionException>()),
    );
  });

  test('completely garbage input fails cleanly, not with a crash', () async {
    await expectLater(
      decryptBackup('not even json', passphrase),
      throwsA(isA<BackupDecryptionException>()),
    );
  });

  test('valid JSON that is not a backup envelope fails cleanly', () async {
    await expectLater(
      decryptBackup('{"hello": "world"}', passphrase),
      throwsA(isA<BackupDecryptionException>()),
    );
  });
}
