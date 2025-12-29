import 'dart:async';

import 'package:nexus_store/src/errors/store_errors.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_config.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_metrics.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';
import 'package:rxdart/rxdart.dart';

// Re-export CircuitBreakerOpenException for convenience
export 'package:nexus_store/src/errors/store_errors.dart'
    show CircuitBreakerOpenException;

/// Circuit breaker pattern implementation for preventing cascade failures.
///
/// Monitors failures and automatically "opens" (blocks requests) when
/// failures exceed a threshold, allowing the backend to recover.
///
/// ## State Machine
///
/// ```
/// [closed] --failures >= threshold--> [open]
/// [open] --cooldown elapsed--> [halfOpen]
/// [halfOpen] --successes >= threshold--> [closed]
/// [halfOpen] --any failure--> [open]
/// ```
///
/// ## Example
///
/// ```dart
/// final circuitBreaker = CircuitBreaker(
///   config: CircuitBreakerConfig(
///     failureThreshold: 5,
///     successThreshold: 2,
///     openDuration: Duration(seconds: 30),
///   ),
/// );
///
/// try {
///   final result = await circuitBreaker.execute(() async {
///     return await apiClient.fetchData();
///   });
/// } on CircuitBreakerOpenException catch (e) {
///   print('Service unavailable, retry after ${e.retryAfter}');
/// }
/// ```
class CircuitBreaker {
  /// Creates a circuit breaker with the given configuration.
  CircuitBreaker({
    required CircuitBreakerConfig config,
    void Function(CircuitBreakerState)? onStateChange,
  })  : _config = config,
        _onStateChange = onStateChange,
        _stateSubject = BehaviorSubject.seeded(CircuitBreakerState.closed),
        _metricsSubject = BehaviorSubject.seeded(CircuitBreakerMetrics.empty());

  final CircuitBreakerConfig _config;
  final void Function(CircuitBreakerState)? _onStateChange;
  final BehaviorSubject<CircuitBreakerState> _stateSubject;
  final BehaviorSubject<CircuitBreakerMetrics> _metricsSubject;

  Timer? _openTimer;
  int _failureCount = 0;
  int _successCount = 0;
  int _totalRequests = 0;
  int _rejectedRequests = 0;
  int _halfOpenSuccessCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastStateChange;

  /// Current state of the circuit breaker.
  CircuitBreakerState get currentState => _stateSubject.value;

  /// Stream of state changes.
  ///
  /// Emits distinct state changes only.
  Stream<CircuitBreakerState> get stateStream => _stateSubject.stream.distinct();

  /// Current metrics snapshot.
  CircuitBreakerMetrics get currentMetrics => _buildMetrics();

  /// Stream of metrics updates.
  Stream<CircuitBreakerMetrics> get metricsStream => _metricsSubject.stream;

  /// Whether requests are currently allowed.
  ///
  /// Returns `true` when the circuit is closed or half-open,
  /// `false` when open.
  bool get allowsRequest {
    if (!_config.enabled) return true;
    return currentState.allowsRequests;
  }

  /// Records a successful operation.
  ///
  /// In half-open state, successes count toward closing the circuit.
  void recordSuccess() {
    if (!_config.enabled) return;

    _successCount++;
    _totalRequests++;

    if (currentState == CircuitBreakerState.halfOpen) {
      _halfOpenSuccessCount++;
      if (_halfOpenSuccessCount >= _config.successThreshold) {
        _transitionTo(CircuitBreakerState.closed);
        _resetCounts();
      }
    }

    _emitMetrics();
  }

  /// Records a failed operation.
  ///
  /// Failures count toward opening the circuit. In half-open state,
  /// any failure immediately reopens the circuit.
  void recordFailure() {
    if (!_config.enabled) return;

    _failureCount++;
    _totalRequests++;
    _lastFailureTime = DateTime.now();

    if (currentState == CircuitBreakerState.halfOpen) {
      // Any failure in half-open immediately opens
      _transitionTo(CircuitBreakerState.open);
      _startOpenTimer();
    } else if (currentState == CircuitBreakerState.closed) {
      if (_failureCount >= _config.failureThreshold) {
        _transitionTo(CircuitBreakerState.open);
        _startOpenTimer();
      }
    }

    _emitMetrics();
  }

  /// Executes an operation with circuit breaker protection.
  ///
  /// Throws [CircuitBreakerOpenException] if the circuit is open.
  /// Records success or failure based on the operation result.
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!allowsRequest) {
      _rejectedRequests++;
      _emitMetrics();
      throw CircuitBreakerOpenException(
        retryAfter: _config.openDuration,
      );
    }

    try {
      final result = await operation();
      recordSuccess();
      return result;
    } catch (e) {
      recordFailure();
      rethrow;
    }
  }

  /// Resets the circuit breaker to closed state.
  ///
  /// Clears all counters and cancels any pending timers.
  void reset() {
    _openTimer?.cancel();
    _openTimer = null;
    _resetCounts();
    _transitionTo(CircuitBreakerState.closed);
    _emitMetrics();
  }

  /// Releases resources used by the circuit breaker.
  void dispose() {
    _openTimer?.cancel();
    _stateSubject.close();
    _metricsSubject.close();
  }

  void _transitionTo(CircuitBreakerState newState) {
    if (_stateSubject.value == newState) return;

    _lastStateChange = DateTime.now();
    _stateSubject.add(newState);
    _onStateChange?.call(newState);
  }

  void _startOpenTimer() {
    _openTimer?.cancel();
    _openTimer = Timer(_config.openDuration, () {
      _halfOpenSuccessCount = 0;
      _transitionTo(CircuitBreakerState.halfOpen);
      _emitMetrics();
    });
  }

  void _resetCounts() {
    _failureCount = 0;
    _successCount = 0;
    _halfOpenSuccessCount = 0;
  }

  CircuitBreakerMetrics _buildMetrics() {
    return CircuitBreakerMetrics(
      state: currentState,
      failureCount: _failureCount,
      successCount: _successCount,
      totalRequests: _totalRequests,
      rejectedRequests: _rejectedRequests,
      timestamp: DateTime.now(),
      lastFailureTime: _lastFailureTime,
      lastStateChange: _lastStateChange,
    );
  }

  void _emitMetrics() {
    _metricsSubject.add(_buildMetrics());
  }
}
