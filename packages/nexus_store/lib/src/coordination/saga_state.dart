import 'package:meta/meta.dart';

/// Status of a saga execution.
enum SagaStatus {
  /// Saga has been created but not started.
  pending,

  /// Saga is currently executing steps.
  executing,

  /// Saga is compensating after a failure.
  compensating,

  /// Saga completed successfully.
  completed,

  /// Saga failed and all compensations succeeded.
  failed,

  /// Saga failed and some compensations also failed.
  partiallyFailed;

  /// Whether this status represents a terminal (finished) state.
  bool get isTerminal =>
      this == completed || this == failed || this == partiallyFailed;
}

/// Status of a single saga step.
enum StepStatus {
  /// Step has not been executed yet.
  pending,

  /// Step is currently executing.
  executing,

  /// Step completed successfully.
  completed,

  /// Step failed.
  failed,

  /// Step's compensation is in progress.
  compensating,

  /// Step was compensated after a later step failed.
  compensated,
}

/// Serializable state of a saga for persistence.
///
/// Used to save saga state for crash recovery.
@immutable
class SagaState {
  /// Creates a saga state.
  const SagaState({
    required this.sagaId,
    required this.status,
    required this.currentStepIndex,
    required this.steps,
    required this.startedAt,
    this.completedAt,
    this.stepResults = const {},
    this.error,
    this.failedStep,
  });

  /// Unique identifier for this saga.
  final String sagaId;

  /// Current status of the saga.
  final SagaStatus status;

  /// Index of the current step being executed.
  final int currentStepIndex;

  /// State of each step in the saga.
  final List<SagaStepState> steps;

  /// When the saga started.
  final DateTime startedAt;

  /// When the saga completed (if terminal).
  final DateTime? completedAt;

  /// Results from completed steps (keyed by step name).
  final Map<String, dynamic> stepResults;

  /// Error that caused the saga to fail (if any).
  final String? error;

  /// Name of the step that failed (if any).
  final String? failedStep;

  /// Creates a copy with updated fields.
  SagaState copyWith({
    String? sagaId,
    SagaStatus? status,
    int? currentStepIndex,
    List<SagaStepState>? steps,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? stepResults,
    String? error,
    String? failedStep,
  }) {
    return SagaState(
      sagaId: sagaId ?? this.sagaId,
      status: status ?? this.status,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stepResults: stepResults ?? this.stepResults,
      error: error ?? this.error,
      failedStep: failedStep ?? this.failedStep,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaState &&
          runtimeType == other.runtimeType &&
          sagaId == other.sagaId;

  @override
  int get hashCode => sagaId.hashCode;

  @override
  String toString() => 'SagaState('
      'sagaId: $sagaId, '
      'status: $status, '
      'currentStep: $currentStepIndex/${steps.length})';
}

/// State of a single step within a saga.
@immutable
class SagaStepState {
  /// Creates a step state.
  const SagaStepState({
    required this.name,
    required this.status,
    this.result,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  /// Name of the step.
  final String name;

  /// Current status of the step.
  final StepStatus status;

  /// Result from the step action (if completed).
  final dynamic result;

  /// Error message (if failed).
  final String? error;

  /// When the step started.
  final DateTime? startedAt;

  /// When the step completed or failed.
  final DateTime? completedAt;

  /// Creates a copy with updated fields.
  SagaStepState copyWith({
    String? name,
    StepStatus? status,
    dynamic result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return SagaStepState(
      name: name ?? this.name,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaStepState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          status == other.status;

  @override
  int get hashCode => Object.hash(name, status);

  @override
  String toString() => 'SagaStepState(name: $name, status: $status)';
}
