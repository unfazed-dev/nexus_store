import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_derivation_config.freezed.dart';

/// Hash algorithm for key derivation functions.
enum KdfHashAlgorithm {
  /// HMAC-SHA256 - recommended for most use cases.
  sha256,

  /// HMAC-SHA512 - for higher security requirements.
  sha512,
}

/// Configuration for key derivation in NexusStore.
///
/// Supports secure key derivation from passwords/passphrases
/// using industry-standard algorithms.
///
/// ## Usage Examples
///
/// ### PBKDF2 Key Derivation
/// ```dart
/// final config = EncryptionConfig.fieldLevel(
///   encryptedFields: {'ssn', 'medicalRecord'},
///   keyProvider: () => getUserPassword(),
///   keyDerivation: KeyDerivationConfig.pbkdf2(
///     iterations: 310000, // OWASP 2023 recommendation
///     hashAlgorithm: KdfHashAlgorithm.sha256,
///   ),
/// );
/// ```
///
/// ### Raw Key (Pre-derived)
/// ```dart
/// final config = EncryptionConfig.fieldLevel(
///   encryptedFields: {'ssn'},
///   keyProvider: () => getPreDerivedKey(),
///   keyDerivation: KeyDerivationConfig.raw(),
/// );
/// ```
@freezed
sealed class KeyDerivationConfig with _$KeyDerivationConfig {
  const KeyDerivationConfig._();

  /// PBKDF2 key derivation with configurable parameters.
  ///
  /// Uses PBKDF2 (Password-Based Key Derivation Function 2) with
  /// HMAC-SHA256 or HMAC-SHA512.
  ///
  /// - [iterations]: Number of iterations. OWASP 2023 recommends
  ///   310,000 for HMAC-SHA256. Minimum: 100,000.
  /// - [hashAlgorithm]: Hash algorithm for HMAC.
  /// - [keyLength]: Output key length in bytes. Default: 32 (256 bits).
  /// - [saltLength]: Salt length in bytes. Minimum: 16 (128 bits).
  const factory KeyDerivationConfig.pbkdf2({
    /// Number of PBKDF2 iterations.
    /// OWASP 2023 recommends 310,000 for HMAC-SHA256.
    @Default(310000) int iterations,

    /// Hash algorithm for HMAC (SHA-256 or SHA-512).
    @Default(KdfHashAlgorithm.sha256) KdfHashAlgorithm hashAlgorithm,

    /// Output key length in bytes. Default: 32 (256 bits for AES-256).
    @Default(32) int keyLength,

    /// Salt length in bytes. Minimum recommended: 16 (128 bits).
    @Default(16) int saltLength,
  }) = KeyDerivationPbkdf2;

  /// Raw key mode - no key derivation.
  ///
  /// Use this when the key is already derived or for testing.
  /// The keyProvider should return the actual encryption key.
  const factory KeyDerivationConfig.raw() = KeyDerivationRaw;

  /// Returns `true` if this is PBKDF2 key derivation.
  bool get isPbkdf2 => this is KeyDerivationPbkdf2;

  /// Returns `true` if this is raw key mode (no derivation).
  bool get isRaw => this is KeyDerivationRaw;

  /// Minimum recommended iterations for PBKDF2.
  static const int minimumIterations = 100000;

  /// OWASP 2023 recommended iterations for PBKDF2-HMAC-SHA256.
  static const int recommendedIterations = 310000;

  /// Minimum recommended salt length in bytes.
  static const int minimumSaltLength = 16;
}
