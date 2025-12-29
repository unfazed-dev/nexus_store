import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'saga_event.dart';
import 'saga_result.dart';
import 'saga_step.dart';

/// Coordinates saga execution with automatic compensation on failure.
///
/// A saga is a sequence of steps where each step has a compensating action
/// (rollback). If any step fails, previously completed steps are compensated
/// in reverse order.
///
/// ## Example
///
/// ```dart
/// final coordinator = SagaCoordinator();
///
/// final result = await coordinator.execute([
///   SagaStep(
///     name: 'create-order',
///     action: () => orderStore.save(order),
///     compensation: (result) => orderStore.delete(result.id),
///   ),
///   SagaStep(
///     name: 'charge-payment',
///     action: () => paymentService.charge(amount),
///     compensation: (result) => paymentService.refund(result.transactionId),
///   ),
/// ]);
///
/// result.when(
///   success: (results) => print('Order completed!'),
///   failure: (error, failedStep, compensated) =>
///       print('Failed at $failedStep, rolled back: $compensated'),
///   partialFailure: (error, failedStep, compErrors) =>
///       print('CRITICAL: Compensation failed!'),
/// );
/// ```
///
/// ## Events
///
/// Subscribe to [events] to track saga progress:
///
/// ```dart
/// coordinator.events.listen((event) {
///   logger.info('${event.event}: ${event.stepName}');
/// });
/// ```
class SagaCoordinator {
  /// Creates a saga coordinator.
  ///
  /// - [timeout]: Optional overall timeout for the entire saga
  SagaCoordinator({
    this.timeout,
  }) : _eventsSubject = BehaviorSubject<SagaEventData>();

  /// Overall timeout for the entire saga execution.
  final Duration? timeout;

  final BehaviorSubject<SagaEventData> _eventsSubject;
  bool _disposed = false;

  static const _uuid = Uuid();

  /// Stream of events emitted during saga execution.
  Stream<SagaEventData> get events => _eventsSubject.stream;

  /// Executes a saga with the given steps.
  ///
  /// Returns [SagaSuccess] if all steps complete, [SagaFailure] if a step
  /// fails but compensations succeed, or [SagaPartialFailure] if compensations
  /// also fail.
  ///
  /// - [steps]: The saga steps to execute in order
  /// - [sagaId]: Optional custom ID for this saga execution
  Future<SagaResult<T>> execute<T>(
    List<SagaStep<T>> steps, {
    String? sagaId,
  }) async {
    if (_disposed) {
      throw StateError('SagaCoordinator has been disposed');
    }

    final id = sagaId ?? _uuid.v4();
    final startTime = DateTime.now();

    _emitEvent(SagaEvent.sagaStarted, id, totalSteps: steps.length);

    if (steps.isEmpty) {
      _emitEvent(SagaEvent.sagaCompleted, id, totalSteps: 0);
      return SagaResult<T>.success([]);
    }

    final results = <T>[];
    final completedSteps = <_CompletedStep<T>>[];

    try {
      // Execute with overall timeout if configured
      if (timeout != null) {
        return await _executeWithTimeout(
          steps,
          id,
          results,
          completedSteps,
          startTime,
        );
      }

      return await _executeSteps(
        steps,
        id,
        results,
        completedSteps,
      );
    } catch (e) {
      // Unexpected error - compensate what we have
      return await _handleFailure(
        e,
        'unknown',
        id,
        completedSteps,
      );
    }
  }

  Future<SagaResult<T>> _executeWithTimeout<T>(
    List<SagaStep<T>> steps,
    String sagaId,
    List<T> results,
    List<_CompletedStep<T>> completedSteps,
    DateTime startTime,
  ) async {
    try {
      return await _executeSteps(steps, sagaId, results, completedSteps)
          .timeout(timeout!);
    } on TimeoutException {
      return await _handleFailure(
        TimeoutException('Saga timeout exceeded', timeout),
        steps.length > completedSteps.length
            ? steps[completedSteps.length].name
            : 'unknown',
        sagaId,
        completedSteps,
      );
    }
  }

