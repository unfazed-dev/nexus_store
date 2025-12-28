/// Represents the level of memory pressure in the system.
///
/// Memory pressure levels are used to trigger cache eviction behaviors:
/// - [none]: Normal operation, no eviction needed
/// - [moderate]: Start evicting least recently used items
/// - [critical]: Aggressive eviction to free memory
/// - [emergency]: Clear all non-pinned items immediately
///
/// ## Example
///
/// ```dart
/// void handlePressure(MemoryPressureLevel level) {
///   if (level.shouldEvict) {
///     evictItems(batchSize: level.isEmergency ? 100 : 10);
///   }
/// }
/// ```
enum MemoryPressureLevel {
  /// Normal operation - no memory pressure.
  ///
  /// Cache operates normally without eviction.
  none,

  /// Moderate pressure - start evicting.
  ///
  /// Begin evicting least recently used items in batches.
  moderate,

  /// Critical pressure - aggressive eviction.
  ///
  /// Evict items more aggressively to prevent OOM.
  critical,

  /// Emergency pressure - clear all non-pinned.
  ///
  /// Immediately clear all non-pinned items from cache.
  emergency;

  /// Returns `true` if this level is at least as severe as [other].
  ///
  /// Useful for threshold comparisons:
  /// ```dart
  /// if (level.isAtLeast(MemoryPressureLevel.moderate)) {
  ///   startEviction();
  /// }
  /// ```
  bool isAtLeast(MemoryPressureLevel other) => index >= other.index;

  /// Returns `true` if eviction should be triggered at this level.
  ///
  /// All levels except [none] should trigger eviction.
  bool get shouldEvict => this != none;

  /// Returns `true` if this is the emergency level.
  ///
  /// Emergency level requires immediate clearing of all non-pinned items.
  bool get isEmergency => this == emergency;
}
