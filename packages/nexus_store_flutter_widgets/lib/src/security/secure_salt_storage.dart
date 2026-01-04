import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexus_store/nexus_store.dart';

/// Production-ready [SaltStorage] implementation using Flutter Secure Storage.
///
/// This implementation stores salts in the platform's secure storage:
/// - **iOS**: Keychain with configurable accessibility
/// - **Android**: Encrypted SharedPreferences (EncryptedSharedPreferences)
/// - **macOS**: Keychain
/// - **Linux**: libsecret
/// - **Windows**: Windows Credentials Manager
///
/// ## Security Features
///
/// - Salts are stored as hex-encoded strings for safe serialization
/// - Keys are prefixed to avoid collisions with other secure storage data
/// - Platform-specific security options can be configured
///
/// ## Usage
///
/// ```dart
/// final saltStorage = SecureSaltStorage();
///
/// // Use with KeyDerivationService
/// final keyService = KeyDerivationService(
///   config: KeyDerivationConfig.pbkdf2(iterations: 310000),
///   saltStorage: saltStorage,
/// );
///
/// // Derive a key (salt is automatically generated and stored)
/// final key = await keyService.deriveKey(
///   password: userPassword,
///   keyId: 'user-123-field-encryption',
/// );
/// ```
///
/// ## Custom Configuration
///
/// ```dart
/// final saltStorage = SecureSaltStorage(
///   storage: FlutterSecureStorage(
///     aOptions: AndroidOptions(
///       encryptedSharedPreferences: true,
///       resetOnError: true,
///     ),
///     iOptions: IOSOptions(
///       accessibility: KeychainAccessibility.first_unlock,
///       synchronizable: true,  // Sync with iCloud Keychain
///     ),
///   ),
///   keyPrefix: 'myapp_salt_',
/// );
/// ```
class SecureSaltStorage implements SaltStorage {
  /// Creates a [SecureSaltStorage] with optional custom configuration.
  ///
  /// [storage] - Custom FlutterSecureStorage instance. If not provided,
  /// uses default secure storage with recommended settings.
  ///
  /// [keyPrefix] - Prefix for all salt storage keys. Defaults to 'nexus_salt_'.
  /// Use a custom prefix to avoid key collisions if using secure storage
  /// for other purposes in your app.
  SecureSaltStorage({
    FlutterSecureStorage? storage,
    this.keyPrefix = 'nexus_salt_',
  }) : _storage = storage ?? _createDefaultStorage();

  final FlutterSecureStorage _storage;

  /// Prefix applied to all salt storage keys.
  final String keyPrefix;

  /// Creates default secure storage with recommended platform options.
  static FlutterSecureStorage _createDefaultStorage() =>
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          resetOnError: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

  /// Converts a key ID to a storage key with prefix.
  String _storageKey(String keyId) => '$keyPrefix$keyId';

  @override
  Future<Uint8List?> getSalt(String keyId) async {
    try {
      final hexString = await _storage.read(key: _storageKey(keyId));
      if (hexString == null || hexString.isEmpty) {
        return null;
      }
      return _hexToBytes(hexString);
    } on Exception catch (e) {
      debugPrint('SecureSaltStorage: Error reading salt for $keyId: $e');
      return null;
    }
  }

  @override
  Future<void> storeSalt(String keyId, Uint8List salt) async {
    final hexString = _bytesToHex(salt);
    await _storage.write(key: _storageKey(keyId), value: hexString);
  }

  @override
  Future<bool> hasSalt(String keyId) async {
    try {
      return await _storage.containsKey(key: _storageKey(keyId));
    } on Exception catch (e) {
      debugPrint('SecureSaltStorage: Error checking salt for $keyId: $e');
      return false;
    }
  }

  @override
  Future<void> deleteSalt(String keyId) async {
    await _storage.delete(key: _storageKey(keyId));
  }

  /// Deletes all salts managed by this storage instance.
  ///
  /// This only deletes keys with the configured [keyPrefix].
  /// Use with caution in production.
  Future<void> deleteAllSalts() async {
    final allKeys = await _storage.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith(keyPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  /// Lists all salt key IDs stored by this instance.
  ///
  /// Returns key IDs without the prefix.
  Future<List<String>> listSaltKeyIds() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith(keyPrefix))
        .map((key) => key.substring(keyPrefix.length))
        .toList();
  }

  /// Converts bytes to hex string for safe storage.
  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Converts hex string back to bytes.
  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}

/// Extension for convenient encryption setup with secure storage.
extension SecureEncryptionConfigExtension on EncryptionConfig {
  /// Creates a field-level encryption config with secure salt storage.
  ///
  /// This is a convenience factory for production setups.
  ///
  /// ```dart
  /// final config = EncryptionConfig.secureFieldLevel(
  ///   encryptedFields: {'ssn', 'creditCard'},
  ///   keyProvider: () => secureStorage.read(key: 'encryption_key'),
  /// );
  /// ```
  static EncryptionConfig secureFieldLevel({
    required Set<String> encryptedFields,
    required Future<String> Function() keyProvider,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes256Gcm,
    String version = 'v1',
    int pbkdf2Iterations = 310000,
    FlutterSecureStorage? storage,
    String saltKeyPrefix = 'nexus_salt_',
  }) =>
      EncryptionConfig.fieldLevel(
        encryptedFields: encryptedFields,
        keyProvider: keyProvider,
        algorithm: algorithm,
        version: version,
        keyDerivation: KeyDerivationConfig.pbkdf2(
          iterations: pbkdf2Iterations,
        ),
        saltStorage: SecureSaltStorage(
          storage: storage,
          keyPrefix: saltKeyPrefix,
        ),
      );
}