  Future<SagaResult<T>> _executeSteps<T>(
    List<SagaStep<T>> steps,
    String sagaId,
    List<T> results,
    List<_CompletedStep<T>> completedSteps,
  ) async {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final stepStartTime = DateTime.now();

      _emitEvent(
        SagaEvent.stepStarted,
        sagaId,
        stepName: step.name,
        stepIndex: i,
        totalSteps: steps.length,
      );

      try {
        final result = await _executeStepWithTimeout(step);

        final duration = DateTime.now().difference(stepStartTime);
        _emitEvent(
          SagaEvent.stepCompleted,
          sagaId,
          stepName: step.name,
          stepIndex: i,
          totalSteps: steps.length,
          duration: duration,
        );

        results.add(result);
        completedSteps.add(_CompletedStep(step, result));
      } catch (e) {
        _emitEvent(
          SagaEvent.stepFailed,
          sagaId,
          stepName: step.name,
          stepIndex: i,
          totalSteps: steps.length,
          error: e,
        );

        return await _handleFailure(e, step.name, sagaId, completedSteps);
      }
    }

    _emitEvent(SagaEvent.sagaCompleted, sagaId, totalSteps: steps.length);
    return SagaResult<T>.success(results);
  }

  Future<T> _executeStepWithTimeout<T>(SagaStep<T> step) async {
    if (step.timeout != null) {
      return await step.action().timeout(step.timeout!);
    }
    return await step.action();
  }

  Future<SagaResult<T>> _handleFailure<T>(
    Object error,
    String failedStepName,
    String sagaId,
    List<_CompletedStep<T>> completedSteps,
  ) async {
    if (completedSteps.isEmpty) {
      _emitEvent(SagaEvent.sagaFailed, sagaId, error: error);
      return SagaResult<T>.failure(
        error,
        failedStep: failedStepName,
        compensatedSteps: [],
      );
    }

    final compensatedSteps = <String>[];
    final compensationErrors = <SagaCompensationError>[];

    // Compensate in reverse order
    for (final completed in completedSteps.reversed) {
      final compStartTime = DateTime.now();

      _emitEvent(
        SagaEvent.compensationStarted,
        sagaId,
        stepName: completed.step.name,
      );

      try {
        await completed.step.compensation(completed.result);

        final duration = DateTime.now().difference(compStartTime);
        _emitEvent(
          SagaEvent.compensationCompleted,
          sagaId,
          stepName: completed.step.name,
          duration: duration,
        );

        compensatedSteps.add(completed.step.name);
      } catch (compError, stackTrace) {
        _emitEvent(
          SagaEvent.compensationFailed,
          sagaId,
          stepName: completed.step.name,
          error: compError,
        );

        compensationErrors.add(SagaCompensationError(
          stepName: completed.step.name,
          error: compError,
          stackTrace: stackTrace,
        ));
      }
    }

    _emitEvent(SagaEvent.sagaFailed, sagaId, error: error);

    if (compensationErrors.isNotEmpty) {
      return SagaResult<T>.partialFailure(
        error,
        failedStep: failedStepName,
        compensationErrors: compensationErrors,
      );
    }

    return SagaResult<T>.failure(
      error,
      failedStep: failedStepName,
      compensatedSteps: compensatedSteps,
    );
  }

  void _emitEvent(
    SagaEvent event,
    String sagaId, {
    String? stepName,
    int? stepIndex,
    int? totalSteps,
    Duration? duration,
    Object? error,
  }) {
    if (_disposed) return;

    _eventsSubject.add(SagaEventData(
      event: event,
      sagaId: sagaId,
      stepName: stepName,
      timestamp: DateTime.now(),
      duration: duration,
      error: error,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
    ));
  }

  /// Disposes the coordinator and closes the event stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _eventsSubject.close();
  }
}

/// Internal class to track completed steps for compensation.
class _CompletedStep<T> {
  const _CompletedStep(this.step, this.result);

  final SagaStep<T> step;
  final T result;
}
