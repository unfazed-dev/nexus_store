import 'dart:async';

import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/query/query.dart';

/// Handles fetch operations according to the configured [FetchPolicy].
///
/// This class abstracts the complexity of cache-vs-network decisions,
/// allowing the store to simply delegate read operations.
class FetchPolicyHandler<T, ID> {
  /// Creates a fetch policy handler.
  FetchPolicyHandler({
    required this.backend,
    required this.defaultPolicy,
    this.staleDuration,
    Map<ID, DateTime>? lastFetchTimes,
  }) : _lastFetchTimes = lastFetchTimes ?? {};

  /// The storage backend.
  final StoreBackend<T, ID> backend;

  /// Default policy when none is specified.
  final FetchPolicy defaultPolicy;

  /// Duration after which cached data is considered stale.
  final Duration? staleDuration;

  /// Tracks when each entity was last fetched from network.
  final Map<ID, DateTime> _lastFetchTimes;

  /// Gets a single entity according to the [policy].
  Future<T?> get(ID id, {FetchPolicy? policy}) async {
    final effectivePolicy = policy ?? defaultPolicy;

    return switch (effectivePolicy) {
      FetchPolicy.cacheFirst => _getCacheFirst(id),
      FetchPolicy.networkFirst => _getNetworkFirst(id),
      FetchPolicy.cacheAndNetwork => _getCacheAndNetwork(id),
      FetchPolicy.cacheOnly => backend.get(id),
      FetchPolicy.networkOnly => _getNetworkOnly(id),
      FetchPolicy.staleWhileRevalidate => _getStaleWhileRevalidate(id),
    };
  }

  /// Gets all entities matching [query] according to the [policy].
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy}) async {
    final effectivePolicy = policy ?? defaultPolicy;

    return switch (effectivePolicy) {
      FetchPolicy.cacheFirst => _getAllCacheFirst(query),
      FetchPolicy.networkFirst => _getAllNetworkFirst(query),
      FetchPolicy.cacheAndNetwork => _getAllCacheAndNetwork(query),
      FetchPolicy.cacheOnly => backend.getAll(query: query),
      FetchPolicy.networkOnly => _getAllNetworkOnly(query),
      FetchPolicy.staleWhileRevalidate => _getAllStaleWhileRevalidate(query),
    };
  }

  /// Watches a single entity with cache-and-network behavior.
  ///
  /// Emits cached value immediately, then network updates.
  Stream<T?> watch(ID id) => backend.watch(id);

  /// Watches all entities matching [query] with cache-and-network behavior.
  Stream<List<T>> watchAll({Query<T>? query}) => backend.watchAll(query: query);

  // ---------------------------------------------------------------------------
  // Cache-First Strategy
  // ---------------------------------------------------------------------------

  Future<T?> _getCacheFirst(ID id) async {
    final cached = await backend.get(id);
    if (cached != null && !_isStale(id)) {
      return cached;
    }

    // Cache miss or stale, try network
    try {
      await backend.sync();
      _lastFetchTimes[id] = DateTime.now();
      return backend.get(id);
    } on Object {
      // Network failed, return whatever we have
      return cached;
    }
  }

  Future<List<T>> _getAllCacheFirst(Query<T>? query) async {
    final cached = await backend.getAll(query: query);
    if (cached.isNotEmpty) {
      return cached;
    }

    // Empty cache, try network
    try {
      await backend.sync();
      return backend.getAll(query: query);
    } on Object {
      return cached;
    }
  }

  // ---------------------------------------------------------------------------
  // Network-First Strategy
  // ---------------------------------------------------------------------------

  Future<T?> _getNetworkFirst(ID id) async {
    try {
      await backend.sync();
      _lastFetchTimes[id] = DateTime.now();
      return backend.get(id);
    } on Object {
      // Network failed, fallback to cache
      return backend.get(id);
    }
  }

  Future<List<T>> _getAllNetworkFirst(Query<T>? query) async {
    try {
      await backend.sync();
      return backend.getAll(query: query);
    } on Object {
      return backend.getAll(query: query);
    }
  }

  // ---------------------------------------------------------------------------
  // Cache-And-Network Strategy
  // ---------------------------------------------------------------------------

  Future<T?> _getCacheAndNetwork(ID id) async {
    // For single get, just return network result (use watch for streaming)
    final cached = await backend.get(id);

    try {
      await backend.sync();
      _lastFetchTimes[id] = DateTime.now();
      return backend.get(id);
    } on Object {
      return cached;
    }
  }

  Future<List<T>> _getAllCacheAndNetwork(Query<T>? query) async {
    try {
      await backend.sync();
      return backend.getAll(query: query);
    } on Object {
      return backend.getAll(query: query);
    }
  }

  // ---------------------------------------------------------------------------
  // Network-Only Strategy
  // ---------------------------------------------------------------------------

  Future<T?> _getNetworkOnly(ID id) async {
    await backend.sync();
    _lastFetchTimes[id] = DateTime.now();
    return backend.get(id);
  }

  Future<List<T>> _getAllNetworkOnly(Query<T>? query) async {
    await backend.sync();
    return backend.getAll(query: query);
  }

  // ---------------------------------------------------------------------------
  // Stale-While-Revalidate Strategy
  // ---------------------------------------------------------------------------

  Future<T?> _getStaleWhileRevalidate(ID id) async {
    final cached = await backend.get(id);

    // Return stale data immediately
    if (cached != null) {
      // Trigger background revalidation
      unawaited(_revalidateInBackground(id));
      return cached;
    }

    // No cache, must wait for network
    await backend.sync();
    _lastFetchTimes[id] = DateTime.now();
    return backend.get(id);
  }

  Future<List<T>> _getAllStaleWhileRevalidate(Query<T>? query) async {
    final cached = await backend.getAll(query: query);

    if (cached.isNotEmpty) {
      // Trigger background revalidation
      unawaited(_revalidateAllInBackground());
      return cached;
    }

    await backend.sync();
    return backend.getAll(query: query);
  }

  Future<void> _revalidateInBackground(ID id) async {
    try {
      await backend.sync();
      _lastFetchTimes[id] = DateTime.now();
    } on Object {
      // Silently ignore background revalidation failures
    }
  }

  Future<void> _revalidateAllInBackground() async {
    try {
      await backend.sync();
    } on Object {
      // Silently ignore background revalidation failures
    }
  }

  // ---------------------------------------------------------------------------
  // Staleness Detection
  // ---------------------------------------------------------------------------

  bool _isStale(ID id) {
    if (staleDuration == null) return false;

    final lastFetch = _lastFetchTimes[id];
    if (lastFetch == null) return true;

    return DateTime.now().difference(lastFetch) > staleDuration!;
  }

  /// Marks an entity as stale, forcing next fetch to hit network.
  void invalidate(ID id) {
    _lastFetchTimes.remove(id);
  }

  /// Marks all entities as stale.
  void invalidateAll() {
    _lastFetchTimes.clear();
  }
}
