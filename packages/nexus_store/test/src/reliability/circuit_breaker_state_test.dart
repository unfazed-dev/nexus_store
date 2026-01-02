import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';

void main() {
  group('CircuitBreakerState', () {
    group('values', () {
      test('has closed state', () {
        expect(CircuitBreakerState.closed, isNotNull);
      });

      test('has open state', () {
        expect(CircuitBreakerState.open, isNotNull);
      });

      test('has halfOpen state', () {
        expect(CircuitBreakerState.halfOpen, isNotNull);
      });

      test('has exactly 3 values', () {
        expect(CircuitBreakerState.values.length, equals(3));
      });
    });

    group('allowsRequests', () {
      test('returns true for closed state', () {
        expect(CircuitBreakerState.closed.allowsRequests, isTrue);
      });

      test('returns false for open state', () {
        expect(CircuitBreakerState.open.allowsRequests, isFalse);
      });

      test('returns true for halfOpen state', () {
        expect(CircuitBreakerState.halfOpen.allowsRequests, isTrue);
      });
    });

    group('isClosed', () {
      test('returns true only for closed state', () {
        expect(CircuitBreakerState.closed.isClosed, isTrue);
        expect(CircuitBreakerState.open.isClosed, isFalse);
        expect(CircuitBreakerState.halfOpen.isClosed, isFalse);
      });
    });

    group('isOpen', () {
      test('returns true only for open state', () {
        expect(CircuitBreakerState.closed.isOpen, isFalse);
        expect(CircuitBreakerState.open.isOpen, isTrue);
        expect(CircuitBreakerState.halfOpen.isOpen, isFalse);
      });
    });

    group('isHalfOpen', () {
      test('returns true only for halfOpen state', () {
        expect(CircuitBreakerState.closed.isHalfOpen, isFalse);
        expect(CircuitBreakerState.open.isHalfOpen, isFalse);
        expect(CircuitBreakerState.halfOpen.isHalfOpen, isTrue);
      });
    });

    group('isAtLeast', () {
      test('closed is at least closed', () {
        expect(
          CircuitBreakerState.closed.isAtLeast(CircuitBreakerState.closed),
          isTrue,
        );
      });

      test('open is at least closed', () {
        expect(
          CircuitBreakerState.open.isAtLeast(CircuitBreakerState.closed),
          isTrue,
        );
      });

      test('closed is not at least open', () {
        expect(
          CircuitBreakerState.closed.isAtLeast(CircuitBreakerState.open),
          isFalse,
        );
      });

      test('halfOpen is at least open', () {
        expect(
          CircuitBreakerState.halfOpen.isAtLeast(CircuitBreakerState.open),
          isTrue,
        );
      });

      test('open is not at least halfOpen', () {
        expect(
          CircuitBreakerState.open.isAtLeast(CircuitBreakerState.halfOpen),
          isFalse,
        );
      });
    });
  });
}
