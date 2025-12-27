import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/compliance/gdpr_config.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/retry_config.dart';
import 'package:nexus_store/src/interceptors/store_interceptor.dart';
import 'package:nexus_store/src/security/encryption_config.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/telemetry/metrics_config.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';

part 'store_config.freezed.dart';

/// Configuration for a [NexusStore] instance.
///
/// ## Example
///
/// ```dart
/// final config = StoreConfig(
///   fetchPolicy: FetchPolicy.cacheFirst,
///   writePolicy: WritePolicy.cacheAndNetwork,
///   syncMode: SyncMode.realtime,
///   encryption: EncryptionConfig.fieldLevel(
///     encryptedFields: {'ssn', 'email'},
///     keyProvider: () => secureStorage.getKey(),
///   ),
/// );
/// ```
@freezed
abstract class StoreConfig with _$StoreConfig {
  /// Creates a store configuration.
  const factory StoreConfig({
    /// Default fetch policy for read operations.
    @Default(FetchPolicy.cacheFirst) FetchPolicy fetchPolicy,

    /// Default write policy for write operations.
    @Default(WritePolicy.cacheAndNetwork) WritePolicy writePolicy,

    /// Synchronization mode.
    @Default(SyncMode.realtime) SyncMode syncMode,

    /// Conflict resolution strategy.
    @Default(ConflictResolution.serverWins)
    ConflictResolution conflictResolution,

    /// Retry configuration for failed operations.
    @Default(RetryConfig.defaults) RetryConfig retryConfig,

    /// Encryption configuration.
    @Default(EncryptionConfig.none()) EncryptionConfig encryption,

    /// Whether to enable audit logging.
    @Default(false) bool enableAuditLogging,

    /// Whether to enable GDPR compliance features.
    @Default(false) bool enableGdpr,

    /// GDPR configuration for enhanced compliance features.
    ///
    /// Provides configuration for data minimization, consent tracking,
    /// and breach notification. When provided, enables the enhanced GDPR
    /// compliance features (REQ-026, REQ-027, REQ-028).
    GdprConfig? gdpr,

    /// Duration to cache data before considering it stale.
    Duration? staleDuration,

    /// Interval for periodic sync (when syncMode is periodic).
    Duration? syncInterval,

    /// Custom table/collection name override.
    String? tableName,

    /// Metrics reporter for telemetry (defaults to no-op).
    @Default(NoOpMetricsReporter()) MetricsReporter metricsReporter,

    /// Metrics configuration for sampling and buffering.
    @Default(MetricsConfig.defaults) MetricsConfig metricsConfig,

    /// Default timeout for transactions.
    ///
    /// If a transaction takes longer than this duration, it will be
    /// automatically rolled back with a [TransactionError].
    @Default(Duration(seconds: 30)) Duration transactionTimeout,

    /// Delta sync configuration for field-level change tracking.
    ///
    /// When enabled, only changed fields are synced instead of entire entities,
    /// reducing bandwidth usage. See [DeltaSyncConfig] for options.
    DeltaSyncConfig? deltaSync,

    /// Interceptors for pre/post processing of store operations.
    ///
    /// Interceptors are called in order for requests (first to last) and
    /// in reverse order for responses/errors (last to first).
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   interceptors: [
    ///     LoggingInterceptor(),
    ///     AuthInterceptor(authService),
    ///     CachingInterceptor(cache),
    ///   ],
    /// );
    /// ```
    @Default([]) List<StoreInterceptor> interceptors,
  }) = _StoreConfig;

  const StoreConfig._();

  /// Default configuration with sensible defaults.
  static const StoreConfig defaults = StoreConfig();

  /// Configuration optimized for offline-first usage.
  static const StoreConfig offlineFirst = StoreConfig(
    writePolicy: WritePolicy.cacheFirst,
    syncMode: SyncMode.eventDriven,
  );

  /// Configuration optimized for online-only usage.
  static const StoreConfig onlineOnly = StoreConfig(
    fetchPolicy: FetchPolicy.networkOnly,
    writePolicy: WritePolicy.networkFirst,
    syncMode: SyncMode.disabled,
  );

  /// Configuration optimized for real-time usage.
  static const StoreConfig realtime = StoreConfig(
    fetchPolicy: FetchPolicy.cacheAndNetwork,
  );
}
