import 'dart:typed_data';

import 'package:nexus_store/src/security/derived_key.dart';

/// Abstract interface for key derivation implementations.
///
/// Provides a common interface for different key derivation algorithms
/// (PBKDF2, Argon2, scrypt, etc.).
///
/// ## Implementing Custom Key Derivers
///
/// To implement a custom key deriver (e.g., Argon2):
///
/// ```dart
/// class Argon2KeyDeriver implements KeyDeriver {
///   @override
///   Future<DerivedKey> deriveKey({
///     required String password,
///     Uint8List? salt,
///   }) async {
///     salt ??= generateSalt();
///     // Use argon2 package or FFI implementation
///     final keyBytes = await argon2id.deriveKey(...);
///     return DerivedKey(
///       keyBytes: keyBytes,
///       salt: salt,
///       algorithm: 'argon2id',
///       params: {...},
///     );
///   }
///
///   @override
///   Uint8List generateSalt([int length = 16]) {
///     // Implementation
///   }
/// }
/// ```
abstract class KeyDeriver {
  /// Derives a cryptographic key from a password.
  ///
  /// - [password]: The password or passphrase to derive from.
  /// - [salt]: Optional salt bytes. If not provided, a new salt will be
  ///   generated using [generateSalt].
  ///
  /// Returns a [DerivedKey] containing the derived key bytes, salt,
  /// algorithm identifier, and parameters.
  Future<DerivedKey> deriveKey({
    required String password,
    Uint8List? salt,
  });

  /// Generates cryptographically secure random salt.
  ///
  /// - [length]: Salt length in bytes. Default is implementation-specific
  ///   (typically 16 bytes / 128 bits).
  ///
  /// Returns a [Uint8List] of random bytes suitable for use as salt.
  Uint8List generateSalt([int length]);
}
