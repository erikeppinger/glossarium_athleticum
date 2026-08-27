import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Thrown when a backup file can't be decrypted - wrong passphrase, or the
/// file is corrupted/truncated/not a backup at all. Deliberately doesn't
/// distinguish "wrong passphrase" from "corrupted file": both mean the
/// decrypted bytes can't be trusted, and telling them apart isn't something
/// AES-GCM's authentication tag can do reliably anyway.
class BackupDecryptionException implements Exception {
  final String message;
  const BackupDecryptionException(this.message);
  @override
  String toString() => message;
}

/// OWASP-recommended-minimum Argon2id parameters for password hashing
/// (19 MiB memory, 2 iterations, single-threaded) - a reasonable floor for
/// a mobile app where a much higher memory cost risks OOM on low-end
/// devices. Encoded in the envelope itself so a future stronger default
/// doesn't break decrypting older backups.
const _defaultMemoryKib = 19456;
const _defaultIterations = 2;
const _defaultParallelism = 1;
const _keyLengthBytes = 32; // AES-256
const _saltLengthBytes = 16;
const _envelopeVersion = 1;

final _cipher = AesGcm.with256bits();

Argon2id _kdf({
  required int memoryKib,
  required int iterations,
  required int parallelism,
}) => Argon2id(
  memory: memoryKib,
  iterations: iterations,
  parallelism: parallelism,
  hashLength: _keyLengthBytes,
);

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

/// Encrypts [plaintext] with a key derived from [passphrase] via Argon2id,
/// then AES-256-GCM. Returns a self-contained JSON envelope (versioned, with
/// the salt/nonce/KDF parameters needed to decrypt) - safe to write directly
/// to a `.backup` file; nothing else needs to be stored alongside it.
Future<String> encryptBackup(String plaintext, String passphrase) async {
  final salt = _randomBytes(_saltLengthBytes);
  final secretKey = await _kdf(
    memoryKib: _defaultMemoryKib,
    iterations: _defaultIterations,
    parallelism: _defaultParallelism,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  final secretBox = await _cipher.encrypt(
    utf8.encode(plaintext),
    secretKey: secretKey,
  );

  final envelope = {
    'version': _envelopeVersion,
    'kdf': 'argon2id',
    'memoryKib': _defaultMemoryKib,
    'iterations': _defaultIterations,
    'parallelism': _defaultParallelism,
    'salt': base64Encode(salt),
    'cipher': 'aes-256-gcm',
    'nonce': base64Encode(secretBox.nonce),
    'ciphertext': base64Encode(secretBox.cipherText),
    'mac': base64Encode(secretBox.mac.bytes),
  };
  return jsonEncode(envelope);
}

/// Decrypts an envelope produced by [encryptBackup]. Throws
/// [BackupDecryptionException] - never partially - for a wrong passphrase,
/// a corrupted/truncated file, or a file that isn't a backup envelope at
/// all.
Future<String> decryptBackup(String envelopeJson, String passphrase) async {
  final Map<String, dynamic> envelope;
  try {
    final decoded = jsonDecode(envelopeJson);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupDecryptionException('Not a valid backup file.');
    }
    envelope = decoded;
  } on FormatException {
    throw const BackupDecryptionException('Not a valid backup file.');
  }

  if (envelope['version'] != _envelopeVersion ||
      envelope['cipher'] != 'aes-256-gcm' ||
      envelope['kdf'] != 'argon2id') {
    throw const BackupDecryptionException(
      'Unsupported or corrupted backup file.',
    );
  }

  try {
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    final ciphertext = base64Decode(envelope['ciphertext'] as String);
    final macBytes = base64Decode(envelope['mac'] as String);

    final secretKey = await _kdf(
      memoryKib: envelope['memoryKib'] as int,
      iterations: envelope['iterations'] as int,
      parallelism: envelope['parallelism'] as int,
    ).deriveKeyFromPassword(password: passphrase, nonce: salt);

    final plaintextBytes = await _cipher.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes)),
      secretKey: secretKey,
    );
    return utf8.decode(plaintextBytes);
  } on SecretBoxAuthenticationError {
    throw const BackupDecryptionException(
      'Incorrect passphrase, or the file is corrupted.',
    );
  } on FormatException {
    throw const BackupDecryptionException('Corrupted backup file.');
  } on TypeError {
    throw const BackupDecryptionException('Corrupted backup file.');
  }
}
