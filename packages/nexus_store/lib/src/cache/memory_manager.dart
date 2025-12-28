import 'package:rxdart/rxdart.dart';

import 'eviction_strategy.dart';
import 'lru_tracker.dart';
import 'memory_config.dart';
import 'memory_metrics.dart';
import 'memory_pressure_handler.dart';
import 'memory_pressure_level.dart';
import 'size_estimator.dart';

/// Manages cache memory with configurable eviction strategies.
///
/// [MemoryManager] tracks cache entries, monitors memory usage, and
/// automatically evicts items when thresholds are exceeded. It supports
/// LRU, LFU, and size-based eviction strategies, as well as pinned items
/// that are protected from eviction.
///
/// ## Example
///
/// ```dart
/// final manager = MemoryManager<User, String>(
///   config: MemoryConfig(
///     maxCacheBytes: 50 * 1024 * 1024, // 50MB
///     moderateThreshold: 0.7,
///     criticalThreshold: 0.9,
///     strategy: EvictionStrategy.lru,
///   ),
///   sizeEstimator: JsonSizeEstimator(toJson: (u) => u.toJson()),
///   onEviction: (ids) => cache.removeAll(ids),
/// );
///
/// // Track items
/// manager.recordItem('user-1', user);
/// manager.recordAccess('user-1');
///
/// // Pin important items
/// manager.pin('current-user');
///
/// // Check status
/// print('Using ${manager.currentBytes} bytes');
/// print('Pressure: ${manager.currentLevel}');
/// ```
class MemoryManager<T, ID> {
  /// Creates a memory manager.
  ///
  /// [config] specifies thresholds and eviction strategy.
  /// [sizeEstimator] estimates the size of cached items.
  /// [onEviction] is called when items are evicted, with the list of IDs.
  MemoryManager({
    required MemoryConfig config,
    required SizeEstimator<T> sizeEstimator,
    void Function(List<ID> evictedIds)? onEviction,
  })  : _config = config,
        _sizeEstimator = sizeEstimator,
        _onEviction = onEviction,
        _tracker = LruTracker<ID>(),
        _pressureHandler = ThresholdMemoryPressureHandler(
          maxBytes: config.maxCacheBytes,
          moderateThreshold: config.moderateThreshold,
          criticalThreshold: config.criticalThreshold,
        ),
        _metricsSubject = BehaviorSubject.seeded(MemoryMetrics.empty());

  final MemoryConfig _config;
  final SizeEstimator<T> _sizeEstimator;
  final void Function(List<ID> evictedIds)? _onEviction;
  final LruTracker<ID> _tracker;
  final ThresholdMemoryPressureHandler _pressureHandler;
  final BehaviorSubject<MemoryMetrics> _metricsSubject;
  final Set<ID> _pinnedIds = {};
  final Map<ID, int> _itemSizes = {};

  int _evictionCount = 0;
  int _maxBytes = 0;

  /// Records an item in the cache.
  ///
  /// Estimates the item's size and updates tracking information.
  /// May trigger eviction if thresholds are exceeded.
  void recordItem(ID id, T item) {
    final size = _sizeEstimator.estimateSize(item);
    _itemSizes[id] = size;
    _tracker.recordAccess(id, size: size);
    _updatePressure();
    _emitMetrics();
  }

  /// Records an access to an existing cached item.
  ///
  /// Updates the access time and count for eviction decisions.
  void recordAccess(ID id) {
    if (!_itemSizes.containsKey(id)) return;
    final size = _itemSizes[id]!;
    _tracker.recordAccess(id, size: size);
  }

  /// Removes an item from tracking.
  void removeItem(ID id) {
    _tracker.remove(id);
    _itemSizes.remove(id);
    _pinnedIds.remove(id);
    _updatePressure();
    _emitMetrics();
  }

  /// Returns `true` if [id] is being tracked.
  bool contains(ID id) => _tracker.contains(id);

  /// Returns the number of tracked items.
  int get itemCount => _tracker.itemCount;

