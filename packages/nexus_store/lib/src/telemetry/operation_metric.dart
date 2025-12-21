import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation_metric.freezed.dart';

/// Types of store operations that can be tracked.
enum OperationType {
  /// Single item retrieval.
  get,

  /// Multiple item retrieval.
  getAll,

  /// Single item save.
  save,

  /// Multiple item save.
  saveAll,

  /// Single item deletion.
  delete,

  /// Multiple item deletion.
  deleteAll,

  /// Single item watch (stream subscription).
  watch,

  /// Multiple item watch (stream subscription).
  watchAll,

  /// Synchronization operation.
  sync,

  /// Transaction operation.
  transaction,
}

/// Metric for tracking store operation performance.
///
/// Records timing, success/failure, and metadata about store operations
/// for observability and debugging purposes.
///
/// ## Example
///
/// ```dart
/// final metric = OperationMetric(
///   operation: OperationType.get,
///   duration: Duration(milliseconds: 15),
///   success: true,
///   timestamp: DateTime.now(),
/// );
/// ```
@freezed
abstract class OperationMetric with _$OperationMetric {
  /// Creates an operation metric.
  const factory OperationMetric({
    /// The type of operation performed.
    required OperationType operation,

    /// Duration of the operation.
    required Duration duration,

    /// Whether the operation succeeded.
    required bool success,

    /// Number of items affected by the operation.
    @Default(1) int itemCount,

    /// The fetch/write policy used (if applicable).
    String? policy,

    /// When the metric was recorded.
    required DateTime timestamp,

    /// Optional error message if operation failed.
    String? errorMessage,
  }) = _OperationMetric;

  const OperationMetric._();
}
