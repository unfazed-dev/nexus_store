import 'dart:typed_data';

import 'package:collection/collection.dart';

/// Represents a cryptographically derived key with its associated metadata.
///
/// Contains the derived key bytes, salt used for derivation, algorithm
/// identifier, and optional parameters.
///
/// ## Security Notes
///
/// - Call [dispose] when done to zero-fill the key bytes
/// - Never log or serialize the [keyBytes] directly
/// - Store [salt] securely - losing it means losing access to data
///
/// ## Example
///
/// ```dart
/// final derivedKey = await keyDeriver.deriveKey(
///   password: 'user-password',
///   salt: storedSalt,
/// );
///
/// // Use the key for encryption
/// final encryptionKey = SecretKey(derivedKey.keyBytes);
///
/// // Clean up when done
/// derivedKey.dispose();
/// ```
class DerivedKey {
  /// The derived key bytes.
  final Uint8List keyBytes;

  /// The salt used for key derivation.
  final Uint8List salt;

  /// Algorithm identifier (e.g., 'pbkdf2-sha256', 'argon2id').
  final String algorithm;

  /// Additional algorithm parameters.
  final Map<String, dynamic> params;

  bool _isDisposed = false;

  /// Creates a new [DerivedKey] instance.
  ///
  /// - [keyBytes]: The derived key bytes (typically 32 bytes for AES-256).
  /// - [salt]: The salt used during derivation.
  /// - [algorithm]: Algorithm identifier for metadata/verification.
  /// - [params]: Optional algorithm parameters (iterations, memory cost, etc.).
  DerivedKey({
    required this.keyBytes,
    required this.salt,
    required this.algorithm,
    this.params = const {},
  });

  /// Length of the derived key in bytes.
  int get keyLength => keyBytes.length;

  /// Length of the salt in bytes.
  int get saltLength => salt.length;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  /// Securely clears the key bytes from memory.
  ///
  /// After calling dispose:
  /// - [keyBytes] will be zero-filled
  /// - [isDisposed] will return `true`
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_isDisposed) return;

    // Zero-fill the key bytes for security
    for (var i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = 0;
    }

    _isDisposed = true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DerivedKey) return false;

    final listEquals = const ListEquality<int>().equals;
    final mapEquals = const DeepCollectionEquality().equals;

    return listEquals(keyBytes, other.keyBytes) &&
        listEquals(salt, other.salt) &&
        algorithm == other.algorithm &&
        mapEquals(params, other.params);
  }

  @override
  int get hashCode {
    return Object.hash(
      const ListEquality<int>().hash(keyBytes),
      const ListEquality<int>().hash(salt),
      algorithm,
      const DeepCollectionEquality().hash(params),
    );
  }

  @override
  String toString() {
    // Never expose the actual key bytes in toString for security
    return 'DerivedKey(algorithm: $algorithm, keyLength: $keyLength, '
        'saltLength: $saltLength, isDisposed: $isDisposed)';
  }
}
