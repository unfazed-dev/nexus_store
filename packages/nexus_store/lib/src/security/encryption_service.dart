import 'package:nexus_store/src/security/encryption_config.dart';
import 'package:nexus_store/src/security/field_encryptor.dart';

/// Service that coordinates encryption operations across the store.
///
/// Handles encrypting fields before writes and decrypting after reads.
///
/// ## Example
///
/// ```dart
/// final service = EncryptionService(
///   config: EncryptionConfig.fieldLevel(
///     encryptedFields: {'ssn', 'email'},
///     keyProvider: () => secureStorage.getKey(),
///   ),
/// );
///
/// // Encrypt before save
/// final encrypted = await service.encryptFields({'ssn': '123-45-6789'});
/// // Result: {'ssn': 'enc:v1:...'}
///
/// // Decrypt after read
/// final decrypted = await service.decryptFields(encrypted);
/// // Result: {'ssn': '123-45-6789'}
/// ```
class EncryptionService {
  /// Creates an encryption service with the given configuration.
  EncryptionService({required this.config}) {
    if (config case final EncryptionFieldLevel fieldLevel) {
      _encryptor = DefaultFieldEncryptor(config: fieldLevel);
    }
  }

  /// The encryption configuration.
  final EncryptionConfig config;

  FieldEncryptor? _encryptor;

  /// Returns `true` if encryption is enabled.
  bool get isEnabled => config.isEnabled;

  /// Returns `true` if field-level encryption is enabled.
  bool get isFieldLevel => config.isFieldLevel;

  /// Returns the underlying field encryptor, if field-level encryption
  /// is enabled.
  FieldEncryptor? get encryptor => _encryptor;

  /// Encrypts fields in the given data map.
  ///
  /// Only encrypts fields that are configured for encryption.
  /// Non-string values are converted to JSON strings before encryption.
  ///
  /// Returns a new map with encrypted field values.
  Future<Map<String, dynamic>> encryptFields(Map<String, dynamic> data) async {
    if (!isFieldLevel || _encryptor == null) return data;

    final result = Map<String, dynamic>.from(data);

    for (final entry in data.entries) {
      if (_encryptor!.shouldEncrypt(entry.key)) {
        final value = entry.value;
        if (value != null) {
          final stringValue = value is String ? value : value.toString();
          result[entry.key] = await _encryptor!.encrypt(stringValue, entry.key);
        }
      }
    }

    return result;
  }

  /// Decrypts fields in the given data map.
  ///
  /// Only decrypts fields that appear to be encrypted (have the encryption
  /// prefix).
  ///
  /// Returns a new map with decrypted field values.
  Future<Map<String, dynamic>> decryptFields(Map<String, dynamic> data) async {
    if (!isFieldLevel || _encryptor == null) return data;

    final result = Map<String, dynamic>.from(data);

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String && _encryptor!.isEncrypted(value)) {
        result[entry.key] = await _encryptor!.decrypt(value, entry.key);
      }
    }

    return result;
  }

  /// Encrypts a single field value.
  ///
  /// Returns the original value if the field is not configured for encryption.
  Future<String?> encryptField(String fieldName, String? value) async {
    if (!isFieldLevel || _encryptor == null || value == null) return value;
    if (!_encryptor!.shouldEncrypt(fieldName)) return value;
    return _encryptor!.encrypt(value, fieldName);
  }

  /// Decrypts a single field value.
  ///
  /// Returns the original value if it's not encrypted.
  Future<String?> decryptField(String fieldName, String? value) async {
    if (!isFieldLevel || _encryptor == null || value == null) return value;
    if (!_encryptor!.isEncrypted(value)) return value;
    return _encryptor!.decrypt(value, fieldName);
  }

  /// Clears cached encryption state.
  ///
  /// Call after key rotation to ensure new key is used.
  void clearCache() {
    if (_encryptor case final DefaultFieldEncryptor encryptor) {
      encryptor.clearCache();
    }
  }
}
