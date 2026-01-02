import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_config.dart';

void main() {
  group('CircuitBreakerConfig', () {
    group('default values', () {
      test('failureThreshold defaults to 5', () {
        const config = CircuitBreakerConfig();
        expect(config.failureThreshold, equals(5));
      });

      test('successThreshold defaults to 3', () {
        const config = CircuitBreakerConfig();
        expect(config.successThreshold, equals(3));
      });

      test('openDuration defaults to 30 seconds', () {
        const config = CircuitBreakerConfig();
        expect(config.openDuration, equals(const Duration(seconds: 30)));
      });

      test('halfOpenMaxRequests defaults to 3', () {
        const config = CircuitBreakerConfig();
        expect(config.halfOpenMaxRequests, equals(3));
      });

      test('enabled defaults to true', () {
        const config = CircuitBreakerConfig();
        expect(config.enabled, isTrue);
      });
    });

    group('custom values', () {
      test('can set failureThreshold', () {
        const config = CircuitBreakerConfig(failureThreshold: 10);
        expect(config.failureThreshold, equals(10));
      });

      test('can set successThreshold', () {
        const config = CircuitBreakerConfig(successThreshold: 5);
        expect(config.successThreshold, equals(5));
      });

      test('can set openDuration', () {
        const config = CircuitBreakerConfig(
          openDuration: Duration(minutes: 1),
        );
        expect(config.openDuration, equals(const Duration(minutes: 1)));
      });

      test('can set halfOpenMaxRequests', () {
        const config = CircuitBreakerConfig(halfOpenMaxRequests: 5);
        expect(config.halfOpenMaxRequests, equals(5));
      });

      test('can disable circuit breaker', () {
        const config = CircuitBreakerConfig(enabled: false);
        expect(config.enabled, isFalse);
      });
    });

    group('presets', () {
      test('defaults preset has expected values', () {
        const config = CircuitBreakerConfig.defaults;
        expect(config.failureThreshold, equals(5));
        expect(config.successThreshold, equals(3));
        expect(config.openDuration, equals(const Duration(seconds: 30)));
      });

      test('aggressive preset has lower failure threshold', () {
        const config = CircuitBreakerConfig.aggressive;
        expect(config.failureThreshold, equals(3));
        expect(config.openDuration, equals(const Duration(seconds: 60)));
      });

      test('lenient preset has higher failure threshold', () {
        const config = CircuitBreakerConfig.lenient;
        expect(config.failureThreshold, equals(10));
        expect(config.openDuration, equals(const Duration(seconds: 15)));
      });

      test('disabled preset has enabled false', () {
        const config = CircuitBreakerConfig.disabled;
        expect(config.enabled, isFalse);
      });
    });

    group('validation', () {
      test('isValid returns true for valid config', () {
        const config = CircuitBreakerConfig();
        expect(config.isValid, isTrue);
      });

      test('isValid returns false when failureThreshold is 0', () {
        const config = CircuitBreakerConfig(failureThreshold: 0);
        expect(config.isValid, isFalse);
      });

      test('isValid returns false when successThreshold is 0', () {
        const config = CircuitBreakerConfig(successThreshold: 0);
        expect(config.isValid, isFalse);
      });

      test('isValid returns false when halfOpenMaxRequests is 0', () {
        const config = CircuitBreakerConfig(halfOpenMaxRequests: 0);
        expect(config.isValid, isFalse);
      });

      test('isValid returns false when openDuration is zero', () {
        const config = CircuitBreakerConfig(openDuration: Duration.zero);
        expect(config.isValid, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated failureThreshold', () {
        const config = CircuitBreakerConfig();
        final copy = config.copyWith(failureThreshold: 10);
        expect(copy.failureThreshold, equals(10));
        expect(copy.successThreshold, equals(config.successThreshold));
      });

      test('creates copy with updated openDuration', () {
        const config = CircuitBreakerConfig();
        final copy = config.copyWith(openDuration: const Duration(minutes: 2));
        expect(copy.openDuration, equals(const Duration(minutes: 2)));
        expect(copy.failureThreshold, equals(config.failureThreshold));
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = CircuitBreakerConfig();
        const config2 = CircuitBreakerConfig();
        expect(config1, equals(config2));
      });

      test('different configs are not equal', () {
        const config1 = CircuitBreakerConfig(failureThreshold: 5);
        const config2 = CircuitBreakerConfig(failureThreshold: 10);
        expect(config1, isNot(equals(config2)));
      });

      test('same hashCode for equal configs', () {
        const config1 = CircuitBreakerConfig();
        const config2 = CircuitBreakerConfig();
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });
}
