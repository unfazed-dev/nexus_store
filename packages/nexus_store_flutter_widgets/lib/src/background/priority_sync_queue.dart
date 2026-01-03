import 'dart:collection';

import 'package:nexus_store_flutter_widgets/src/background/sync_priority.dart';

/// A priority queue for sync operations.
///
/// Items are dequeued by priority (critical first), with FIFO ordering
/// within the same priority level.
///
/// ## Example
///
/// ```dart
/// final queue = PrioritySyncQueue<SyncItem>();
///
/// // Add items with different priorities
/// queue.enqueue(criticalItem, SyncPriority.critical);
/// queue.enqueue(normalItem, SyncPriority.normal);
/// queue.enqueue(lowItem, SyncPriority.low);
///
/// // Items come out in priority order
/// queue.dequeue(); // criticalItem
/// queue.dequeue(); // normalItem
/// queue.dequeue(); // lowItem
/// ```
class PrioritySyncQueue<T> {
  /// Creates an empty priority sync queue.
  PrioritySyncQueue();

  /// Internal queues for each priority level.
  /// Using LinkedList for O(1) enqueue operations.
  final Map<SyncPriority, Queue<T>> _queues = {
    SyncPriority.critical: Queue<T>(),
    SyncPriority.high: Queue<T>(),
    SyncPriority.normal: Queue<T>(),
    SyncPriority.low: Queue<T>(),
  };

  /// Total number of items across all priority levels.
  int _length = 0;

  /// Returns true if the queue contains no items.
  bool get isEmpty => _length == 0;

  /// Returns true if the queue contains at least one item.
  bool get isNotEmpty => _length > 0;

  /// Returns the total number of items in the queue.
  int get length => _length;

  /// Adds an item to the queue with the specified priority.
  ///
  /// Items with the same priority are processed in FIFO order.
  void enqueue(T item, SyncPriority priority) {
    _queues[priority]!.add(item);
    _length++;
  }

  /// Removes and returns the highest priority item.
  ///
  /// Returns `null` if the queue is empty.
  /// Among items with the same priority, returns the oldest (FIFO).
  T? dequeue() {
    if (isEmpty) return null;

    // Check each priority level in order
    for (final priority in SyncPriority.values) {
      final queue = _queues[priority]!;
      if (queue.isNotEmpty) {
        _length--;
        return queue.removeFirst();
      }
    }

    return null;
  }

  /// Returns the highest priority item without removing it.
  ///
  /// Returns `null` if the queue is empty.
  T? peek() {
    if (isEmpty) return null;

    for (final priority in SyncPriority.values) {
      final queue = _queues[priority]!;
      if (queue.isNotEmpty) {
        return queue.first;
      }
    }

    return null;
  }

  /// Removes all items from the queue.
  void clear() {
    for (final queue in _queues.values) {
      queue.clear();
    }
    _length = 0;
  }

  /// Returns all items in priority order as a list.
  ///
  /// Does not modify the queue.
  List<T> toList() {
    final result = <T>[];
    for (final priority in SyncPriority.values) {
      result.addAll(_queues[priority]!);
    }
    return result;
  }
}
