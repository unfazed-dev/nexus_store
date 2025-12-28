import 'dart:convert';

/// Interface for estimating the memory size of cached items.
///
/// Size estimation is used by [MemoryManager] to track cache usage and
/// decide which items to evict based on their size.
///
/// ## Example
///
/// ```dart
/// final estimator = JsonSizeEstimator<User>(
///   toJson: (user) => user.toJson(),
/// );
///
/// final size = estimator.estimateSize(user);
/// print('User takes approximately $size bytes');
/// ```
abstract interface class SizeEstimator<T> {
  /// Estimates the size of [item] in bytes.
  ///
  /// This is an approximation - actual memory usage may differ due to
  /// object overhead, references, and runtime optimizations.
  int estimateSize(T item);
}

/// Size estimator that uses JSON serialization to estimate size.
///
/// Converts items to JSON and measures the UTF-8 encoded byte length.
/// This provides a reasonable approximation for serializable objects.
///
/// ## Example
///
/// ```dart
/// final estimator = JsonSizeEstimator<User>(
///   toJson: (user) => user.toJson(),
///   cacheEstimates: true, // Cache sizes for repeated lookups
/// );
/// ```
class JsonSizeEstimator<T> implements SizeEstimator<T> {
  /// Creates a JSON-based size estimator.
  ///
  /// [toJson] converts items to JSON-serializable maps.
  /// [cacheEstimates] enables caching of computed estimates.
  /// [maxCacheSize] limits the estimate cache size.
  JsonSizeEstimator({
    required this.toJson,
    this.cacheEstimates = false,
    this.maxCacheSize = 1000,
  });

  /// Function to convert items to JSON-serializable form.
  final Object? Function(T item) toJson;

  /// Whether to cache computed estimates.
  final bool cacheEstimates;

  /// Maximum number of estimates to cache.
  final int maxCacheSize;

  final Map<int, int> _cache = {};

  @override
  int estimateSize(T item) {
    if (item == null) {
      return 4; // 'null' as JSON string
    }

    final hashCode = item.hashCode;

    if (cacheEstimates && _cache.containsKey(hashCode)) {
      return _cache[hashCode]!;
    }

    final json = toJson(item);
    final encoded = utf8.encode(jsonEncode(json));
    final size = encoded.length;

    if (cacheEstimates) {
      // Evict oldest entries if cache is full
      while (_cache.length >= maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[hashCode] = size;
    }

    return size;
  }

  /// Returns the current number of cached estimates.
  int get cacheSize => _cache.length;

  /// Clears all cached estimates.
  void clearCache() => _cache.clear();
}

/// Size estimator that always returns a fixed size.
///
/// Useful when all items are approximately the same size or when
/// exact sizes don't matter.
///
/// ## Example
///
/// ```dart
/// // Assume all items are ~1KB
/// final estimator = FixedSizeEstimator<User>(1024);
/// ```
class FixedSizeEstimator<T> implements SizeEstimator<T> {
  /// Creates a fixed size estimator.
  const FixedSizeEstimator(this.size);

  /// The fixed size to return for all items.
  final int size;

  @override
  int estimateSize(T item) => size;
}

/// Size estimator that uses a callback function.
///
/// Provides flexibility for custom size calculation logic.
///
/// ## Example
///
/// ```dart
/// final estimator = CallbackSizeEstimator<MediaItem>(
///   (item) => item.metadata.length + (item.thumbnail?.length ?? 0),
/// );
/// ```
class CallbackSizeEstimator<T> implements SizeEstimator<T> {
  /// Creates a callback-based size estimator.
  const CallbackSizeEstimator(this.callback);

  /// Callback function to compute size.
  final int Function(T item) callback;

  @override
  int estimateSize(T item) => callback(item);
}

/// Size estimator that wraps another estimator with overhead/multiplier.
///
/// Useful for accounting for object overhead, references, or other
/// memory that isn't captured by the delegate estimator.
///
/// ## Example
///
/// ```dart
/// final jsonEstimator = JsonSizeEstimator<User>(...);
/// final estimator = CompositeSizeEstimator<User>(
///   delegate: jsonEstimator,
///   overhead: 64, // Object header overhead
///   multiplier: 1.2, // 20% extra for internal structures
/// );
/// ```
class CompositeSizeEstimator<T> implements SizeEstimator<T> {
  /// Creates a composite size estimator.
  const CompositeSizeEstimator({
    required this.delegate,
    this.overhead = 0,
    this.multiplier = 1.0,
  });

  /// The delegate estimator to wrap.
  final SizeEstimator<T> delegate;

  /// Fixed overhead to add to each estimate.
  final int overhead;

  /// Multiplier to apply to the delegate estimate.
  final double multiplier;

  @override
  int estimateSize(T item) {
    final baseSize = delegate.estimateSize(item);
    return (baseSize * multiplier).round() + overhead;
  }
}
