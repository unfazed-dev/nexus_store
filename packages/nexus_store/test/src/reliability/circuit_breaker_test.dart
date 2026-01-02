import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/circuit_breaker.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_config.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          successThreshold: 2,
          openDuration: Duration(milliseconds: 100),
          halfOpenMaxRequests: 2,
        ),
      );
    });

    tearDown(() {
      circuitBreaker.dispose();
    });

    group('initial state', () {
      test('starts in closed state', () {
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
      });

      test('allows requests initially', () {
        expect(circuitBreaker.allowsRequest, isTrue);
      });

      test('has empty metrics initially', () {
        final metrics = circuitBreaker.currentMetrics;
        expect(metrics.state, equals(CircuitBreakerState.closed));
        expect(metrics.failureCount, equals(0));
        expect(metrics.successCount, equals(0));
      });
    });

    group('recordSuccess', () {
      test('increments success count', () {
        circuitBreaker.recordSuccess();
        expect(circuitBreaker.currentMetrics.successCount, equals(1));
      });

      test('increments total requests', () {
        circuitBreaker.recordSuccess();
        expect(circuitBreaker.currentMetrics.totalRequests, equals(1));
      });

      test('keeps circuit closed after success', () {
        circuitBreaker.recordSuccess();
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
      });
    });

    group('recordFailure', () {
      test('increments failure count', () {
        circuitBreaker.recordFailure();
        expect(circuitBreaker.currentMetrics.failureCount, equals(1));
      });

      test('increments total requests', () {
        circuitBreaker.recordFailure();
        expect(circuitBreaker.currentMetrics.totalRequests, equals(1));
      });

      test('keeps circuit closed below threshold', () {
        circuitBreaker.recordFailure();
        circuitBreaker.recordFailure();
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
      });

      test('opens circuit at failure threshold', () {
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.open));
      });

      test('updates lastFailureTime', () {
        final before = DateTime.now();
        circuitBreaker.recordFailure();
        final after = DateTime.now();

        final lastFailureTime = circuitBreaker.currentMetrics.lastFailureTime;
        expect(lastFailureTime, isNotNull);
        expect(
          lastFailureTime!.isAfter(before) ||
              lastFailureTime.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          lastFailureTime.isBefore(after) ||
              lastFailureTime.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('state transitions', () {
      test('closed to open when failures reach threshold', () {
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));

        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        expect(circuitBreaker.currentState, equals(CircuitBreakerState.open));
      });

      test('open to halfOpen after cooldown', () async {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.open));

        // Wait for cooldown (openDuration is 100ms)
        await Future.delayed(const Duration(milliseconds: 150));

        expect(
            circuitBreaker.currentState, equals(CircuitBreakerState.halfOpen));
      });

      test('halfOpen to closed after success threshold', () async {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        // Wait for half-open
        await Future.delayed(const Duration(milliseconds: 150));
        expect(
            circuitBreaker.currentState, equals(CircuitBreakerState.halfOpen));

        // Record successes
        circuitBreaker.recordSuccess();
        circuitBreaker.recordSuccess();

        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
      });

      test('halfOpen to open on failure', () async {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        // Wait for half-open
        await Future.delayed(const Duration(milliseconds: 150));
        expect(
            circuitBreaker.currentState, equals(CircuitBreakerState.halfOpen));

        // Record failure
        circuitBreaker.recordFailure();

        expect(circuitBreaker.currentState, equals(CircuitBreakerState.open));
      });
    });

    group('allowsRequest', () {
      test('returns true when closed', () {
        expect(circuitBreaker.allowsRequest, isTrue);
      });

      test('returns false when open', () {
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }
        expect(circuitBreaker.allowsRequest, isFalse);
      });

      test('returns true when halfOpen (limited)', () async {
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }
        await Future.delayed(const Duration(milliseconds: 150));

        expect(circuitBreaker.allowsRequest, isTrue);
      });
    });

    group('stateStream', () {
      test('emits state changes', () async {
        final states = <CircuitBreakerState>[];
        final subscription = circuitBreaker.stateStream.listen(states.add);

        // Trigger state change: closed -> open
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        await Future.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();

        expect(states, contains(CircuitBreakerState.open));
      });

      test('emits distinct state changes only', () async {
        final states = <CircuitBreakerState>[];
        final subscription = circuitBreaker.stateStream.listen(states.add);

        // Record multiple failures (same state)
        circuitBreaker.recordFailure();
        circuitBreaker.recordFailure();
        circuitBreaker.recordFailure(); // This triggers open

        await Future.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();

        // Should only emit once for open state
        expect(states.where((s) => s == CircuitBreakerState.open).length,
            equals(1));
      });
    });

    group('execute', () {
      test('executes operation when closed', () async {
        var called = false;
        await circuitBreaker.execute(() async {
          called = true;
          return 'success';
        });
        expect(called, isTrue);
      });

      test('returns operation result', () async {
        final result = await circuitBreaker.execute(() async => 42);
        expect(result, equals(42));
      });

      test('records success on successful execution', () async {
        await circuitBreaker.execute(() async => 'success');
        expect(circuitBreaker.currentMetrics.successCount, equals(1));
      });

      test('records failure on exception', () async {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('test error');
          });
        } catch (_) {}

        expect(circuitBreaker.currentMetrics.failureCount, equals(1));
      });

      test('rethrows exception from operation', () async {
        expect(
          () => circuitBreaker.execute(() async {
            throw Exception('test error');
          }),
          throwsException,
        );
      });

      test('throws CircuitBreakerOpenException when open', () async {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        expect(
          () => circuitBreaker.execute(() async => 'success'),
          throwsA(isA<CircuitBreakerOpenException>()),
        );
      });

      test('increments rejected count when open', () async {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        try {
          await circuitBreaker.execute(() async => 'success');
        } catch (_) {}

        expect(circuitBreaker.currentMetrics.rejectedRequests, equals(1));
      });
    });

    group('reset', () {
      test('resets to closed state', () {
        // Open the circuit
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.open));

        circuitBreaker.reset();

        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
      });

      test('resets failure count', () {
        circuitBreaker.recordFailure();
        circuitBreaker.recordFailure();

        circuitBreaker.reset();

        expect(circuitBreaker.currentMetrics.failureCount, equals(0));
      });
    });

    group('onStateChange callback', () {
      test('calls callback on state change', () {
        final stateChanges = <CircuitBreakerState>[];
        final cb = CircuitBreaker(
          config: const CircuitBreakerConfig(failureThreshold: 2),
          onStateChange: stateChanges.add,
        );

        cb.recordFailure();
        cb.recordFailure();

        expect(stateChanges, contains(CircuitBreakerState.open));

        cb.dispose();
      });
    });

    group('disabled circuit breaker', () {
      test('always allows requests when disabled', () {
        final disabled = CircuitBreaker(
          config: const CircuitBreakerConfig(enabled: false),
        );

        // Record many failures
        for (var i = 0; i < 10; i++) {
          disabled.recordFailure();
        }

        expect(disabled.allowsRequest, isTrue);
        expect(disabled.currentState, equals(CircuitBreakerState.closed));

        disabled.dispose();
      });

      test('execute works when disabled', () async {
        final disabled = CircuitBreaker(
          config: const CircuitBreakerConfig(enabled: false),
        );

        // Record many failures
        for (var i = 0; i < 10; i++) {
          disabled.recordFailure();
        }

        // Should still execute
        final result = await disabled.execute(() async => 'success');
        expect(result, equals('success'));

        disabled.dispose();
      });
    });
  });

  group('CircuitBreakerOpenException', () {
    test('has correct message', () {
      const exception = CircuitBreakerOpenException(
        retryAfter: Duration(seconds: 30),
      );
      expect(exception.message, equals('Circuit breaker is open'));
    });

    test('has correct code', () {
      const exception = CircuitBreakerOpenException(
        retryAfter: Duration(seconds: 30),
      );
      expect(exception.code, equals('CIRCUIT_BREAKER_OPEN'));
    });

    test('contains retryAfter duration', () {
      const exception = CircuitBreakerOpenException(
        retryAfter: Duration(seconds: 30),
      );
      expect(exception.retryAfter, equals(const Duration(seconds: 30)));
    });

    test('isRetryable returns true', () {
      const exception = CircuitBreakerOpenException(
        retryAfter: Duration(seconds: 30),
      );
      expect(exception.isRetryable, isTrue);
    });
  });
}
