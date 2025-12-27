/// Priority level for background sync operations.
///
/// Items with higher priority (lower index) are synced before items
/// with lower priority. Within the same priority level, items are
/// processed in FIFO order.
///
/// ## Usage
///
/// ```dart
/// await store.save(
///   criticalUpdate,
///   priority: SyncPriority.critical, // Syncs first
/// );
///
/// await store.save(
///   regularUpdate,
///   priority: SyncPriority.normal, // Syncs after critical
/// );
/// ```
enum SyncPriority {
  /// Sync immediately. Use for user-initiated actions or critical data.
  ///
  /// Best for: Payment confirmations, security updates, user-visible changes.
  critical,

  /// Sync soon. Use for important but not urgent data.
  ///
  /// Best for: User preferences, recent activity, notifications.
  high,

  /// Standard priority. Default for most operations.
  ///
  /// Best for: Regular data updates, background refreshes.
  normal,

  /// Defer if busy. Use for non-urgent background operations.
  ///
  /// Best for: Analytics, logs, cached data refresh.
  low,
}
