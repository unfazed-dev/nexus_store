import 'package:meta/meta.dart';

/// Configuration for paginated streaming behavior.
///
/// Controls pagination settings for infinite scrolling and batch loading
/// in [NexusStore] and related widgets.
///
/// ## Example
///
/// ```dart
/// // Default configuration
/// const config = StreamingConfig();
///
/// // Custom configuration for large lists
/// const largeListConfig = StreamingConfig(
///   pageSize: 50,
///   prefetchDistance: 10,
///   maxPagesInMemory: 10,
/// );
///
/// // Use with store
/// store.watchAllPaginated(
///   query: Query<User>().orderByField('name'),
///   config: config,
/// );
/// ```
@immutable
class StreamingConfig {
  /// Creates a streaming configuration with the given parameters.
  ///
  /// All parameters have sensible defaults for typical use cases.
  const StreamingConfig({
    this.pageSize = 20,
    this.prefetchDistance = 5,
    this.maxPagesInMemory = 5,
    this.debounce = const Duration(milliseconds: 300),
  })  : assert(pageSize > 0, 'pageSize must be positive'),
        assert(prefetchDistance >= 0, 'prefetchDistance must be non-negative'),
        assert(maxPagesInMemory > 0, 'maxPagesInMemory must be positive');

  /// Creates a configuration optimized for small lists.
  ///
  /// Uses smaller page sizes and fewer pages in memory.
  const StreamingConfig.small()
      : pageSize = 10,
        prefetchDistance = 3,
        maxPagesInMemory = 3,
        debounce = const Duration(milliseconds: 300);

  /// Creates a configuration optimized for large lists.
  ///
  /// Uses larger page sizes and more pages in memory for smoother scrolling.
  const StreamingConfig.large()
      : pageSize = 50,
        prefetchDistance = 10,
        maxPagesInMemory = 10,
        debounce = const Duration(milliseconds: 300);

  /// Creates a configuration with no prefetching.
  ///
  /// Items are only loaded when the user scrolls to them.
  const StreamingConfig.noPrefetch()
      : pageSize = 20,
        prefetchDistance = 0,
        maxPagesInMemory = 5,
        debounce = const Duration(milliseconds: 300);

  /// Number of items to load per page.
  ///
  /// Default: 20
  final int pageSize;

  /// Number of items from the end to trigger prefetch.
  ///
  /// When the user scrolls within this distance from the end of loaded items,
  /// the next page will be fetched automatically.
  ///
  /// Set to 0 to disable prefetching.
  ///
  /// Default: 5
  final int prefetchDistance;

  /// Maximum number of pages to keep in memory.
  ///
  /// Older pages are discarded when this limit is exceeded, reducing
  /// memory usage for long lists.
  ///
  /// Default: 5
  final int maxPagesInMemory;

  /// Debounce duration for rapid scroll events.
  ///
  /// Prevents excessive loading when the user scrolls quickly.
  ///
  /// Set to [Duration.zero] to disable debouncing.
  ///
  /// Default: 300ms
  final Duration debounce;

  // ---------------------------------------------------------------------------
  // Helper Getters
  // ---------------------------------------------------------------------------

  /// Maximum number of items kept in memory.
  int get totalItemsInMemory => pageSize * maxPagesInMemory;

  /// Whether prefetching is enabled.
  bool get shouldPrefetch => prefetchDistance > 0;

  /// Whether debouncing is enabled.
  bool get shouldDebounce => debounce > Duration.zero;

  // ---------------------------------------------------------------------------
  // Copy With
  // ---------------------------------------------------------------------------

  /// Creates a copy with the specified fields replaced.
  StreamingConfig copyWith({
    int? pageSize,
    int? prefetchDistance,
    int? maxPagesInMemory,
    Duration? debounce,
  }) {
    return StreamingConfig(
      pageSize: pageSize ?? this.pageSize,
      prefetchDistance: prefetchDistance ?? this.prefetchDistance,
      maxPagesInMemory: maxPagesInMemory ?? this.maxPagesInMemory,
      debounce: debounce ?? this.debounce,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingConfig &&
        other.pageSize == pageSize &&
        other.prefetchDistance == prefetchDistance &&
        other.maxPagesInMemory == maxPagesInMemory &&
        other.debounce == debounce;
  }

  @override
  int get hashCode => Object.hash(
        pageSize,
        prefetchDistance,
        maxPagesInMemory,
        debounce,
      );

  @override
  String toString() => 'StreamingConfig('
      'pageSize: $pageSize, '
      'prefetchDistance: $prefetchDistance, '
      'maxPagesInMemory: $maxPagesInMemory, '
      'debounce: $debounce)';
}
