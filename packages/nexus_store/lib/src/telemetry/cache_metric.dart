import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_metric.freezed.dart';

/// Types of cache events that can be tracked.
enum CacheEvent {
  /// Cache hit - item found in cache.
  hit,

  /// Cache miss - item not found in cache.
  miss,

  /// Cache write - item written to cache.
  write,

  /// Cache eviction - item removed due to size/policy limits.
  eviction,

  /// Cache invalidation - item manually invalidated.
  invalidation,

  /// Cache expiration - item expired due to TTL.
  expiration,
}

/// Metric for tracking cache behavior.
///
/// Records cache hits, misses, writes, and other cache events
/// for performance monitoring and optimization.
///
/// ## Example
///
/// ```dart
/// final metric = CacheMetric(
///   event: CacheEvent.hit,
///   itemId: 'user-123',
///   tags: {'users', 'active'},
///   timestamp: DateTime.now(),
/// );
/// ```
@freezed
abstract class CacheMetric with _$CacheMetric {
  /// Creates a cache metric.
  const factory CacheMetric({
    /// The type of cache event.
    required CacheEvent event,

    /// The ID of the affected item (if single item).
    String? itemId,

    /// Tags associated with the cache entry.
    @Default(<String>{}) Set<String> tags,

    /// When the event occurred.
    required DateTime timestamp,

    /// Number of items affected (for batch operations).
    @Default(1) int itemCount,
  }) = _CacheMetric;

  const CacheMetric._();
}
