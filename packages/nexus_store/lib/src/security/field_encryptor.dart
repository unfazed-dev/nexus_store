import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nexus_store/src/security/encryption_algorithm.dart';
import 'package:nexus_store/src/security/encryption_config.dart';

/// Abstract interface for field-level encryption.
///
/// Implementations encrypt and decrypt individual field values while
/// preserving the data structure.
abstract interface class FieldEncryptor {
  /// Encrypts a plaintext value.
  ///
  /// Returns the encrypted value as a prefixed string
  /// (e.g., `enc:v1:base64data`).
  Future<String> encrypt(String plaintext, String fieldName);

  /// Decrypts an encrypted value.
  ///
  /// Returns the original plaintext value.
  /// Throws [EncryptionException] if decryption fails.
  Future<String> decrypt(String ciphertext, String fieldName);

  /// Returns `true` if the given field should be encrypted.
  bool shouldEncrypt(String fieldName);

  /// Returns `true` if the given value is already encrypted.
  bool isEncrypted(String value);
}

/// Default implementation of [FieldEncryptor] using the `cryptography` package.
class DefaultFieldEncryptor implements FieldEncryptor {
  /// Creates a field encryptor with the given configuration.
  DefaultFieldEncryptor({required this.config});

  /// The encryption configuration.
  final EncryptionFieldLevel config;

  /// Encryption prefix pattern: `enc:<version>:<base64_data>`
  static const String _encryptionPrefix = 'enc:';

  Cipher? _cipher;
  SecretKey? _secretKey;

  Future<Cipher> _getCipher() async {
    if (_cipher != null) return _cipher!;

    _cipher = switch (config.algorithm) {
      EncryptionAlgorithm.aes256Gcm => AesGcm.with256bits(),
      EncryptionAlgorithm.aes256Cbc => throw UnimplementedError(
          'AES-256-CBC is not yet implemented. Use AES-256-GCM instead.',
        ),
      EncryptionAlgorithm.chaCha20Poly1305 => Chacha20.poly1305Aead(),
    };

    return _cipher!;
  }

  Future<SecretKey> _getSecretKey() async {
    if (_secretKey != null) return _secretKey!;

    final keyString = await config.keyProvider();
    final keyBytes = utf8.encode(keyString);

    // Ensure key is 32 bytes for AES-256
    if (keyBytes.length < 32) {
      // Derive a 32-byte key using SHA-256
      final hash = await Sha256().hash(keyBytes);
      _secretKey = SecretKey(hash.bytes);
    } else {
      _secretKey = SecretKey(keyBytes.sublist(0, 32));
    }

    return _secretKey!;
  }

  @override
  bool shouldEncrypt(String fieldName) =>
      config.encryptedFields.contains(fieldName);

  @override
  bool isEncrypted(String value) => value.startsWith(_encryptionPrefix);

  @override
  Future<String> encrypt(String plaintext, String fieldName) async {
    if (!shouldEncrypt(fieldName)) return plaintext;

    final cipher = await _getCipher();
    final secretKey = await _getSecretKey();

    final secretBox = await cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );

    // Combine nonce + ciphertext + MAC into single bytes
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    final encoded = base64Encode(combined);
    return '$_encryptionPrefix${config.version}:$encoded';
  }

  @override
  Future<String> decrypt(String ciphertext, String fieldName) async {
    if (!isEncrypted(ciphertext)) return ciphertext;

    // Parse: enc:<version>:<base64_data>
    final parts = ciphertext.split(':');
    if (parts.length != 3 || parts[0] != 'enc') {
      throw EncryptionException('Invalid encrypted format: $ciphertext');
    }

    final version = parts[1];
    if (version != config.version) {
      throw EncryptionException(
        'Version mismatch: expected ${config.version}, got $version. '
        'Key rotation may be required.',
      );
    }

    final combined = base64Decode(parts[2]);
    final cipher = await _getCipher();
    final secretKey = await _getSecretKey();

    // Extract nonce (12 bytes for GCM/ChaCha20), ciphertext, and MAC (16 bytes)
    final nonceLength = cipher is AesGcm ? 12 : 12;
    const macLength = 16;

    if (combined.length < nonceLength + macLength) {
      throw const EncryptionException('Invalid encrypted data length');
    }

    final nonce = combined.sublist(0, nonceLength);
    final ciphertextBytes = combined.sublist(
      nonceLength,
      combined.length - macLength,
    );
    final macBytes = combined.sublist(combined.length - macLength);

    final secretBox = SecretBox(
      ciphertextBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final plainBytes = await cipher.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(plainBytes);
    } on SecretBoxAuthenticationError catch (e) {
      throw EncryptionException('Decryption failed: authentication error', e);
    }
  }

  /// Clears cached cipher and key.
  ///
  /// Call this when the key provider might return a different key
  /// (e.g., after key rotation).
  void clearCache() {
    _cipher = null;
    _secretKey = null;
  }
}

/// Exception thrown when encryption or decryption fails.
class EncryptionException implements Exception {
  /// Creates an encryption exception.
  const EncryptionException(this.message, [this.cause]);

  /// Error message.
  final String message;

  /// Underlying cause, if any.
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'EncryptionException: $message ($cause)'
      : 'EncryptionException: $message';
}
