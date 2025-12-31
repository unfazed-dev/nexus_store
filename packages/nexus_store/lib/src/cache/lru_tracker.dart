/// Tracks cache entry access patterns for eviction decisions.
///
/// Maintains access time, access count, and size information for each
/// tracked item, enabling LRU, LFU, and size-based eviction strategies.
///
/// ## Example
///
/// ```dart
/// final tracker = LruTracker<String>();
///
/// // Record accesses
/// tracker.recordAccess('user-1', size: 1024);
/// tracker.recordAccess('user-2', size: 512);
/// tracker.recordAccess('user-1', size: 1024); // Updates access time
///
/// // Get eviction candidates (least recently used)
/// final toEvict = tracker.getEvictionCandidatesLru(5);
/// ```
class LruTracker<ID> {
  /// Creates a new LRU tracker.
  LruTracker();

  final Map<ID, _TrackedEntry> _entries = {};

  /// Records an access for [id] with the given [size].
  ///
  /// If the item is new, creates an entry. If it exists, updates the
  /// access time, increments the access count, and updates the size.
  void recordAccess(ID id, {required int size}) {
    final existing = _entries[id];
    if (existing != null) {
      _entries[id] = _TrackedEntry(
        lastAccessTime: DateTime.now(),
        accessCount: existing.accessCount + 1,
        size: size,
      );
    } else {
      _entries[id] = _TrackedEntry(
        lastAccessTime: DateTime.now(),
        accessCount: 1,
        size: size,
      );
    }
  }

  /// Removes tracking for [id].
  void remove(ID id) {
    _entries.remove(id);
  }

  /// Clears all tracked entries.
  void clear() {
    _entries.clear();
  }

  /// Returns `true` if [id] is being tracked.
  bool contains(ID id) => _entries.containsKey(id);

  /// Returns the number of tracked items.
  int get itemCount => _entries.length;

  /// Returns the total size of all tracked items.
  int get totalSize =>
      _entries.values.fold(0, (sum, entry) => sum + entry.size);

  /// Returns all tracked IDs.
  Iterable<ID> get allIds => _entries.keys;

  /// Returns the last access time for [id], or null if not tracked.
  DateTime? getLastAccessTime(ID id) => _entries[id]?.lastAccessTime;

  /// Returns the access count for [id], or 0 if not tracked.
  int getAccessCount(ID id) => _entries[id]?.accessCount ?? 0;

  /// Returns the size for [id], or 0 if not tracked.
  int getSize(ID id) => _entries[id]?.size ?? 0;

  /// Returns eviction candidates in LRU order (least recently used first).
  ///
  /// [count] is the maximum number of candidates to return.
  /// [excludeIds] contains IDs to exclude (e.g., pinned items).
  List<ID> getEvictionCandidatesLru(
    int count, {
    Set<ID>? excludeIds,
  }) {
    final candidates = _entries.entries
        .where((e) => excludeIds == null || !excludeIds.contains(e.key))
        .toList()
      ..sort(
          (a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime));

    return candidates.take(count).map((e) => e.key).toList();
  }

  /// Returns eviction candidates in LFU order (least frequently used first).
  ///
  /// [count] is the maximum number of candidates to return.
  /// [excludeIds] contains IDs to exclude (e.g., pinned items).
  List<ID> getEvictionCandidatesLfu(
    int count, {
    Set<ID>? excludeIds,
  }) {
    final candidates = _entries.entries
        .where((e) => excludeIds == null || !excludeIds.contains(e.key))
        .toList()
      ..sort((a, b) => a.value.accessCount.compareTo(b.value.accessCount));

    return candidates.take(count).map((e) => e.key).toList();
  }

  /// Returns eviction candidates by size (largest first).
  ///
  /// [count] is the maximum number of candidates to return.
  /// [excludeIds] contains IDs to exclude (e.g., pinned items).
  List<ID> getEvictionCandidatesBySize(
    int count, {
    Set<ID>? excludeIds,
  }) {
    final candidates = _entries.entries
        .where((e) => excludeIds == null || !excludeIds.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.size.compareTo(a.value.size)); // Largest first

    return candidates.take(count).map((e) => e.key).toList();
  }
}

/// Internal class to track entry metadata.
class _TrackedEntry {
  const _TrackedEntry({
    required this.lastAccessTime,
    required this.accessCount,
    required this.size,
  });

  final DateTime lastAccessTime;
  final int accessCount;
  final int size;
}
