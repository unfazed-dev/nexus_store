import 'dart:math';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('RetryConfig', () {
    group('default constructor', () {
      test('should have 3 as default maxAttempts', () {
        const config = RetryConfig();
        expect(config.maxAttempts, equals(3));
      });

      test('should have 1 second as default initialDelay', () {
        const config = RetryConfig();
        expect(config.initialDelay, equals(const Duration(seconds: 1)));
      });

      test('should have 30 seconds as default maxDelay', () {
        const config = RetryConfig();
        expect(config.maxDelay, equals(const Duration(seconds: 30)));
      });

      test('should have 2.0 as default backoffMultiplier', () {
        const config = RetryConfig();
        expect(config.backoffMultiplier, equals(2.0));
      });

      test('should have 0.1 as default jitterFactor', () {
        const config = RetryConfig();
        expect(config.jitterFactor, equals(0.1));
      });

      test('should have empty retryableExceptions by default', () {
        const config = RetryConfig();
        expect(config.retryableExceptions, isEmpty);
      });
    });

    group('defaults preset', () {
      test('should match default constructor', () {
        expect(RetryConfig.defaults, equals(const RetryConfig()));
      });
    });

    group('noRetry preset', () {
      test('should have maxAttempts of 1', () {
        expect(RetryConfig.noRetry.maxAttempts, equals(1));
      });
    });

    group('aggressive preset', () {
      test('should have maxAttempts of 5', () {
        expect(RetryConfig.aggressive.maxAttempts, equals(5));
      });

      test('should have initialDelay of 500ms', () {
        expect(
          RetryConfig.aggressive.initialDelay,
          equals(const Duration(milliseconds: 500)),
        );
      });

      test('should have maxDelay of 1 minute', () {
        expect(
          RetryConfig.aggressive.maxDelay,
          equals(const Duration(minutes: 1)),
        );
      });

      test('should have backoffMultiplier of 1.5', () {
        expect(RetryConfig.aggressive.backoffMultiplier, equals(1.5));
      });

      test('should have jitterFactor of 0.2', () {
        expect(RetryConfig.aggressive.jitterFactor, equals(0.2));
      });
    });

    group('delayForAttempt', () {
      test('should return initialDelay for first attempt with no jitter', () {
        const config = RetryConfig(jitterFactor: 0);
        final delay = config.delayForAttempt(1);

        expect(delay, equals(const Duration(seconds: 1)));
      });

      test('should apply exponential backoff for subsequent attempts', () {
        const config = RetryConfig(jitterFactor: 0);

        expect(config.delayForAttempt(1), equals(const Duration(seconds: 1)));
        expect(config.delayForAttempt(2), equals(const Duration(seconds: 2)));
        expect(config.delayForAttempt(3), equals(const Duration(seconds: 4)));
        expect(config.delayForAttempt(4), equals(const Duration(seconds: 8)));
      });

      test('should cap delay at maxDelay', () {
        const config = RetryConfig(
          maxDelay: Duration(seconds: 5),
          jitterFactor: 0,
        );

        // Attempt 4 would be 8 seconds, but capped at 5
        expect(config.delayForAttempt(4), equals(const Duration(seconds: 5)));
      });

      test('should apply jitter to delay', () {
        const config = RetryConfig();

        // Use a fixed random seed for deterministic testing
        final random = Random(42);
        final delay1 = config.delayForAttempt(1, random: random);
        final delay2 = config.delayForAttempt(1, random: random);

        // Delays should be close to 1000ms but with jitter
        expect(delay1.inMilliseconds, greaterThanOrEqualTo(900));
        expect(delay1.inMilliseconds, lessThanOrEqualTo(1100));

        // Different random values should give different delays
        expect(delay1, isNot(equals(delay2)));
      });

      test('should work with custom backoffMultiplier', () {
        const config = RetryConfig(
          initialDelay: Duration(milliseconds: 100),
          backoffMultiplier: 3,
          jitterFactor: 0,
        );

        expect(
          config.delayForAttempt(1),
          equals(const Duration(milliseconds: 100)),
        );
        expect(
          config.delayForAttempt(2),
          equals(const Duration(milliseconds: 300)),
        );
        expect(
          config.delayForAttempt(3),
          equals(const Duration(milliseconds: 900)),
        );
      });
    });

    group('shouldRetry', () {
      test(
          'should return true for any exception when retryableExceptions is '
          'empty', () {
        const config = RetryConfig();

        expect(config.shouldRetry(Exception('test')), isTrue);
        expect(config.shouldRetry(const FormatException('test')), isTrue);
        expect(config.shouldRetry(ArgumentError('test')), isTrue);
      });

      test('should return true only for specified exception types', () {
        const config = RetryConfig(
          retryableExceptions: {FormatException, ArgumentError},
        );

        expect(config.shouldRetry(const FormatException('test')), isTrue);
        expect(config.shouldRetry(ArgumentError('test')), isTrue);
        expect(config.shouldRetry(Exception('test')), isFalse);
      });
    });

    group('copyWith', () {
      test('should create new instance with changed maxAttempts', () {
        const original = RetryConfig();
        final modified = original.copyWith(maxAttempts: 5);

        expect(modified.maxAttempts, equals(5));
        expect(original.maxAttempts, equals(3));
      });

      test('should create new instance with changed initialDelay', () {
        const original = RetryConfig();
        final modified = original.copyWith(
          initialDelay: const Duration(milliseconds: 500),
        );

        expect(
          modified.initialDelay,
          equals(const Duration(milliseconds: 500)),
        );
        expect(original.initialDelay, equals(const Duration(seconds: 1)));
      });

      test('should create new instance with changed backoffMultiplier', () {
        const original = RetryConfig();
        final modified = original.copyWith(backoffMultiplier: 3);

        expect(modified.backoffMultiplier, equals(3.0));
        expect(original.backoffMultiplier, equals(2.0));
      });

      test('should preserve unchanged values', () {
        const original = RetryConfig(
          maxAttempts: 5,
          jitterFactor: 0.2,
        );
        final modified = original.copyWith(initialDelay: Duration.zero);

        expect(modified.maxAttempts, equals(5));
        expect(modified.jitterFactor, equals(0.2));
        expect(modified.initialDelay, equals(Duration.zero));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        const config1 = RetryConfig();
        const config2 = RetryConfig();

        expect(config1, equals(config2));
      });

      test('should not be equal when maxAttempts differs', () {
        const config1 = RetryConfig();
        const config2 = RetryConfig(maxAttempts: 5);

        expect(config1, isNot(equals(config2)));
      });

      test('should have same hashCode for equal configs', () {
        const config1 = RetryConfig();
        const config2 = RetryConfig();

        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        const config = RetryConfig();
        final str = config.toString();

        expect(str, contains('RetryConfig'));
        expect(str, contains('maxAttempts: 3'));
        expect(str, contains('initialDelay'));
        expect(str, contains('backoffMultiplier: 2.0'));
      });
    });

    group('assertions', () {
      test('should throw when maxAttempts is less than 1', () {
        expect(
          () => RetryConfig(maxAttempts: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw when backoffMultiplier is less than 1.0', () {
        expect(
          () => RetryConfig(backoffMultiplier: 0.5),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw when jitterFactor is negative', () {
        expect(
          () => RetryConfig(jitterFactor: -0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw when jitterFactor is greater than 1.0', () {
        expect(
          () => RetryConfig(jitterFactor: 1.5),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
