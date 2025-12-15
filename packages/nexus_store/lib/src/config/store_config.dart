import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/config/retry_config.dart';
import 'package:nexus_store/src/security/encryption_config.dart';

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
    @Default(ConflictResolution.serverWins) ConflictResolution conflictResolution,

    /// Retry configuration for failed operations.
    @Default(RetryConfig.defaults) RetryConfig retryConfig,

    /// Encryption configuration.
    @Default(EncryptionConfig.none()) EncryptionConfig encryption,

    /// Whether to enable audit logging.
    @Default(false) bool enableAuditLogging,

    /// Whether to enable GDPR compliance features.
    @Default(false) bool enableGdpr,

    /// Duration to cache data before considering it stale.
    Duration? staleDuration,

    /// Interval for periodic sync (when syncMode is periodic).
    Duration? syncInterval,

    /// Custom table/collection name override.
    String? tableName,
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
