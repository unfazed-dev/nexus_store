import 'package:meta/meta.dart';

/// Represents the result of a saga execution.
///
/// A saga can complete in one of three states:
/// - [SagaSuccess]: All steps completed successfully
/// - [SagaFailure]: A step failed, but compensations succeeded
/// - [SagaPartialFailure]: A step failed AND some compensations also failed
///
/// ## Pattern Matching
///
/// Use [when] or [maybeWhen] for exhaustive pattern matching:
///
/// ```dart
/// result.when(
///   success: (results) => print('All ${results.length} steps completed'),
///   failure: (error, failedStep, compensated) =>
///       print('Step $failedStep failed, rolled back: $compensated'),
///   partialFailure: (error, failedStep, compErrors) =>
///       print('CRITICAL: Compensation failed for ${compErrors.length} steps'),
/// );
/// ```
@immutable
sealed class SagaResult<T> {
  const SagaResult._();

  /// Creates a success result with all step results.
  const factory SagaResult.success(List<T> results) = SagaSuccess<T>;

  /// Creates a failure result where compensations succeeded.
  const factory SagaResult.failure(
    Object error, {
    required String failedStep,
    required List<String> compensatedSteps,
  }) = SagaFailure<T>;

  /// Creates a partial failure where some compensations also failed.
  const factory SagaResult.partialFailure(
    Object error, {
    required String failedStep,
    required List<SagaCompensationError> compensationErrors,
  }) = SagaPartialFailure<T>;

  /// Whether this result represents a successful saga completion.
  bool get isSuccess;

  /// Whether this result represents a failed saga with successful compensations.
  bool get isFailure;

  /// Whether this result represents a failed saga with failed compensations.
  bool get isPartialFailure;

  /// The results of completed steps (empty for failures).
  List<T> get results;

  /// The error that caused the saga to fail (null for success).
  Object? get error;

  /// Pattern matching method covering all states.
  R when<R>({
    required R Function(List<T> results) success,
    required R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    ) failure,
    required R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    ) partialFailure,
  });

  /// Pattern matching with optional handlers and fallback.
  R maybeWhen<R>({
    R Function(List<T> results)? success,
    R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    )? failure,
    R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    )? partialFailure,
    required R Function() orElse,
  });
}

/// Successful saga completion with all step results.
@immutable
class SagaSuccess<T> extends SagaResult<T> {
  /// Creates a success result.
  const SagaSuccess(this.results) : super._();

  @override
  final List<T> results;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  bool get isPartialFailure => false;

  @override
  Object? get error => null;

  @override
  R when<R>({
    required R Function(List<T> results) success,
    required R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    ) failure,
    required R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    ) partialFailure,
  }) =>
      success(results);

  @override
  R maybeWhen<R>({
    R Function(List<T> results)? success,
    R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    )? failure,
    R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    )? partialFailure,
    required R Function() orElse,
  }) =>
      success?.call(results) ?? orElse();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaSuccess<T> &&
          runtimeType == other.runtimeType &&
          _listEquals(results, other.results);

  @override
  int get hashCode => Object.hashAll(results);

  @override
  String toString() => 'SagaSuccess<$T>(results: $results)';
}

/// Failed saga where compensations completed successfully.
@immutable
class SagaFailure<T> extends SagaResult<T> {
  /// Creates a failure result.
  const SagaFailure(
    this.error, {
    required this.failedStep,
    required this.compensatedSteps,
  }) : super._();

  @override
  final Object error;

  /// The name of the step that failed.
  final String failedStep;

  /// Names of steps that were successfully compensated (in reverse order).
  final List<String> compensatedSteps;

  @override
  List<T> get results => const [];

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  bool get isPartialFailure => false;

  @override
  R when<R>({
    required R Function(List<T> results) success,
    required R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    ) failure,
    required R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    ) partialFailure,
  }) =>
      failure(error, failedStep, compensatedSteps);

  @override
  R maybeWhen<R>({
    R Function(List<T> results)? success,
    R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    )? failure,
    R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    )? partialFailure,
    required R Function() orElse,
  }) =>
      failure?.call(error, failedStep, compensatedSteps) ?? orElse();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          failedStep == other.failedStep &&
          _listEquals(compensatedSteps, other.compensatedSteps);

  @override
  int get hashCode => Object.hash(error, failedStep, Object.hashAll(compensatedSteps));

  @override
  String toString() => 'SagaFailure<$T>('
      'error: $error, '
      'failedStep: $failedStep, '
      'compensatedSteps: $compensatedSteps)';
}

/// Failed saga where some compensations also failed.
///
/// This is a critical state that may require manual intervention.
@immutable
class SagaPartialFailure<T> extends SagaResult<T> {
  /// Creates a partial failure result.
  const SagaPartialFailure(
    this.error, {
    required this.failedStep,
    required this.compensationErrors,
  }) : super._();

  @override
  final Object error;

  /// The name of the step that failed.
  final String failedStep;

  /// Errors from failed compensation attempts.
  final List<SagaCompensationError> compensationErrors;

  @override
  List<T> get results => const [];

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => false;

  @override
  bool get isPartialFailure => true;

  @override
  R when<R>({
    required R Function(List<T> results) success,
    required R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    ) failure,
    required R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    ) partialFailure,
  }) =>
      partialFailure(error, failedStep, compensationErrors);

  @override
  R maybeWhen<R>({
    R Function(List<T> results)? success,
    R Function(
      Object error,
      String failedStep,
      List<String> compensatedSteps,
    )? failure,
    R Function(
      Object error,
      String failedStep,
      List<SagaCompensationError> compensationErrors,
    )? partialFailure,
    required R Function() orElse,
  }) =>
      partialFailure?.call(error, failedStep, compensationErrors) ?? orElse();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaPartialFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          failedStep == other.failedStep &&
          _listEquals(compensationErrors, other.compensationErrors);

  @override
  int get hashCode =>
      Object.hash(error, failedStep, Object.hashAll(compensationErrors));

  @override
  String toString() => 'SagaPartialFailure<$T>('
      'error: $error, '
      'failedStep: $failedStep, '
      'compensationErrors: $compensationErrors)';
}

/// Represents a compensation that failed during saga rollback.
@immutable
class SagaCompensationError {
  /// Creates a compensation error.
  const SagaCompensationError({
    required this.stepName,
    required this.error,
    this.stackTrace,
  });

  /// The name of the step whose compensation failed.
  final String stepName;

  /// The error that occurred during compensation.
  final Object error;

  /// Stack trace when the error occurred.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaCompensationError &&
          runtimeType == other.runtimeType &&
          stepName == other.stepName &&
          error == other.error;

  @override
  int get hashCode => Object.hash(stepName, error);

  @override
  String toString() =>
      'SagaCompensationError(stepName: $stepName, error: $error)';
}

/// Helper to compare lists for equality.
bool _listEquals<E>(List<E> a, List<E> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
