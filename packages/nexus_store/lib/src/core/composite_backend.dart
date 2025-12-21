import 'dart:async';

import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/core/store_backend.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/paged_result.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/sync/conflict_details.dart';
import 'package:nexus_store/src/sync/pending_change.dart';
import 'package:rxdart/rxdart.dart';

/// A composite backend that combines multiple backends with fallback behavior.
///
/// Useful for:
/// - **Primary/Fallback**: Use PowerSync, fall back to Supabase if offline fails
/// - **Caching**: Read-through cache with primary storage
/// - **Migration**: Transition from one backend to another
///
/// ## Example
///
/// ```dart
/// // Primary PowerSync, fallback to Supabase
/// final backend = CompositeBackend<User, String>(
///   primary: PowerSyncBackend(powerSync),
///   fallback: SupabaseBackend(supabase, 'users'),
/// );
///
/// // With cache layer
/// final backend = CompositeBackend<User, String>(
///   primary: PowerSyncBackend(powerSync),
///   cache: InMemoryCacheBackend(),
/// );
/// ```
class CompositeBackend<T, ID> implements StoreBackend<T, ID> {
  /// Creates a composite backend.
  CompositeBackend({
    required this.primary,
    this.fallback,
    this.cache,
    this.readStrategy = CompositeReadStrategy.primaryFirst,
    this.writeStrategy = CompositeWriteStrategy.primaryOnly,
  });

  /// Primary storage backend.
  final StoreBackend<T, ID> primary;

  /// Fallback backend used when primary fails.
  final StoreBackend<T, ID>? fallback;

  /// Cache layer for read-through caching.
  final StoreBackend<T, ID>? cache;

  /// Strategy for read operations.
  final CompositeReadStrategy readStrategy;

  /// Strategy for write operations.
  final CompositeWriteStrategy writeStrategy;

  final BehaviorSubject<SyncStatus> _syncStatusSubject =
      BehaviorSubject.seeded(SyncStatus.synced);

