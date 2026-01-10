/// Sync policy determining when changes are pushed to the remote server.
enum BrickSyncPolicy {
  /// Changes are synced immediately when they occur.
  immediate,

  /// Changes are batched and synced periodically.
  batch,

  /// Changes are only synced when explicitly requested.
  manual,
}

/// Conflict resolution strategy when local and remote data diverge.
enum BrickConflictResolution {
  /// Server data wins - remote changes overwrite local.
  serverWins,

  /// Client data wins - local changes overwrite remote.
  clientWins,

  /// Most recent write wins based on timestamp.
  lastWriteWins,

  /// Attempt to merge changes field-by-field.
  merge,
}

/// Retry policy for failed sync operations.
class BrickRetryPolicy {
  /// Creates a retry policy.
  const BrickRetryPolicy({
    this.maxAttempts = 3,
    this.backoffMs = 1000,
    this.exponentialBackoff = true,
    this.maxBackoffMs = 30000,
  });

  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Base backoff duration in milliseconds.
  final int backoffMs;

  /// Whether to use exponential backoff (doubles each retry).
  final bool exponentialBackoff;

  /// Maximum backoff duration in milliseconds.
  final int maxBackoffMs;

  /// Gets the backoff duration for a given attempt number.
  Duration getBackoffDuration(int attempt) {
    if (!exponentialBackoff) {
      return Duration(milliseconds: backoffMs);
    }

    final delay = backoffMs * (1 << attempt); // 2^attempt
    final cappedDelay = delay > maxBackoffMs ? maxBackoffMs : delay;
    return Duration(milliseconds: cappedDelay);
  }

  /// Creates a copy with optional overrides.
  BrickRetryPolicy copyWith({
    int? maxAttempts,
    int? backoffMs,
    bool? exponentialBackoff,
    int? maxBackoffMs,
  }) => BrickRetryPolicy(
        maxAttempts: maxAttempts ?? this.maxAttempts,
        backoffMs: backoffMs ?? this.backoffMs,
        exponentialBackoff: exponentialBackoff ?? this.exponentialBackoff,
        maxBackoffMs: maxBackoffMs ?? this.maxBackoffMs,
      );
}

/// Configuration for sync behavior in Brick adapters.
class BrickSyncConfig {
  /// Creates a sync configuration.
  const BrickSyncConfig({
    this.syncPolicy = BrickSyncPolicy.immediate,
    this.conflictResolution = BrickConflictResolution.serverWins,
    this.retryPolicy = const BrickRetryPolicy(),
    this.batchSize = 50,
    this.syncIntervalMs,
  });

  /// Creates a configuration for immediate sync.
  const BrickSyncConfig.immediate({
    BrickConflictResolution conflictResolution =
        BrickConflictResolution.serverWins,
    BrickRetryPolicy retryPolicy = const BrickRetryPolicy(),
  }) : this(
          syncPolicy: BrickSyncPolicy.immediate,
          conflictResolution: conflictResolution,
          retryPolicy: retryPolicy,
        );

  /// Creates a configuration for batch sync.
  const BrickSyncConfig.batch({
    int batchSize = 50,
    int? syncIntervalMs,
    BrickConflictResolution conflictResolution =
        BrickConflictResolution.serverWins,
    BrickRetryPolicy retryPolicy = const BrickRetryPolicy(),
  }) : this(
          syncPolicy: BrickSyncPolicy.batch,
          batchSize: batchSize,
          syncIntervalMs: syncIntervalMs,
          conflictResolution: conflictResolution,
          retryPolicy: retryPolicy,
        );

  /// Creates a configuration for manual sync only.
  const BrickSyncConfig.manual({
    BrickConflictResolution conflictResolution =
        BrickConflictResolution.serverWins,
    BrickRetryPolicy retryPolicy = const BrickRetryPolicy(),
  }) : this(
          syncPolicy: BrickSyncPolicy.manual,
          conflictResolution: conflictResolution,
          retryPolicy: retryPolicy,
        );

  /// When to sync changes.
  final BrickSyncPolicy syncPolicy;

  /// How to resolve conflicts.
  final BrickConflictResolution conflictResolution;

  /// Retry policy for failed operations.
  final BrickRetryPolicy retryPolicy;

  /// Number of items per sync batch (for batch policy).
  final int batchSize;

  /// Interval between syncs in milliseconds (for batch policy).
  final int? syncIntervalMs;

  /// Creates a copy with optional overrides.
  BrickSyncConfig copyWith({
    BrickSyncPolicy? syncPolicy,
    BrickConflictResolution? conflictResolution,
    BrickRetryPolicy? retryPolicy,
    int? batchSize,
    int? syncIntervalMs,
  }) => BrickSyncConfig(
        syncPolicy: syncPolicy ?? this.syncPolicy,
        conflictResolution: conflictResolution ?? this.conflictResolution,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        batchSize: batchSize ?? this.batchSize,
        syncIntervalMs: syncIntervalMs ?? this.syncIntervalMs,
      );
}
