import 'package:collection/collection.dart';

/// Statistics about the cache state.
class CacheStats {
  /// Creates cache statistics.
  const CacheStats({
    required this.totalCount,
    required this.staleCount,
    required this.tagCounts,
  });

  /// Creates empty cache statistics.
  factory CacheStats.empty() => const CacheStats(
        totalCount: 0,
        staleCount: 0,
        tagCounts: {},
      );

  /// Total number of cached items.
  final int totalCount;

  /// Number of stale items.
  final int staleCount;

  /// Count of items per tag.
  final Map<String, int> tagCounts;

  /// Number of fresh (non-stale) items.
  int get freshCount => totalCount - staleCount;

  /// Percentage of stale items (0-100).
  double get stalePercentage {
    if (totalCount == 0) return 0.0;
    return (staleCount / totalCount) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CacheStats) return false;
    return totalCount == other.totalCount &&
        staleCount == other.staleCount &&
        const MapEquality<String, int>().equals(tagCounts, other.tagCounts);
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        staleCount,
        const MapEquality<String, int>().hash(tagCounts),
      );

  @override
  String toString() =>
      'CacheStats(total: $totalCount, stale: $staleCount, tags: $tagCounts)';
}
