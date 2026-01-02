import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_metrics.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';

void main() {
  group('CircuitBreakerMetrics', () {
    group('empty factory', () {
      test('creates metrics with closed state', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.state, equals(CircuitBreakerState.closed));
      });

      test('creates metrics with zero failure count', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.failureCount, equals(0));
      });

      test('creates metrics with zero success count', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.successCount, equals(0));
      });

      test('creates metrics with zero total requests', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.totalRequests, equals(0));
      });

      test('creates metrics with zero rejected requests', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.rejectedRequests, equals(0));
      });

      test('creates metrics with null lastFailureTime', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.lastFailureTime, isNull);
      });

      test('creates metrics with null lastStateChange', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.lastStateChange, isNull);
      });

      test('creates metrics with current timestamp', () {
        final before = DateTime.now();
        final metrics = CircuitBreakerMetrics.empty();
        final after = DateTime.now();

        expect(
          metrics.timestamp.isAfter(before) ||
              metrics.timestamp.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          metrics.timestamp.isBefore(after) ||
              metrics.timestamp.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('custom values', () {
      test('can create with custom state', () {
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.open,
          failureCount: 5,
          successCount: 0,
          totalRequests: 10,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.state, equals(CircuitBreakerState.open));
      });

      test('can create with custom failure count', () {
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 3,
          successCount: 0,
          totalRequests: 5,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.failureCount, equals(3));
      });

      test('can create with lastFailureTime', () {
        final failureTime = DateTime.now();
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 1,
          successCount: 0,
          totalRequests: 1,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
          lastFailureTime: failureTime,
        );
        expect(metrics.lastFailureTime, equals(failureTime));
      });

      test('can create with lastStateChange', () {
        final stateChange = DateTime.now();
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.open,
          failureCount: 5,
          successCount: 0,
          totalRequests: 10,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
          lastStateChange: stateChange,
        );
        expect(metrics.lastStateChange, equals(stateChange));
      });
    });

    group('failureRate', () {
      test('returns 0 when totalRequests is 0', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.failureRate, equals(0.0));
      });

      test('calculates correct failure rate', () {
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 3,
          successCount: 7,
          totalRequests: 10,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.failureRate, equals(0.3));
      });

      test('returns 1.0 when all requests failed', () {
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.open,
          failureCount: 5,
          successCount: 0,
          totalRequests: 5,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.failureRate, equals(1.0));
      });
    });

    group('successRate', () {
      test('returns 0 when totalRequests is 0', () {
        final metrics = CircuitBreakerMetrics.empty();
        expect(metrics.successRate, equals(0.0));
      });

      test('calculates correct success rate', () {
        final metrics = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 3,
          successCount: 7,
          totalRequests: 10,
          rejectedRequests: 0,
          timestamp: DateTime.now(),
        );
        expect(metrics.successRate, equals(0.7));
      });
    });

    group('copyWith', () {
      test('creates copy with updated state', () {
        final original = CircuitBreakerMetrics.empty();
        final copy = original.copyWith(state: CircuitBreakerState.open);
        expect(copy.state, equals(CircuitBreakerState.open));
        expect(copy.failureCount, equals(original.failureCount));
      });

      test('creates copy with updated failure count', () {
        final original = CircuitBreakerMetrics.empty();
        final copy = original.copyWith(failureCount: 5);
        expect(copy.failureCount, equals(5));
        expect(copy.state, equals(original.state));
      });
    });

    group('equality', () {
      test('equal metrics are equal', () {
        final timestamp = DateTime.now();
        final metrics1 = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 0,
          successCount: 0,
          totalRequests: 0,
          rejectedRequests: 0,
          timestamp: timestamp,
        );
        final metrics2 = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 0,
          successCount: 0,
          totalRequests: 0,
          rejectedRequests: 0,
          timestamp: timestamp,
        );
        expect(metrics1, equals(metrics2));
      });

      test('different metrics are not equal', () {
        final timestamp = DateTime.now();
        final metrics1 = CircuitBreakerMetrics(
          state: CircuitBreakerState.closed,
          failureCount: 0,
          successCount: 0,
          totalRequests: 0,
          rejectedRequests: 0,
          timestamp: timestamp,
        );
        final metrics2 = CircuitBreakerMetrics(
          state: CircuitBreakerState.open,
          failureCount: 5,
          successCount: 0,
          totalRequests: 5,
          rejectedRequests: 0,
          timestamp: timestamp,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });
    });
  });
}
