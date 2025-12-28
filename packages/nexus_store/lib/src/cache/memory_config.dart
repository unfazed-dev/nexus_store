import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/cache/eviction_strategy.dart';

part 'memory_config.freezed.dart';

/// Configuration for memory management and cache eviction.
///
/// Controls how the cache behaves under memory pressure, including when to
/// start evicting items and which eviction strategy to use.
///
/// ## Example
///
/// ```dart
/// final config = MemoryConfig(
///   maxCacheBytes: 50 * 1024 * 1024, // 50MB limit
///   moderateThreshold: 0.7, // Start evicting at 70%
///   criticalThreshold: 0.9, // Aggressive eviction at 90%
///   evictionBatchSize: 20,
///   strategy: EvictionStrategy.lru,
/// );
/// ```
@freezed
abstract class MemoryConfig with _$MemoryConfig {
  /// Creates a memory configuration.
  const factory MemoryConfig({
    /// Maximum cache size in bytes.
    ///
    /// When null, the cache is unlimited (no automatic eviction based on size).
    /// When set, cache eviction is triggered when usage exceeds thresholds.
    int? maxCacheBytes,

    /// Threshold (0.0-1.0) for moderate memory pressure.
    ///
    /// When cache usage exceeds this percentage of [maxCacheBytes],
    /// the system starts evicting items in batches using the configured
    /// [strategy]. Defaults to 0.7 (70%).
    @Default(0.7) double moderateThreshold,

    /// Threshold (0.0-1.0) for critical memory pressure.
    ///
    /// When cache usage exceeds this percentage of [maxCacheBytes],
    /// the system performs aggressive eviction. Defaults to 0.9 (90%).
    @Default(0.9) double criticalThreshold,

    /// Number of items to evict per batch.
    ///
    /// When eviction is triggered, this many items are removed at once.
    /// Larger batches are more efficient but may cause UI jank.
    /// Defaults to 10.
    @Default(10) int evictionBatchSize,

    /// Strategy for selecting which items to evict.
    ///
    /// Defaults to [EvictionStrategy.lru] (least recently used).
    @Default(EvictionStrategy.lru) EvictionStrategy strategy,
  }) = _MemoryConfig;

  const MemoryConfig._();

  /// Default configuration with no size limit and LRU eviction.
  static const MemoryConfig defaults = MemoryConfig();

  /// Aggressive configuration for low-memory devices.
  ///
  /// Uses lower thresholds and larger batch sizes for faster eviction.
  static const MemoryConfig aggressive = MemoryConfig(
    moderateThreshold: 0.5,
    criticalThreshold: 0.7,
    evictionBatchSize: 25,
  );

  /// Conservative configuration for high-memory devices.
  ///
  /// Uses higher thresholds to maximize cache utilization.
  static const MemoryConfig conservative = MemoryConfig(
    moderateThreshold: 0.8,
    criticalThreshold: 0.95,
    evictionBatchSize: 5,
  );

  /// Returns `true` if the cache has no size limit.
  bool get isUnlimited => maxCacheBytes == null;

  /// Returns `true` if the threshold configuration is valid.
  ///
  /// Thresholds must be between 0.0 and 1.0, and moderate must be
  /// less than critical.
  bool get hasValidThresholds =>
      moderateThreshold >= 0.0 &&
      moderateThreshold <= 1.0 &&
      criticalThreshold >= 0.0 &&
      criticalThreshold <= 1.0 &&
      moderateThreshold < criticalThreshold;
}
