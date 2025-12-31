/// Metadata wrapper for a cached item.
///
/// Tracks tags, timestamps, and staleness for cache entries.
class CacheEntry<ID> {
  /// Creates a cache entry.
  CacheEntry({
    required this.id,
    required this.cachedAt,
    Set<String>? tags,
    this.staleAt,
  }) : tags = tags ?? {};

  /// The identifier of the cached item.
  final ID id;

  /// The tags associated with this cached item.
  final Set<String> tags;

  /// When the item was cached.
  final DateTime cachedAt;

  /// When the item becomes stale. Null means never stale.
  final DateTime? staleAt;

  /// Returns true if this entry is stale.
  ///
  /// If [now] is not provided, uses the current time.
  bool isStale([DateTime? now]) {
    if (staleAt == null) return false;
    final checkTime = now ?? DateTime.now();
    return checkTime.isAfter(staleAt!);
  }

  /// Returns a new entry marked as immediately stale.
  CacheEntry<ID> markStale() {
    return copyWith(
        staleAt: DateTime.now().subtract(const Duration(seconds: 1)));
  }

  /// Creates a copy with the given fields replaced.
  CacheEntry<ID> copyWith({
    Set<String>? tags,
    DateTime? staleAt,
  }) {
    return CacheEntry<ID>(
      id: id,
      cachedAt: cachedAt,
      tags: tags ?? this.tags,
      staleAt: staleAt ?? this.staleAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CacheEntry<ID>) return false;
    return id == other.id &&
        cachedAt == other.cachedAt &&
        staleAt == other.staleAt &&
        _setsEqual(tags, other.tags);
  }

  @override
  int get hashCode => Object.hash(id, cachedAt, staleAt, Object.hashAll(tags));

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
