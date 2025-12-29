import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/cache/memory_config.dart';
import 'package:nexus_store/src/compliance/gdpr_config.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/retry_config.dart';
import 'package:nexus_store/src/interceptors/store_interceptor.dart';
import 'package:nexus_store/src/lazy/lazy_load_config.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_config.dart';
import 'package:nexus_store/src/reliability/degradation_config.dart';
import 'package:nexus_store/src/reliability/health_check_config.dart';
import 'package:nexus_store/src/reliability/schema_validation_config.dart';
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

    /// Lazy loading configuration for heavy fields.
    ///
    /// When configured, enables on-demand loading for specified fields
    /// (e.g., images, blobs, large text) to improve initial load performance.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   lazyLoad: LazyLoadConfig(
    ///     lazyFields: {'thumbnail', 'fullImage', 'video'},
    ///     batchSize: 10,
    ///   ),
    /// );
    /// ```
    LazyLoadConfig? lazyLoad,

    /// Memory management configuration for cache eviction.
    ///
    /// When configured, enables automatic cache eviction under memory pressure
    /// with configurable thresholds, eviction strategies, and pinned items.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   memory: MemoryConfig(
    ///     maxCacheBytes: 50 * 1024 * 1024, // 50MB
    ///     moderateThreshold: 0.7,
    ///     criticalThreshold: 0.9,
    ///     strategy: EvictionStrategy.lru,
    ///   ),
    /// );
    /// ```
    MemoryConfig? memory,

    /// Circuit breaker configuration for preventing cascade failures.
    ///
    /// When configured, enables automatic circuit breaker protection for
    /// backend operations to prevent overwhelming a failing service.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   circuitBreaker: CircuitBreakerConfig(
    ///     failureThreshold: 5,
    ///     successThreshold: 2,
    ///     openDuration: Duration(seconds: 30),
    ///   ),
    /// );
    /// ```
    CircuitBreakerConfig? circuitBreaker,

    /// Health check configuration for system health monitoring.
    ///
    /// When configured, enables periodic health checks of store components
    /// with configurable intervals and thresholds.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   healthCheck: HealthCheckConfig(
    ///     checkInterval: Duration(seconds: 30),
    ///     timeout: Duration(seconds: 10),
    ///     failureThreshold: 3,
    ///   ),
    /// );
    /// ```
    HealthCheckConfig? healthCheck,

    /// Schema validation configuration for entity validation.
    ///
    /// When configured, enables validation of entities against schemas
    /// before save operations.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   schemaValidation: SchemaValidationConfig(
    ///     mode: SchemaValidationMode.strict,
    ///     validateOnSave: true,
    ///   ),
    /// );
    /// ```
    SchemaValidationConfig? schemaValidation,

    /// Degradation configuration for graceful degradation behavior.
    ///
    /// When configured, enables automatic degradation when components
    /// become unavailable, with configurable fallback modes.
    ///
    /// ## Example
    ///
    /// ```dart
    /// final config = StoreConfig(
    ///   degradation: DegradationConfig(
    ///     autoDegradation: true,
    ///     fallbackMode: DegradationMode.cacheOnly,
    ///     cooldown: Duration(seconds: 60),
    ///   ),
    /// );
    /// ```
    DegradationConfig? degradation,
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