  // ---------------------------------------------------------------------------
  // Read Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T?> get(ID id) async {
    switch (readStrategy) {
      case CompositeReadStrategy.primaryFirst:
        return _getPrimaryFirst(id);
      case CompositeReadStrategy.cacheFirst:
        return _getCacheFirst(id);
      case CompositeReadStrategy.fastest:
        return _getFastest(id);
    }
  }

  Future<T?> _getPrimaryFirst(ID id) async {
    try {
      final result = await primary.get(id);
      if (result != null) {
        // Update cache
        await cache?.save(result);
        return result;
      }
    } on Object {
      // Primary failed, try fallback
    }

    // Try fallback
    if (fallback != null) {
      try {
        return await fallback!.get(id);
      } on Object {
        // Fallback also failed
      }
    }

    // Try cache as last resort
    return cache?.get(id);
  }

  Future<T?> _getCacheFirst(ID id) async {
    // Check cache first
    final cached = await cache?.get(id);
    if (cached != null) return cached;

    // Cache miss, try primary
    final result = await primary.get(id);
    if (result != null) {
      await cache?.save(result);
    }
    return result;
  }

  Future<T?> _getFastest(ID id) async {
    final futures = <Future<T?>>[primary.get(id)];
    if (fallback != null) futures.add(fallback!.get(id));
    if (cache != null) futures.add(cache!.get(id));

    // Return first non-null result
    for (final future in futures) {
      final result = await future;
      if (result != null) return result;
    }

    return null;
  }

  @override
  Future<List<T>> getAll({Query<T>? query}) async {
    try {
      final results = await primary.getAll(query: query);
      // Update cache
      for (final item in results) {
        await cache?.save(item);
      }
      return results;
    } on Object {
      // Primary failed, try fallback
    }

    if (fallback != null) {
      try {
        return await fallback!.getAll(query: query);
      } on Object {
        // Fallback also failed
      }
    }

    // Try cache as last resort
    return cache?.getAll(query: query) ?? [];
  }

  @override
  Stream<T?> watch(ID id) {
    // Merge streams from primary and fallback
    final streams = <Stream<T?>>[primary.watch(id)];
    if (fallback != null) streams.add(fallback!.watch(id));

    return Rx.merge(streams).distinct();
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) {
    final streams = <Stream<List<T>>>[primary.watchAll(query: query)];
    if (fallback != null) streams.add(fallback!.watchAll(query: query));

    return Rx.merge(streams).distinct();
  }

  // ---------------------------------------------------------------------------
  // Write Operations
  // ---------------------------------------------------------------------------

  @override
  Future<T> save(T item) async {
    switch (writeStrategy) {
      case CompositeWriteStrategy.primaryOnly:
        return _savePrimaryOnly(item);
      case CompositeWriteStrategy.all:
        return _saveAll(item);
      case CompositeWriteStrategy.primaryAndCache:
        return _savePrimaryAndCache(item);
    }
  }

  Future<T> _savePrimaryOnly(T item) => primary.save(item);

  Future<T> _saveAll(T item) async {
    final result = await primary.save(item);
    await cache?.save(result);
    await fallback?.save(result);
    return result;
  }

  Future<T> _savePrimaryAndCache(T item) async {
    final result = await primary.save(item);
    await cache?.save(result);
    return result;
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    final results = await primary.saveAll(items);

    if (writeStrategy != CompositeWriteStrategy.primaryOnly) {
      for (final item in results) {
        await cache?.save(item);
        if (writeStrategy == CompositeWriteStrategy.all) {
          await fallback?.save(item);
        }
      }
    }

    return results;
  }

  @override
  Future<bool> delete(ID id) async {
    final result = await primary.delete(id);

    if (writeStrategy != CompositeWriteStrategy.primaryOnly) {
      await cache?.delete(id);
      if (writeStrategy == CompositeWriteStrategy.all) {
        await fallback?.delete(id);
      }
    }

    return result;
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    var count = 0;
    for (final id in ids) {
      if (await delete(id)) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<T> query) => primary.deleteWhere(query);

  // ---------------------------------------------------------------------------
  // Sync Operations
  // ---------------------------------------------------------------------------

  @override
  SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<void> sync() async {
    _syncStatusSubject.add(SyncStatus.syncing);

    try {
      await primary.sync();
      await fallback?.sync();
      _syncStatusSubject.add(SyncStatus.synced);
    } on Object {
      _syncStatusSubject.add(SyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<int> get pendingChangesCount async {
    final primaryCount = await primary.pendingChangesCount;
    final fallbackCount = await fallback?.pendingChangesCount ?? 0;
    return primaryCount + fallbackCount;
  }

  @override
  Stream<List<PendingChange<T>>> get pendingChangesStream {
    final streams = <Stream<List<PendingChange<T>>>>[
      primary.pendingChangesStream,
    ];
    if (fallback != null) {
      streams.add(fallback!.pendingChangesStream);
    }
    // Merge and combine pending changes from all backends
    return Rx.combineLatest(streams, (lists) => lists.expand((l) => l).toList());
  }

  @override
  Stream<ConflictDetails<T>> get conflictsStream {
    final streams = <Stream<ConflictDetails<T>>>[primary.conflictsStream];
    if (fallback != null) {
      streams.add(fallback!.conflictsStream);
    }
    return Rx.merge(streams);
  }

  @override
  Future<void> retryChange(String changeId) async {
    // Try primary first, then fallback
    try {
      await primary.retryChange(changeId);
      return;
    } on Object {
      // Not found in primary, try fallback
    }
    await fallback?.retryChange(changeId);
  }

  @override
  Future<PendingChange<T>?> cancelChange(String changeId) async {
    // Try primary first
    final primaryResult = await primary.cancelChange(changeId);
    if (primaryResult != null) return primaryResult;

    // Try fallback
    return fallback?.cancelChange(changeId);
  }

  // ---------------------------------------------------------------------------
  // Backend Information
  // ---------------------------------------------------------------------------

  @override
  String get name => 'CompositeBackend(${primary.name})';

  @override
  bool get supportsOffline =>
      primary.supportsOffline || (fallback?.supportsOffline ?? false);

  @override
  bool get supportsRealtime =>
      primary.supportsRealtime || (fallback?.supportsRealtime ?? false);

  @override
  bool get supportsTransactions => primary.supportsTransactions;

  @override
  bool get supportsPagination =>
      primary.supportsPagination || (fallback?.supportsPagination ?? false);

  // ---------------------------------------------------------------------------
  // Pagination Operations
  // ---------------------------------------------------------------------------

  @override
  Future<PagedResult<T>> getAllPaged({Query<T>? query}) async {
    try {
      final results = await primary.getAllPaged(query: query);
      // Update cache with items
      for (final item in results.items) {
        await cache?.save(item);
      }
      return results;
    } on Object {
      // Primary failed, try fallback
    }

    if (fallback != null) {
      try {
        return await fallback!.getAllPaged(query: query);
      } on Object {
        // Fallback also failed
      }
    }

    // Try cache as last resort
    if (cache != null) {
      return cache!.getAllPaged(query: query);
    }

    return PagedResult<T>(
      items: [],
      pageInfo: const PageInfo.empty(),
    );
  }

  @override
  Stream<PagedResult<T>> watchAllPaged({Query<T>? query}) {
    final streams = <Stream<PagedResult<T>>>[
      primary.watchAllPaged(query: query),
    ];
    if (fallback != null) {
      streams.add(fallback!.watchAllPaged(query: query));
    }

    return Rx.merge(streams).distinct();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    await primary.initialize();
    await fallback?.initialize();
    await cache?.initialize();
  }

  @override
  Future<void> close() async {
    await primary.close();
    await fallback?.close();
    await cache?.close();
    await _syncStatusSubject.close();
  }
}

/// Strategy for read operations in composite backend.
enum CompositeReadStrategy {
  /// Try primary first, then fallback if primary fails.
  primaryFirst,

  /// Try cache first, then primary on cache miss.
  cacheFirst,

  /// Query all backends in parallel, return first result.
  fastest,
}

/// Strategy for write operations in composite backend.
enum CompositeWriteStrategy {
  /// Write only to primary backend.
  primaryOnly,

  /// Write to all backends (primary, cache, fallback).
  all,

  /// Write to primary and cache only.
  primaryAndCache,
}
