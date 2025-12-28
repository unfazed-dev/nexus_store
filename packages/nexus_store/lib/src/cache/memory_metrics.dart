import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';

part 'memory_metrics.freezed.dart';

/// Metrics about memory usage and cache state.
///
/// Provides a snapshot of the current memory situation including usage,
/// eviction history, and pinned item counts.
///
/// ## Example
///
/// ```dart
/// final metrics = store.memoryMetrics;
/// print('Cache size: ${metrics.currentBytes / 1024 / 1024} MB');
/// print('Evictions: ${metrics.evictionCount}');
/// print('Pressure: ${metrics.pressureLevel}');
/// ```
@freezed
abstract class MemoryMetrics with _$MemoryMetrics {
  /// Creates memory metrics.
  const factory MemoryMetrics({
    /// Current estimated cache size in bytes.
    required int currentBytes,

    /// Peak cache size in bytes since last reset.
    required int maxBytes,

    /// Total number of items evicted since last reset.
    required int evictionCount,

    /// Number of pinned items (protected from eviction).
    required int pinnedCount,

    /// Estimated size of pinned items in bytes.
    required int pinnedBytes,

    /// Current memory pressure level.
    required MemoryPressureLevel pressureLevel,

    /// Total number of items in the cache.
    required int itemCount,

    /// When these metrics were captured.
    required DateTime timestamp,
  }) = _MemoryMetrics;

  const MemoryMetrics._();

  /// Creates empty metrics with zero values.
  factory MemoryMetrics.empty() => MemoryMetrics(
        currentBytes: 0,
        maxBytes: 0,
        evictionCount: 0,
        pinnedCount: 0,
        pinnedBytes: 0,
        pressureLevel: MemoryPressureLevel.none,
        itemCount: 0,
        timestamp: DateTime.now(),
      );

  /// Ratio of current usage to max capacity (0.0-1.0).
  ///
  /// Returns 0.0 if [maxBytes] is 0.
  double get usageRatio => maxBytes > 0 ? currentBytes / maxBytes : 0.0;

  /// Estimated bytes used by non-pinned items.
  int get unpinnedBytes => currentBytes - pinnedBytes;

  /// Number of non-pinned items.
  int get unpinnedCount => itemCount - pinnedCount;

  /// Average size per item in bytes.
  ///
  /// Returns 0 if [itemCount] is 0.
  int get averageItemSize => itemCount > 0 ? currentBytes ~/ itemCount : 0;
}
