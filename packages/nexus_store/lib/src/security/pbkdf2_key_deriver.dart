import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nexus_store/src/security/derived_key.dart';
import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:nexus_store/src/security/key_deriver.dart';

/// PBKDF2 (Password-Based Key Derivation Function 2) implementation.
///
/// Uses HMAC-SHA256 or HMAC-SHA512 as the pseudo-random function.
///
/// ## Security Recommendations
///
/// - **Iterations**: OWASP 2023 recommends 310,000 for HMAC-SHA256.
///   Higher values are more secure but slower.
/// - **Salt**: Always use a unique, random salt per user/key.
///   Never reuse salts across different passwords.
/// - **Key Length**: 32 bytes (256 bits) is standard for AES-256.
///
/// ## Example
///
/// ```dart
/// final deriver = Pbkdf2KeyDeriver(
///   config: KeyDerivationConfig.pbkdf2(
///     iterations: 310000,
///     hashAlgorithm: KdfHashAlgorithm.sha256,
///   ) as KeyDerivationPbkdf2,
/// );
///
/// // First-time key derivation (generates new salt)
/// final derivedKey = await deriver.deriveKey(
///   password: 'user-password',
/// );
///
/// // Store derivedKey.salt securely
/// // Use derivedKey.keyBytes for encryption
///
/// // Later, derive the same key with stored salt
/// final sameKey = await deriver.deriveKey(
///   password: 'user-password',
///   salt: storedSalt,
/// );
/// ```
class Pbkdf2KeyDeriver implements KeyDeriver {
  /// The PBKDF2 configuration.
  final KeyDerivationPbkdf2 config;

  final Random _secureRandom = Random.secure();

  /// Creates a PBKDF2 key deriver with the given configuration.
  ///
  /// If no config is provided, uses OWASP 2023 recommended defaults:
  /// - 310,000 iterations
  /// - HMAC-SHA256
  /// - 32-byte key length
  /// - 16-byte salt length
  Pbkdf2KeyDeriver({
    KeyDerivationPbkdf2? config,
  }) : config = config ??
            const KeyDerivationConfig.pbkdf2() as KeyDerivationPbkdf2;

  @override
  Future<DerivedKey> deriveKey({
    required String password,
    Uint8List? salt,
  }) async {
    // Generate salt if not provided
    salt ??= generateSalt(config.saltLength);

    // Create PBKDF2 instance with appropriate MAC algorithm
    final pbkdf2 = Pbkdf2(
      macAlgorithm: _getMacAlgorithm(),
      iterations: config.iterations,
      bits: config.keyLength * 8, // Convert bytes to bits
    );

    // Derive the key
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final keyBytes = await secretKey.extractBytes();

    return DerivedKey(
      keyBytes: Uint8List.fromList(keyBytes),
      salt: salt,
      algorithm: _getAlgorithmName(),
      params: {
        'iterations': config.iterations,
        'hashAlgorithm': _getHashAlgorithmName(),
        'keyLength': config.keyLength,
      },
    );
  }

  @override
  Uint8List generateSalt([int? length]) {
    length ??= config.saltLength;
    final salt = Uint8List(length);
    for (var i = 0; i < length; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }
    return salt;
  }

  /// Returns the MAC algorithm for PBKDF2 based on configuration.
  MacAlgorithm _getMacAlgorithm() {
    return switch (config.hashAlgorithm) {
      KdfHashAlgorithm.sha256 => Hmac.sha256(),
      KdfHashAlgorithm.sha512 => Hmac.sha512(),
    };
  }

  /// Returns the algorithm name string for the derived key metadata.
  String _getAlgorithmName() {
    return switch (config.hashAlgorithm) {
      KdfHashAlgorithm.sha256 => 'pbkdf2-sha256',
      KdfHashAlgorithm.sha512 => 'pbkdf2-sha512',
    };
  }

  /// Returns the hash algorithm name for params.
  String _getHashAlgorithmName() {
    return switch (config.hashAlgorithm) {
      KdfHashAlgorithm.sha256 => 'sha256',
      KdfHashAlgorithm.sha512 => 'sha512',
    };
  }
}
