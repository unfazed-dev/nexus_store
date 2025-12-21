import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:nexus_store/src/security/derived_key.dart';
import 'package:nexus_store/src/security/key_derivation_config.dart';
import 'package:nexus_store/src/security/key_deriver.dart';
import 'package:nexus_store/src/security/pbkdf2_key_deriver.dart';
import 'package:nexus_store/src/security/salt_storage.dart';

/// Service for deriving cryptographic keys from passwords.
///
/// Coordinates key derivation with salt storage and provides a
/// unified interface for different key derivation algorithms.
///
/// ## Usage Examples
///
/// ### Basic Key Derivation
/// ```dart
/// final service = KeyDerivationService(
///   config: KeyDerivationConfig.pbkdf2(iterations: 310000),
/// );
///
/// final derivedKey = await service.deriveKey(
///   password: 'user-password',
/// );
/// // Use derivedKey.keyBytes for encryption
/// // Store derivedKey.salt securely
/// ```
///
/// ### With Salt Storage
/// ```dart
/// final service = KeyDerivationService(
///   config: KeyDerivationConfig.pbkdf2(),
///   saltStorage: SecureStorageSaltProvider(), // Your implementation
/// );
///
/// // First call generates and stores salt
/// final key1 = await service.deriveKey(
///   password: 'user-password',
///   keyId: 'user-123-encryption',
/// );
///
/// // Subsequent calls reuse stored salt
/// final key2 = await service.deriveKey(
///   password: 'user-password',
///   keyId: 'user-123-encryption',
/// );
///
/// assert(key1.keyBytes == key2.keyBytes); // Same key!
/// ```
class KeyDerivationService {
  /// The key derivation configuration.
  final KeyDerivationConfig config;

  /// Optional salt storage for persisting salts.
  final SaltStorage? saltStorage;

  late final KeyDeriver? _deriver;
  final Random _secureRandom = Random.secure();

  /// Creates a key derivation service with the given configuration.
  ///
  /// - [config]: Key derivation algorithm configuration.
  /// - [saltStorage]: Optional storage for persisting salts.
  KeyDerivationService({
    required this.config,
    this.saltStorage,
  }) {
    _deriver = _createDeriver();
  }

  /// Creates the appropriate key deriver based on configuration.
  KeyDeriver? _createDeriver() {
    return switch (config) {
      KeyDerivationPbkdf2 pbkdf2Config => Pbkdf2KeyDeriver(config: pbkdf2Config),
      KeyDerivationRaw() => null, // No deriver needed for raw keys
    };
  }

  /// Derives a cryptographic key from a password.
  ///
  /// - [password]: The password or passphrase to derive from.
  /// - [salt]: Optional explicit salt. If not provided:
  ///   - If [keyId] is set and salt exists in storage, uses stored salt.
  ///   - Otherwise, generates a new random salt.
  /// - [keyId]: Optional identifier for salt storage/retrieval.
  ///
  /// Returns a [DerivedKey] containing the derived key bytes, salt,
  /// algorithm identifier, and parameters.
  Future<DerivedKey> deriveKey({
    required String password,
    Uint8List? salt,
    String? keyId,
  }) async {
    // Handle raw key mode
    if (config is KeyDerivationRaw) {
      return _handleRawKey(password);
    }

    // Resolve salt: explicit > stored > generated
    salt ??= await _resolveSalt(keyId);

    // Derive the key
    final derivedKey = await _deriver!.deriveKey(
      password: password,
      salt: salt,
    );

    // Store salt if keyId provided and storage available
    if (keyId != null && saltStorage != null) {
      await saltStorage!.storeSalt(keyId, derivedKey.salt);
    }

    return derivedKey;
  }

  /// Resolves salt from storage or generates new salt.
  Future<Uint8List?> _resolveSalt(String? keyId) async {
    if (keyId != null && saltStorage != null) {
      final storedSalt = await saltStorage!.getSalt(keyId);
      if (storedSalt != null) {
        return storedSalt;
      }
    }
    return null; // Let the deriver generate salt
  }

  /// Handles raw key mode - no derivation, just encoding.
  DerivedKey _handleRawKey(String password) {
    final keyBytes = utf8.encode(password);
    // Ensure key is exactly 32 bytes for AES-256
    final normalizedKey = Uint8List(32);
    for (var i = 0; i < 32 && i < keyBytes.length; i++) {
      normalizedKey[i] = keyBytes[i];
    }

    return DerivedKey(
      keyBytes: normalizedKey,
      salt: Uint8List(0), // No salt for raw keys
      algorithm: 'raw',
      params: {},
    );
  }

  /// Generates a random salt of the configured length.
  ///
  /// - [length]: Optional custom length. If not provided, uses
  ///   the configured salt length for PBKDF2, or 16 bytes default.
  Uint8List generateSalt([int? length]) {
    length ??= switch (config) {
      KeyDerivationPbkdf2 pbkdf2Config => pbkdf2Config.saltLength,
      KeyDerivationRaw() => 16,
    };

    final salt = Uint8List(length);
    for (var i = 0; i < length; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }
    return salt;
  }

  /// Clears any cached keys or state.
  ///
  /// Should be called when the service is no longer needed.
  void dispose() {
    // Currently no caching, but reserved for future use
  }

  /// Generates cryptographically secure random bytes.
  ///
  /// Static utility method for generating random salts.
  ///
  /// - [length]: Number of bytes to generate. Default: 16.
  static Uint8List generateSecureRandomSalt([int length = 16]) {
    final random = Random.secure();
    final salt = Uint8List(length);
    for (var i = 0; i < length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }
}
