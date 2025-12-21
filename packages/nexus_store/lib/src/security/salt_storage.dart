import 'dart:typed_data';

/// Abstract interface for storing and retrieving salt values.
///
/// Salt storage is essential for key derivation - the salt must be
/// stored securely and retrieved when deriving the same key again.
///
/// ## Implementations
///
/// - [InMemorySaltStorage]: Non-persistent storage for testing
/// - For production, implement using `flutter_secure_storage` or similar
///
/// ## Usage Example
///
/// ```dart
/// final storage = InMemorySaltStorage();
///
/// // Store salt for a user's encryption key
/// await storage.storeSalt('user-123-field-encryption', salt);
///
/// // Later, retrieve salt to derive the same key
/// final storedSalt = await storage.getSalt('user-123-field-encryption');
/// if (storedSalt != null) {
///   final key = await deriver.deriveKey(password: pwd, salt: storedSalt);
/// }
/// ```
abstract class SaltStorage {
  /// Retrieves the salt for the given key ID.
  ///
  /// Returns `null` if no salt exists for this key ID.
  Future<Uint8List?> getSalt(String keyId);

  /// Stores a salt for the given key ID.
  ///
  /// If a salt already exists for this key ID, it will be overwritten.
  Future<void> storeSalt(String keyId, Uint8List salt);

  /// Checks if a salt exists for the given key ID.
  Future<bool> hasSalt(String keyId);

  /// Deletes the salt for the given key ID.
  ///
  /// Does nothing if the key ID does not exist.
  Future<void> deleteSalt(String keyId);
}

/// In-memory salt storage for testing purposes.
///
/// **Warning**: This implementation is NOT persistent. Salts will be
/// lost when the application restarts. For production use, implement
/// [SaltStorage] using persistent secure storage like `flutter_secure_storage`.
///
/// ## Example
///
/// ```dart
/// // In tests
/// final storage = InMemorySaltStorage();
/// await storage.storeSalt('test-key', salt);
///
/// // Later
/// final retrievedSalt = await storage.getSalt('test-key');
/// ```
class InMemorySaltStorage implements SaltStorage {
  final Map<String, Uint8List> _storage = {};

  @override
  Future<Uint8List?> getSalt(String keyId) async {
    return _storage[keyId];
  }

  @override
  Future<void> storeSalt(String keyId, Uint8List salt) async {
    _storage[keyId] = salt;
  }

  @override
  Future<bool> hasSalt(String keyId) async {
    return _storage.containsKey(keyId);
  }

  @override
  Future<void> deleteSalt(String keyId) async {
    _storage.remove(keyId);
  }

  /// Clears all stored salts.
  ///
  /// Useful for testing teardown.
  Future<void> clear() async {
    _storage.clear();
  }

  /// Returns all stored key IDs.
  ///
  /// Useful for debugging or testing.
  Future<List<String>> get keys async {
    return _storage.keys.toList();
  }
}
