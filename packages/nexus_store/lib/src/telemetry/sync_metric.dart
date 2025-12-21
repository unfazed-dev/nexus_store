import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_metric.freezed.dart';

/// Types of sync events that can be tracked.
enum SyncEvent {
  /// Sync operation started.
  started,

  /// Sync operation completed successfully.
  completed,

  /// Sync operation failed.
  failed,

  /// Sync operation was retried.
  retried,

  /// A conflict was resolved during sync.
  conflictResolved,
}

/// Metric for tracking synchronization operations.
///
/// Records sync start, completion, failure, and retry events
/// for monitoring sync health and performance.
///
/// ## Example
///
/// ```dart
/// final metric = SyncMetric(
///   event: SyncEvent.completed,
///   duration: Duration(seconds: 5),
///   itemsSynced: 100,
///   timestamp: DateTime.now(),
/// );
/// ```
@freezed
abstract class SyncMetric with _$SyncMetric {
  /// Creates a sync metric.
  const factory SyncMetric({
    /// The type of sync event.
    required SyncEvent event,

    /// Duration of the sync operation (for completed/failed).
    Duration? duration,

    /// Number of items synced.
    @Default(0) int itemsSynced,

    /// Error message if sync failed.
    String? error,

    /// When the event occurred.
    required DateTime timestamp,
  }) = _SyncMetric;

  const SyncMetric._();
}
