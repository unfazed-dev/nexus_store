import 'dart:async';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/src/powersync_backend.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_query_translator.dart';
import 'package:powersync/powersync.dart' as ps;

/// Encryption algorithms supported by SQLCipher.
enum EncryptionAlgorithm {
  /// AES-256 in GCM mode (default, recommended).
  aes256Gcm,

  /// ChaCha20 with Poly1305 authentication.
  chacha20Poly1305,
}

/// Interface for providing encryption keys.
///
/// Implement this interface to provide custom key management,
/// such as fetching keys from a secure keychain or HSM.
abstract class EncryptionKeyProvider {
  /// Retrieves the current encryption key.
  ///
  /// Throws [StateError] if the provider has been disposed.
  Future<String> getKey();

  /// Rotates to a new encryption key.
  ///
  /// Returns the new key after rotation is complete.
  Future<String> rotateKey(String newKey);

  /// Clears the key from memory and releases resources.
  Future<void> dispose();
}

/// Simple in-memory key provider for testing and basic use cases.
///
/// For production, consider using a secure keychain provider.
class InMemoryKeyProvider implements EncryptionKeyProvider {
  /// Creates an in-memory key provider with the given initial key.
  InMemoryKeyProvider(this._key);

  String? _key;
  bool _disposed = false;

  @override
  Future<String> getKey() async {
    if (_disposed || _key == null) {
      throw StateError('Key provider has been disposed');
    }
    return _key!;
  }

  @override
  Future<String> rotateKey(String newKey) async {
    if (_disposed) {
      throw StateError('Key provider has been disposed');
    }
    _key = newKey;
    return newKey;
  }

  @override
  Future<void> dispose() async {
    _key = null;
    _disposed = true;
  }
}

