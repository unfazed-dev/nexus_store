import 'package:meta/meta.dart';

/// Events emitted during saga execution for observability.
///
/// Subscribe to a saga's event stream to track progress:
///
/// ```dart
/// saga.events.listen((event) {
///   if (event.event == SagaEvent.stepFailed) {
///     logger.error('Step ${event.stepName} failed: ${event.error}');
///   }
/// });
/// ```
enum SagaEvent {
  /// Saga execution started.
  sagaStarted,

  /// Saga completed successfully.
  sagaCompleted,

  /// Saga failed (after compensations).
  sagaFailed,

  /// A step started executing.
  stepStarted,

  /// A step completed successfully.
  stepCompleted,

  /// A step failed.
  stepFailed,

  /// Compensation started for a step.
  compensationStarted,

  /// Compensation completed for a step.
  compensationCompleted,

  /// Compensation failed for a step.
  compensationFailed,
}

/// Data associated with a saga event.
///
/// Provides context about what happened during saga execution.
@immutable
class SagaEventData {
  /// Creates saga event data.
  const SagaEventData({
    required this.event,
    required this.sagaId,
    this.stepName,
    required this.timestamp,
    this.error,
    this.duration,
    this.stepIndex,
    this.totalSteps,
  });

  /// The type of event.
  final SagaEvent event;

  /// Unique identifier for this saga execution.
  final String sagaId;

  /// The name of the step (null for saga-level events).
  final String? stepName;

  /// When this event occurred.
  final DateTime timestamp;

  /// The error if this is a failure event.
  final Object? error;

  /// Duration of the step or compensation (for completed/failed events).
  final Duration? duration;

  /// Index of the current step (0-based).
  final int? stepIndex;

  /// Total number of steps in the saga.
  final int? totalSteps;

  /// Whether this is a step-level event.
  bool get isStepEvent =>
      event == SagaEvent.stepStarted ||
      event == SagaEvent.stepCompleted ||
      event == SagaEvent.stepFailed;

  /// Whether this is a compensation event.
  bool get isCompensationEvent =>
      event == SagaEvent.compensationStarted ||
      event == SagaEvent.compensationCompleted ||
      event == SagaEvent.compensationFailed;

  /// Whether this is a saga lifecycle event.
  bool get isSagaEvent =>
      event == SagaEvent.sagaStarted ||
      event == SagaEvent.sagaCompleted ||
      event == SagaEvent.sagaFailed;

  /// Whether this event indicates a failure.
  bool get isFailure =>
      event == SagaEvent.stepFailed ||
      event == SagaEvent.compensationFailed ||
      event == SagaEvent.sagaFailed;

  /// Whether this event indicates success.
  bool get isSuccess =>
      event == SagaEvent.stepCompleted ||
      event == SagaEvent.compensationCompleted ||
      event == SagaEvent.sagaCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaEventData &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          sagaId == other.sagaId &&
          stepName == other.stepName &&
          timestamp == other.timestamp &&
          error == other.error &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(
        event,
        sagaId,
        stepName,
        timestamp,
        error,
        duration,
      );

  @override
  String toString() {
    final buffer = StringBuffer('SagaEventData(')
      ..write('event: ${event.name}')
      ..write(', sagaId: $sagaId');

    if (stepName != null) {
      buffer.write(', stepName: $stepName');
    }
    if (duration != null) {
      buffer.write(', duration: ${duration!.inMilliseconds}ms');
    }
    if (error != null) {
      buffer.write(', error: $error');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