  /// Returns the current estimated cache size in bytes.
  int get currentBytes => _tracker.totalSize;

  /// Returns the last access time for [id], or null if not tracked.
  DateTime? getLastAccessTime(ID id) => _tracker.getLastAccessTime(id);

  // --- Pinned Items ---

  /// Pins an item to protect it from eviction.
  void pin(ID id) {
    _pinnedIds.add(id);
    _emitMetrics();
  }

  /// Unpins an item, making it eligible for eviction.
  void unpin(ID id) {
    _pinnedIds.remove(id);
    _emitMetrics();
  }

  /// Returns `true` if [id] is pinned.
  bool isPinned(ID id) => _pinnedIds.contains(id);

  /// Returns all pinned IDs.
  Set<ID> get pinnedIds => Set.unmodifiable(_pinnedIds);

  // --- Eviction ---

  /// Evicts items from the cache based on the configured strategy.
  ///
  /// [count] is the number of items to evict. Defaults to [evictionBatchSize].
  /// Returns the list of evicted IDs.
  List<ID> evict({int? count}) {
    final batchSize = count ?? _config.evictionBatchSize;
    final candidates = _getEvictionCandidates(batchSize);

    for (final id in candidates) {
      _tracker.remove(id);
      _itemSizes.remove(id);
    }

    if (candidates.isNotEmpty) {
      _evictionCount += candidates.length;
      _onEviction?.call(candidates);
      _updatePressure();
      _emitMetrics();
    }

    return candidates;
  }

  /// Evicts all non-pinned items from the cache.
  void evictUnpinned() {
    final toEvict =
        _tracker.allIds.where((id) => !_pinnedIds.contains(id)).toList();

    for (final id in toEvict) {
      _tracker.remove(id);
      _itemSizes.remove(id);
    }

    if (toEvict.isNotEmpty) {
      _evictionCount += toEvict.length;
      _onEviction?.call(toEvict);
      _updatePressure();
      _emitMetrics();
    }
  }

  List<ID> _getEvictionCandidates(int count) {
    switch (_config.strategy) {
      case EvictionStrategy.lru:
        return _tracker.getEvictionCandidatesLru(
          count,
          excludeIds: _pinnedIds,
        );
      case EvictionStrategy.lfu:
        return _tracker.getEvictionCandidatesLfu(
          count,
          excludeIds: _pinnedIds,
        );
      case EvictionStrategy.size:
        return _tracker.getEvictionCandidatesBySize(
          count,
          excludeIds: _pinnedIds,
        );
    }
  }

  // --- Pressure Level ---

  /// Current memory pressure level.
  MemoryPressureLevel get currentLevel => _pressureHandler.currentLevel;

  /// Stream of memory pressure level changes.
  Stream<MemoryPressureLevel> get pressureStream =>
      _pressureHandler.pressureStream;

  void _updatePressure() {
    _pressureHandler.updateUsage(currentBytes);

    // Track max usage
    if (currentBytes > _maxBytes) {
      _maxBytes = currentBytes;
    }
  }

  // --- Metrics ---

  /// Current memory metrics snapshot.
  MemoryMetrics get currentMetrics => _buildMetrics();

  /// Stream of memory metrics updates.
  Stream<MemoryMetrics> get metricsStream => _metricsSubject.stream;

  MemoryMetrics _buildMetrics() {
    final pinnedBytes = _pinnedIds.fold<int>(
      0,
      (sum, id) => sum + (_itemSizes[id] ?? 0),
    );

    return MemoryMetrics(
      currentBytes: currentBytes,
      maxBytes: _maxBytes,
      evictionCount: _evictionCount,
      pinnedCount: _pinnedIds.length,
      pinnedBytes: pinnedBytes,
      pressureLevel: currentLevel,
      itemCount: itemCount,
      timestamp: DateTime.now(),
    );
  }

  void _emitMetrics() {
    _metricsSubject.add(_buildMetrics());
  }

  /// Releases resources used by this manager.
  void dispose() {
    _pressureHandler.dispose();
    _metricsSubject.close();
  }
}
