import 'dart:async';

import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/errors/store_errors.dart';

/// Handles write operations according to the configured [WritePolicy].
///
/// This class manages the coordination between local cache writes and
/// network synchronization based on the policy.
class WritePolicyHandler<T, ID> {
  /// Creates a write policy handler.
  WritePolicyHandler({
    required this.backend,
    required this.defaultPolicy,
  });

  /// The storage backend.
  final StoreBackend<T, ID> backend;

  /// Default policy when none is specified.
  final WritePolicy defaultPolicy;

  /// Saves an entity according to the [policy].
  ///
  /// Returns the saved entity, which may include server-generated fields.
  Future<T> save(T item, {WritePolicy? policy}) async {
    final effectivePolicy = policy ?? defaultPolicy;

    return switch (effectivePolicy) {
      WritePolicy.cacheAndNetwork => _saveCacheAndNetwork(item),
      WritePolicy.networkFirst => _saveNetworkFirst(item),
      WritePolicy.cacheFirst => _saveCacheFirst(item),
      WritePolicy.cacheOnly => backend.save(item),
    };
  }

  /// Saves multiple entities according to the [policy].
  Future<List<T>> saveAll(List<T> items, {WritePolicy? policy}) async {
    final effectivePolicy = policy ?? defaultPolicy;

    return switch (effectivePolicy) {
      WritePolicy.cacheAndNetwork => _saveAllCacheAndNetwork(items),
      WritePolicy.networkFirst => _saveAllNetworkFirst(items),
      WritePolicy.cacheFirst => _saveAllCacheFirst(items),
      WritePolicy.cacheOnly => backend.saveAll(items),
    };
  }

  /// Deletes an entity according to the [policy].
  ///
  /// Returns `true` if the entity was deleted.
  Future<bool> delete(ID id, {WritePolicy? policy}) async {
    final effectivePolicy = policy ?? defaultPolicy;

    return switch (effectivePolicy) {
      WritePolicy.cacheAndNetwork => _deleteCacheAndNetwork(id),
      WritePolicy.networkFirst => _deleteNetworkFirst(id),
      WritePolicy.cacheFirst => _deleteCacheFirst(id),
      WritePolicy.cacheOnly => backend.delete(id),
    };
  }

  // ---------------------------------------------------------------------------
  // Cache-And-Network Strategy (Optimistic)
  // ---------------------------------------------------------------------------

  Future<T> _saveCacheAndNetwork(T item) async {
    // Optimistic: save to cache first
    final saved = await backend.save(item);

    // Then sync to network
    try {
      await backend.sync();
      return saved;
    } on StoreError {
      // Sync failed, but local save succeeded
      // Item will be synced later when connection is restored
      rethrow;
    }
  }

  Future<List<T>> _saveAllCacheAndNetwork(List<T> items) async {
    final saved = await backend.saveAll(items);

    try {
      await backend.sync();
      return saved;
    } on StoreError {
      rethrow;
    }
  }

  Future<bool> _deleteCacheAndNetwork(ID id) async {
    final deleted = await backend.delete(id);

    try {
      await backend.sync();
      return deleted;
    } on StoreError {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Network-First Strategy (Consistent)
  // ---------------------------------------------------------------------------

  Future<T> _saveNetworkFirst(T item) async {
    // Save to cache to queue for sync
    final saved = await backend.save(item);

    // Wait for sync to complete
    await backend.sync();

    // Return the latest version (may have server changes)
    return saved;
  }

  Future<List<T>> _saveAllNetworkFirst(List<T> items) async {
    final saved = await backend.saveAll(items);
    await backend.sync();
    return saved;
  }

  Future<bool> _deleteNetworkFirst(ID id) async {
    final deleted = await backend.delete(id);
    await backend.sync();
    return deleted;
  }

  // ---------------------------------------------------------------------------
  // Cache-First Strategy (Offline-First)
  // ---------------------------------------------------------------------------

  Future<T> _saveCacheFirst(T item) async {
    // Save locally only, sync will happen later
    final saved = await backend.save(item);

    // Schedule background sync (non-blocking)
    unawaited(_syncInBackground());

    return saved;
  }

  Future<List<T>> _saveAllCacheFirst(List<T> items) async {
    final saved = await backend.saveAll(items);
    unawaited(_syncInBackground());
    return saved;
  }

  Future<bool> _deleteCacheFirst(ID id) async {
    final deleted = await backend.delete(id);
    unawaited(_syncInBackground());
    return deleted;
  }

  Future<void> _syncInBackground() async {
    try {
      await backend.sync();
    } catch (_) {
      // Silently ignore background sync failures
      // Changes will be synced on next opportunity
    }
  }
}
