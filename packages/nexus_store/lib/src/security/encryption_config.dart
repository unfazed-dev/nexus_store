import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/security/encryption_algorithm.dart';

part 'encryption_config.freezed.dart';

/// Configuration for encryption in NexusStore.
///
/// Three encryption modes are supported:
///
/// 1. **None**: No encryption (default)
/// 2. **SQLCipher**: Full database encryption at rest (AES-256)
/// 3. **Field-Level**: Selective field encryption with configurable algorithm
///
/// ## Usage Examples
///
/// ### No Encryption
/// ```dart
/// final config = StoreConfig(
///   encryption: EncryptionConfig.none(),
/// );
/// ```
///
/// ### SQLCipher (Database-Level)
/// ```dart
/// final config = StoreConfig(
///   encryption: EncryptionConfig.sqlCipher(
///     keyProvider: () async => await secureStorage.read('db_key'),
///     kdfIterations: 256000,
///   ),
/// );
/// ```
///
/// ### Field-Level Encryption
/// ```dart
/// final config = StoreConfig(
///   encryption: EncryptionConfig.fieldLevel(
///     encryptedFields: {'ssn', 'email', 'phone'},
///     keyProvider: () async => await keyVault.getKey(),
///     algorithm: EncryptionAlgorithm.aes256Gcm,
///   ),
/// );
/// ```
@freezed
sealed class EncryptionConfig with _$EncryptionConfig {
  const EncryptionConfig._();

  /// No encryption.
  const factory EncryptionConfig.none() = EncryptionNone;

  /// SQLCipher database-level encryption (AES-256).
  ///
  /// Encrypts the entire database file. Requires backend support
  /// (e.g., powersync_sqlcipher).
  ///
  /// - [keyProvider]: Callback to retrieve the encryption key.
  ///   Should return a secure key (32 bytes for AES-256).
  /// - [kdfIterations]: PBKDF2 iterations for key derivation.
  ///   Higher values are more secure but slower. Default: 256000.
  const factory EncryptionConfig.sqlCipher({
    /// Callback to retrieve the encryption key.
    required Future<String> Function() keyProvider,

    /// PBKDF2 iterations for key derivation.
    @Default(256000) int kdfIterations,
  }) = EncryptionSqlCipher;

  /// Field-level encryption for selective field protection.
  ///
  /// Only encrypts specified fields, leaving others in plaintext.
  /// Useful for HIPAA/PII compliance where only certain data needs protection.
  ///
  /// - [encryptedFields]: Set of field names to encrypt.
  /// - [keyProvider]: Callback to retrieve the encryption key.
  /// - [algorithm]: Encryption algorithm to use.
  const factory EncryptionConfig.fieldLevel({
    /// Set of field names to encrypt.
    required Set<String> encryptedFields,

    /// Callback to retrieve the encryption key.
    required Future<String> Function() keyProvider,

    /// Encryption algorithm (default: AES-256-GCM).
    @Default(EncryptionAlgorithm.aes256Gcm) EncryptionAlgorithm algorithm,

    /// Version prefix for encrypted values (for key rotation).
    @Default('v1') String version,
  }) = EncryptionFieldLevel;

  /// Returns `true` if encryption is enabled.
  bool get isEnabled => this is! EncryptionNone;

  /// Returns `true` if this is SQLCipher database-level encryption.
  bool get isSqlCipher => this is EncryptionSqlCipher;

  /// Returns `true` if this is field-level encryption.
  bool get isFieldLevel => this is EncryptionFieldLevel;
}