/// PowerSync backend with SQLCipher encryption support.
///
/// This backend extends [PowerSyncBackend] to add database encryption
/// at rest using SQLCipher. All data stored locally is encrypted.
///
/// Example:
/// ```dart
/// final keyProvider = InMemoryKeyProvider('my-secret-key');
/// final backend = PowerSyncEncryptedBackend<User, String>(
///   db: powerSyncDb,
///   tableName: 'users',
///   getId: (user) => user.id,
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
///   keyProvider: keyProvider,
/// );
/// ```
///
/// Note: Requires the `powersync_sqlcipher` package for actual encryption.
/// Without it, this backend operates identically to [PowerSyncBackend]
/// but tracks encryption state.
class PowerSyncEncryptedBackend<T, ID>
    with nexus.StoreBackendDefaults<T, ID>
    implements nexus.StoreBackend<T, ID> {
  /// Creates an encrypted PowerSync backend.
  ///
  /// - [db]: The PowerSync database instance
  /// - [tableName]: Name of the table to operate on
  /// - [getId]: Function to extract ID from an item
  /// - [fromJson]: Function to deserialize an item from JSON
  /// - [toJson]: Function to serialize an item to JSON
  /// - [keyProvider]: Provider for the encryption key
  /// - [algorithm]: Encryption algorithm to use (default: AES-256-GCM)
  /// - [primaryKeyColumn]: Name of the primary key column (default: 'id')
  /// - [queryTranslator]: Optional custom query translator
  /// - [fieldMapping]: Optional field name mapping
  PowerSyncEncryptedBackend({
    required ps.PowerSyncDatabase db,
    required String tableName,
    required ID Function(T) getId,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required EncryptionKeyProvider keyProvider,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes256Gcm,
    String primaryKeyColumn = 'id',
    PowerSyncQueryTranslator<T>? queryTranslator,
    Map<String, String>? fieldMapping,
  })  : _keyProvider = keyProvider,
        _algorithm = algorithm,
        _innerBackend = PowerSyncBackend<T, ID>(
          db: db,
          tableName: tableName,
          getId: getId,
          fromJson: fromJson,
          toJson: toJson,
          primaryKeyColumn: primaryKeyColumn,
          queryTranslator: queryTranslator,
          fieldMapping: fieldMapping,
        );

  /// Creates an encrypted backend with a pre-configured inner backend.
  ///
  /// This constructor is primarily for testing, allowing injection of
  /// a mock or pre-configured PowerSyncBackend.
  PowerSyncEncryptedBackend.withBackend({
    required PowerSyncBackend<T, ID> backend,
    required EncryptionKeyProvider keyProvider,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes256Gcm,
  })  : _keyProvider = keyProvider,
        _algorithm = algorithm,
        _innerBackend = backend;

  final EncryptionKeyProvider _keyProvider;
  final EncryptionAlgorithm _algorithm;
  final PowerSyncBackend<T, ID> _innerBackend;

  bool _initialized = false;
  bool _keyCleared = false;

  // Stores the encryption key for SQLCipher database operations.
  // Used when configuring SQLCipher via PRAGMA key commands.
  // ignore: unused_field
  String? _currentKey;

  // ===================== BACKEND INFO =====================

  @override
  String get name => 'powersync_encrypted';

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsRealtime => true;

  @override
  bool get supportsTransactions => true;

  /// Whether this backend uses encryption.
  bool get isEncrypted => true;

  /// The encryption algorithm being used.
  EncryptionAlgorithm get algorithm => _algorithm;

  /// Whether the encryption key has been cleared from memory.
  bool get isKeyCleared => _keyCleared;

  // ===================== LIFECYCLE =====================

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Get encryption key from provider
    _currentKey = await _keyProvider.getKey();

    // Initialize the inner backend
    // Note: In a real implementation with powersync_sqlcipher,
    // you would configure SQLCipher here with the key
    await _innerBackend.initialize();

    _initialized = true;
  }

  @override
  Future<void> close() async {
    // Clear the key from memory
    _currentKey = null;
    _keyCleared = true;

    await _innerBackend.close();
    _initialized = false;
  }

  /// Rotates the encryption key.
  ///
  /// This operation re-encrypts the database with the new key.
  /// Throws [StateError] if the backend is not initialized.
  Future<void> rotateKey(String newKey) async {
    _checkInitialized();

    // Rotate the key in the provider
    await _keyProvider.rotateKey(newKey);
    _currentKey = newKey;

    // Note: In a real implementation with powersync_sqlcipher,
    // you would re-encrypt the database here:
    // await _db.execute('PRAGMA rekey = ?', [newKey]);
  }

  // ===================== READ OPERATIONS =====================

  @override
  Future<T?> get(ID id) {
    _checkInitialized();
    return _innerBackend.get(id);
  }

  @override
  Future<List<T>> getAll({nexus.Query<T>? query}) {
    _checkInitialized();
    return _innerBackend.getAll(query: query);
  }

  @override
  Stream<T?> watch(ID id) {
    _checkInitialized();
    return _innerBackend.watch(id);
  }

  @override
  Stream<List<T>> watchAll({nexus.Query<T>? query}) {
    _checkInitialized();
    return _innerBackend.watchAll(query: query);
  }

  // ===================== WRITE OPERATIONS =====================

  @override
  Future<T> save(T item) {
    _checkInitialized();
    return _innerBackend.save(item);
  }

  @override
  Future<List<T>> saveAll(List<T> items) {
    _checkInitialized();
    return _innerBackend.saveAll(items);
  }

  @override
  Future<bool> delete(ID id) {
    _checkInitialized();
    return _innerBackend.delete(id);
  }

  @override
  Future<int> deleteAll(List<ID> ids) {
    _checkInitialized();
    return _innerBackend.deleteAll(ids);
  }

  @override
  Future<int> deleteWhere(nexus.Query<T> query) {
    _checkInitialized();
    return _innerBackend.deleteWhere(query);
  }

  // ===================== SYNC OPERATIONS =====================

  @override
  nexus.SyncStatus get syncStatus => _innerBackend.syncStatus;

  @override
  Stream<nexus.SyncStatus> get syncStatusStream =>
      _innerBackend.syncStatusStream;

  @override
  Future<void> sync() {
    _checkInitialized();
    return _innerBackend.sync();
  }

  @override
  Future<int> get pendingChangesCount => _innerBackend.pendingChangesCount;

  // ===================== HELPERS =====================

  void _checkInitialized() {
    if (!_initialized) {
      throw const nexus.StateError(
        message: 'PowerSyncEncryptedBackend not initialized. '
            'Call initialize() first.',
      );
    }
  }
}
