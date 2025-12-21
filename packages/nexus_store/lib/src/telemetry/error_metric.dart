import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_metric.freezed.dart';

/// Metric for tracking errors.
///
/// Records errors that occur during store operations for debugging
/// and monitoring purposes.
///
/// ## Example
///
/// ```dart
/// final metric = ErrorMetric(
///   error: Exception('Network timeout'),
///   stackTrace: StackTrace.current,
///   operation: 'sync',
///   recoverable: false,
///   timestamp: DateTime.now(),
/// );
/// ```
@freezed
abstract class ErrorMetric with _$ErrorMetric {
  /// Creates an error metric.
  const factory ErrorMetric({
    /// The error that occurred.
    required Object error,

    /// Stack trace at time of error.
    StackTrace? stackTrace,

    /// The operation that was being performed.
    String? operation,

    /// Whether the error was recoverable.
    @Default(false) bool recoverable,

    /// When the error occurred.
    required DateTime timestamp,
  }) = _ErrorMetric;

  const ErrorMetric._();
}
