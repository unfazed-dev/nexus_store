import 'package:uuid/uuid.dart';

/// Context for tracking saga execution state.
///
/// Maintains information about completed steps, timing, and status
/// for a single saga execution.
///
/// ## Example
///
/// ```dart
/// final context = SagaContext();
///
/// context.addCompletedStep('create-order', order);
/// context.addCompletedStep('charge-payment', payment);
///
/// if (needsRollback) {
///   for (final step in context.stepsToCompensate) {
///     await compensate(step.name, step.result);
///   }
/// }
/// ```
class SagaContext {
  /// Creates a new saga context.
  ///
  /// - [id]: Optional custom identifier (auto-generated if not provided)
  SagaContext({String? id})
      : id = id ?? const Uuid().v4(),
        startedAt = DateTime.now();

  /// Unique identifier for this saga execution.
  final String id;

  /// When this saga started.
  final DateTime startedAt;

  /// When this saga completed (success or failure).
  DateTime? completedAt;

  /// Steps that have been completed successfully.
  final List<CompletedStep<dynamic>> _completedSteps = [];

  /// The step that failed (if any).
  String? failedStep;

  /// The error that caused the saga to fail.
  Object? error;

  bool _isCompleted = false;
  bool _isFailed = false;

  /// All completed steps in execution order.
  List<CompletedStep<dynamic>> get completedSteps =>
      List.unmodifiable(_completedSteps);

  /// Steps to compensate in reverse order.
  List<CompletedStep<dynamic>> get stepsToCompensate =>
      _completedSteps.reversed.toList();

  /// Whether the saga is still executing.
  bool get isActive => !_isCompleted && !_isFailed;

  /// Whether the saga completed successfully.
  bool get isCompleted => _isCompleted;

  /// Whether the saga failed.
  bool get isFailed => _isFailed;

  /// Duration from start to completion (null if still active).
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Adds a completed step to the context.
  ///
  /// Throws [StateError] if the saga is no longer active.
  void addCompletedStep<T>(String name, T result) {
    if (!isActive) {
      throw StateError('Cannot add steps to inactive saga context');
    }
    _completedSteps.add(CompletedStep<T>(name, result));
  }

  /// Marks the saga as successfully completed.
  void markCompleted() {
    if (!isActive) return;
    _isCompleted = true;
    completedAt = DateTime.now();
  }

  /// Marks the saga as failed.
  void markFailed(String stepName, Object err) {
    if (!isActive) return;
    _isFailed = true;
    failedStep = stepName;
    error = err;
    completedAt = DateTime.now();
  }

  /// Gets the result of a completed step by name.
  ///
  /// Returns null if the step doesn't exist.
  T? getStepResult<T>(String name) {
    try {
      final step = _completedSteps.firstWhere((s) => s.name == name);
      return step.result as T;
    } catch (_) {
      return null;
    }
  }

  /// Whether a step with the given name has been completed.
  bool hasStep(String name) {
    return _completedSteps.any((s) => s.name == name);
  }

  @override
  String toString() {
    final status = isActive
        ? 'active'
        : isCompleted
            ? 'completed'
            : 'failed';
    return 'SagaContext(id: $id, status: $status, '
        'steps: ${_completedSteps.length})';
  }
}

/// Represents a completed saga step with its result.
class CompletedStep<T> {
  /// Creates a completed step record.
  CompletedStep(this.name, this.result) : completedAt = DateTime.now();

  /// The name of the step.
  final String name;

  /// The result returned by the step's action.
  final T result;

  /// When this step completed.
  final DateTime completedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedStep && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CompletedStep(name: $name, result: $result)';
}
