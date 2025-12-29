import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/health_check_config.dart';

void main() {
  group('HealthCheckConfig', () {
    group('defaults', () {
      test('has checkInterval of 30 seconds', () {
        const config = HealthCheckConfig();
        expect(config.checkInterval, equals(const Duration(seconds: 30)));
      });

      test('has timeout of 10 seconds', () {
        const config = HealthCheckConfig();
        expect(config.timeout, equals(const Duration(seconds: 10)));
      });

      test('has failureThreshold of 3', () {
        const config = HealthCheckConfig();
        expect(config.failureThreshold, equals(3));
      });

      test('has recoveryThreshold of 2', () {
        const config = HealthCheckConfig();
        expect(config.recoveryThreshold, equals(2));
      });

      test('is enabled by default', () {
        const config = HealthCheckConfig();
        expect(config.enabled, isTrue);
      });

      test('has autoStart true by default', () {
        const config = HealthCheckConfig();
        expect(config.autoStart, isTrue);
      });
    });

    group('presets', () {
      group('defaults preset', () {
        test('matches default constructor values', () {
          expect(
            HealthCheckConfig.defaults,
            equals(const HealthCheckConfig()),
          );
        });
      });

      group('frequent preset', () {
        test('has checkInterval of 10 seconds', () {
          expect(
            HealthCheckConfig.frequent.checkInterval,
            equals(const Duration(seconds: 10)),
          );
        });

        test('has timeout of 5 seconds', () {
          expect(
            HealthCheckConfig.frequent.timeout,
            equals(const Duration(seconds: 5)),
          );
        });
      });

      group('infrequent preset', () {
        test('has checkInterval of 5 minutes', () {
          expect(
            HealthCheckConfig.infrequent.checkInterval,
            equals(const Duration(minutes: 5)),
          );
        });

        test('has timeout of 30 seconds', () {
          expect(
            HealthCheckConfig.infrequent.timeout,
            equals(const Duration(seconds: 30)),
          );
        });
      });

      group('disabled preset', () {
        test('has enabled set to false', () {
          expect(HealthCheckConfig.disabled.enabled, isFalse);
        });
      });
    });

    group('custom values', () {
      test('can create with custom checkInterval', () {
        const config = HealthCheckConfig(
          checkInterval: Duration(minutes: 1),
        );
        expect(config.checkInterval, equals(const Duration(minutes: 1)));
      });

      test('can create with custom timeout', () {
        const config = HealthCheckConfig(
          timeout: Duration(seconds: 5),
        );
        expect(config.timeout, equals(const Duration(seconds: 5)));
      });

      test('can create with custom thresholds', () {
        const config = HealthCheckConfig(
          failureThreshold: 5,
          recoveryThreshold: 3,
        );
        expect(config.failureThreshold, equals(5));
        expect(config.recoveryThreshold, equals(3));
      });

      test('can create with all custom values', () {
        const config = HealthCheckConfig(
          checkInterval: Duration(seconds: 15),
          timeout: Duration(seconds: 3),
          failureThreshold: 2,
          recoveryThreshold: 1,
          enabled: false,
          autoStart: false,
        );
        expect(config.checkInterval, equals(const Duration(seconds: 15)));
        expect(config.timeout, equals(const Duration(seconds: 3)));
        expect(config.failureThreshold, equals(2));
        expect(config.recoveryThreshold, equals(1));
        expect(config.enabled, isFalse);
        expect(config.autoStart, isFalse);
      });
    });

    group('isValid', () {
      test('returns true for default config', () {
        const config = HealthCheckConfig();
        expect(config.isValid, isTrue);
      });

      test('returns false when checkInterval is zero', () {
        const config = HealthCheckConfig(checkInterval: Duration.zero);
        expect(config.isValid, isFalse);
      });

      test('returns false when timeout is zero', () {
        const config = HealthCheckConfig(timeout: Duration.zero);
        expect(config.isValid, isFalse);
      });

      test('returns false when failureThreshold is zero', () {
        const config = HealthCheckConfig(failureThreshold: 0);
        expect(config.isValid, isFalse);
      });

      test('returns false when recoveryThreshold is zero', () {
        const config = HealthCheckConfig(recoveryThreshold: 0);
        expect(config.isValid, isFalse);
      });

      test('returns false when timeout exceeds checkInterval', () {
        const config = HealthCheckConfig(
          checkInterval: Duration(seconds: 5),
          timeout: Duration(seconds: 10),
        );
        expect(config.isValid, isFalse);
      });

      test('returns true when timeout equals checkInterval', () {
        const config = HealthCheckConfig(
          checkInterval: Duration(seconds: 10),
          timeout: Duration(seconds: 10),
        );
        expect(config.isValid, isTrue);
      });
    });

    group('copyWith', () {
      test('can update checkInterval', () {
        const original = HealthCheckConfig();
        final updated = original.copyWith(
          checkInterval: const Duration(minutes: 2),
        );
        expect(updated.checkInterval, equals(const Duration(minutes: 2)));
        expect(updated.timeout, equals(original.timeout));
      });

      test('can update multiple values', () {
        const original = HealthCheckConfig();
        final updated = original.copyWith(
          checkInterval: const Duration(seconds: 20),
          timeout: const Duration(seconds: 5),
          enabled: false,
        );
        expect(updated.checkInterval, equals(const Duration(seconds: 20)));
        expect(updated.timeout, equals(const Duration(seconds: 5)));
        expect(updated.enabled, isFalse);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = HealthCheckConfig(
          checkInterval: Duration(seconds: 30),
          failureThreshold: 3,
        );
        const config2 = HealthCheckConfig(
          checkInterval: Duration(seconds: 30),
          failureThreshold: 3,
        );
        expect(config1, equals(config2));
      });

      test('different configs are not equal', () {
        const config1 = HealthCheckConfig(failureThreshold: 3);
        const config2 = HealthCheckConfig(failureThreshold: 5);
        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
