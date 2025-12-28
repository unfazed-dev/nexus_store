/// Strategy for selecting which items to evict from cache.
///
/// Different strategies optimize for different access patterns:
/// - [lru]: Best for typical app usage with recent items being most relevant
/// - [lfu]: Best for caches with "hot" frequently-accessed items
/// - [size]: Best when memory is constrained and large items cause issues
///
/// ## Example
///
/// ```dart
/// final config = MemoryConfig(
///   strategy: EvictionStrategy.lru,
///   maxCacheBytes: 50 * 1024 * 1024, // 50MB
/// );
/// ```
enum EvictionStrategy {
  /// Least Recently Used - evict items that haven't been accessed recently.
  ///
  /// Items are evicted in order of their last access time, with the oldest
  /// accessed items evicted first. This is the default strategy and works
  /// well for most use cases.
  lru,

  /// Least Frequently Used - evict items that are accessed least often.
  ///
  /// Items are evicted based on their access count, with the least accessed
  /// items evicted first. Useful when some items are "hot" and should be
  /// kept even if not recently accessed.
  lfu,

  /// Size-based - evict largest items first.
  ///
  /// Items are evicted in order of their estimated size, with the largest
  /// items evicted first. Useful when memory is the primary constraint and
  /// a few large items cause most of the pressure.
  size;

  /// Returns `true` if this strategy considers access patterns.
  ///
  /// Both [lru] and [lfu] are access-based, while [size] is not.
  bool get isAccessBased => this == lru || this == lfu;

  /// Returns `true` if this strategy requires tracking access times.
  ///
  /// Used by [MemoryManager] to determine whether to maintain access time
  /// metadata for cache entries.
  bool get requiresAccessTracking => this == lru || this == lfu;

  /// Returns `true` if this strategy requires tracking access frequency.
  ///
  /// Only [lfu] requires frequency tracking, as it evicts based on how
  /// often items are accessed rather than when.
  bool get requiresFrequencyTracking => this == lfu;
}
