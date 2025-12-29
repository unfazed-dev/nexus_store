import 'saga_state.dart';

/// Interface for persisting saga state.
///
/// Used for crash recovery - sagas can be resumed from their last
/// known state after application restart.
///
/// ## Example
///
/// ```dart
/// final persistence = InMemorySagaPersistence();
///
/// // Save saga state during execution
/// await persistence.save(sagaState);
///
/// // Recover after restart
/// final incomplete = await persistence.getIncomplete();
/// for (final state in incomplete) {
///   await coordinator.resume(state);
/// }
/// ```
abstract interface class SagaPersistence {
  /// Saves or updates saga state.
  ///
  /// If a saga with the same ID exists, it will be overwritten.
  Future<void> save(SagaState state);

  /// Loads saga state by ID.
  ///
  /// Returns null if no saga with the given ID exists.
  Future<SagaState?> load(String sagaId);

  /// Deletes saga state.
  ///
  /// Does nothing if no saga with the given ID exists.
  Future<void> delete(String sagaId);

  /// Returns all incomplete (non-terminal) sagas.
  ///
  /// Incomplete sagas are those with status [SagaStatus.pending],
  /// [SagaStatus.executing], or [SagaStatus.compensating].
  Future<List<SagaState>> getIncomplete();

  /// Removes all saga states.
  Future<void> clear();
}

/// In-memory implementation of [SagaPersistence].
///
/// Useful for testing and scenarios where crash recovery is not needed.
/// Data is lost when the application terminates.
class InMemorySagaPersistence implements SagaPersistence {
  final Map<String, SagaState> _states = {};

  @override
  Future<void> save(SagaState state) async {
    _states[state.sagaId] = state;
  }

  @override
  Future<SagaState?> load(String sagaId) async {
    return _states[sagaId];
  }

  @override
  Future<void> delete(String sagaId) async {
    _states.remove(sagaId);
  }

  @override
  Future<List<SagaState>> getIncomplete() async {
    return _states.values.where((state) => !state.status.isTerminal).toList();
  }

  @override
  Future<void> clear() async {
    _states.clear();
  }
}
