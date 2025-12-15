/// Fetch policies for read operations.
///
/// Inspired by Apollo GraphQL fetch policies, these determine how data
/// is retrieved from cache vs network.
enum FetchPolicy {
  /// Return cache if available, otherwise fetch from network.
  ///
  /// Best for: Read-heavy data that doesn't change frequently.
  /// Use when: Performance is priority and slight staleness is acceptable.
  cacheFirst,

  /// Always fetch from network, update cache with result.
  ///
  /// Best for: Data that must be fresh (e.g., account balance).
  /// Use when: Data accuracy is more important than performance.
  networkFirst,

  /// Return cache immediately, then fetch and emit network result.
  ///
  /// Best for: UX optimization where showing stale data is better than loading.
  /// Use when: You want instant UI with background refresh.
  cacheAndNetwork,

  /// Return only cached data, never fetch from network.
  ///
  /// Best for: Offline-only scenarios or when network is unavailable.
  /// Use when: Explicitly avoiding network calls.
  cacheOnly,

  /// Always fetch from network, ignore cache entirely.
  ///
  /// Best for: Data that should never be cached (e.g., OTP, real-time prices).
  /// Use when: Cache should be bypassed completely.
  networkOnly,

  /// Return stale cache immediately while revalidating in background.
  ///
  /// Best for: Content that benefits from instant display with eventual
  /// consistency. Use when: Similar to cacheAndNetwork but optimized for
  /// perceived performance.
  staleWhileRevalidate,
}

/// Write policies for create/update/delete operations.
///
/// These determine how writes are persisted to cache and network.
enum WritePolicy {
  /// Write to cache and network simultaneously.
  ///
  /// Best for: Standard online operations.
  /// Behavior: Optimistic update to cache, rollback on network failure.
  cacheAndNetwork,

  /// Write to network first, then update cache on success.
  ///
  /// Best for: Critical data where consistency is paramount.
  /// Behavior: No optimistic update, UI waits for network confirmation.
  networkFirst,

  /// Write to cache first, sync to network later.
  ///
  /// Best for: Offline-first applications.
  /// Behavior: Immediate local persistence, background sync when online.
  cacheFirst,

  /// Write only to cache, never sync to network.
  ///
  /// Best for: Local-only data (settings, drafts).
  /// Behavior: Data stays on device only.
  cacheOnly,
}

/// Sync status for tracking synchronization state.
enum SyncStatus {
  /// Fully synchronized with remote.
  synced,

  /// Local changes pending sync.
  pending,

  /// Currently syncing with remote.
  syncing,

  /// Sync failed, will retry.
  error,

  /// Sync paused (e.g., offline).
  paused,

  /// Conflict detected, needs resolution.
  conflict,
}

/// Conflict resolution strategies.
enum ConflictResolution {
  /// Server version always wins.
  serverWins,

  /// Client version always wins.
  clientWins,

  /// Most recent timestamp wins.
  latestWins,

  /// Attempt to merge changes.
  merge,

  /// Use CRDT for automatic conflict resolution.
  crdt,

  /// Delegate to custom handler.
  custom,
}

/// Sync modes for different synchronization patterns.
enum SyncMode {
  /// Real-time sync via WebSocket/SSE.
  realtime,

  /// Periodic sync at configured intervals.
  periodic,

  /// Manual sync only when explicitly triggered.
  manual,

  /// Sync triggered by specific events.
  eventDriven,

  /// Sync disabled entirely.
  disabled,
}
