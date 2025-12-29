import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/degradation_config.dart';
import 'package:nexus_store/src/reliability/degradation_mode.dart';

void main() {
  group('DegradationConfig', () {
    group('defaults', () {
      test('is enabled by default', () {
        const config = DegradationConfig();
        expect(config.enabled, isTrue);
      });

      test('has autoDegradation enabled by default', () {
        const config = DegradationConfig();
        expect(config.autoDegradation, isTrue);
      });

      test('has normal default mode', () {
        const config = DegradationConfig();
        expect(config.defaultMode, equals(DegradationMode.normal));
      });

      test('has fallback mode of cacheOnly', () {
        const config = DegradationConfig();
        expect(config.fallbackMode, equals(DegradationMode.cacheOnly));
      });

      test('has cooldown of 60 seconds', () {
        const config = DegradationConfig();
        expect(config.cooldown, equals(const Duration(seconds: 60)));
      });
    });

    group('presets', () {
      group('defaults preset', () {
        test('matches default constructor', () {
          expect(
            DegradationConfig.defaults,
            equals(const DegradationConfig()),
          );
        });
      });

      group('aggressive preset', () {
        test('has short cooldown', () {
          expect(
            DegradationConfig.aggressive.cooldown,
            equals(const Duration(seconds: 30)),
          );
        });

        test('has readOnly fallback', () {
          expect(
            DegradationConfig.aggressive.fallbackMode,
            equals(DegradationMode.readOnly),
          );
        });
      });

      group('conservative preset', () {
        test('has long cooldown', () {
          expect(
            DegradationConfig.conservative.cooldown,
            equals(const Duration(minutes: 5)),
          );
        });

        test('has cacheOnly fallback', () {
          expect(
            DegradationConfig.conservative.fallbackMode,
            equals(DegradationMode.cacheOnly),
          );
        });
      });

      group('disabled preset', () {
        test('has enabled set to false', () {
          expect(DegradationConfig.disabled.enabled, isFalse);
        });

        test('has autoDegradation disabled', () {
          expect(DegradationConfig.disabled.autoDegradation, isFalse);
        });
      });
    });

    group('custom values', () {
      test('can create with custom mode', () {
        const config = DegradationConfig(
          defaultMode: DegradationMode.cacheOnly,
        );
        expect(config.defaultMode, equals(DegradationMode.cacheOnly));
      });

      test('can create with custom fallback mode', () {
        const config = DegradationConfig(
          fallbackMode: DegradationMode.offline,
        );
        expect(config.fallbackMode, equals(DegradationMode.offline));
      });

      test('can create with custom cooldown', () {
        const config = DegradationConfig(
          cooldown: Duration(minutes: 2),
        );
        expect(config.cooldown, equals(const Duration(minutes: 2)));
      });

      test('can create with all custom values', () {
        const config = DegradationConfig(
          enabled: false,
          autoDegradation: false,
          defaultMode: DegradationMode.readOnly,
          fallbackMode: DegradationMode.offline,
          cooldown: Duration(seconds: 45),
        );
        expect(config.enabled, isFalse);
        expect(config.autoDegradation, isFalse);
        expect(config.defaultMode, equals(DegradationMode.readOnly));
        expect(config.fallbackMode, equals(DegradationMode.offline));
        expect(config.cooldown, equals(const Duration(seconds: 45)));
      });
    });

    group('copyWith', () {
      test('can update enabled', () {
        const original = DegradationConfig();
        final updated = original.copyWith(enabled: false);
        expect(updated.enabled, isFalse);
        expect(updated.autoDegradation, equals(original.autoDegradation));
      });

      test('can update multiple values', () {
        const original = DegradationConfig();
        final updated = original.copyWith(
          fallbackMode: DegradationMode.offline,
          cooldown: const Duration(seconds: 30),
        );
        expect(updated.fallbackMode, equals(DegradationMode.offline));
        expect(updated.cooldown, equals(const Duration(seconds: 30)));
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = DegradationConfig(
          cooldown: Duration(seconds: 45),
        );
        const config2 = DegradationConfig(
          cooldown: Duration(seconds: 45),
        );
        expect(config1, equals(config2));
      });

      test('different configs are not equal', () {
        const config1 = DegradationConfig(
          cooldown: Duration(seconds: 45),
        );
        const config2 = DegradationConfig(
          cooldown: Duration(seconds: 60),
        );
        expect(config1, isNot(equals(config2)));
      });
    });
  });

  group('DegradationMetrics', () {
    group('factory', () {
      test('creates with required values', () {
        final metrics = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
        );
        expect(metrics.mode, equals(DegradationMode.normal));
      });

      test('creates with default counts of 0', () {
        final metrics = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
        );
        expect(metrics.degradationCount, equals(0));
        expect(metrics.recoveryCount, equals(0));
      });
    });

    group('initial', () {
      test('creates initial metrics', () {
        final metrics = DegradationMetrics.initial();
        expect(metrics.mode, equals(DegradationMode.normal));
        expect(metrics.degradationCount, equals(0));
        expect(metrics.recoveryCount, equals(0));
      });
    });

    group('isDegraded', () {
      test('returns false for normal mode', () {
        final metrics = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
        );
        expect(metrics.isDegraded, isFalse);
      });

      test('returns true for degraded modes', () {
        final metrics = DegradationMetrics(
          mode: DegradationMode.cacheOnly,
          timestamp: DateTime.now(),
        );
        expect(metrics.isDegraded, isTrue);
      });
    });

    group('timeSinceLastChange', () {
      test('returns null when lastModeChange is null', () {
        final metrics = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
        );
        expect(metrics.timeSinceLastChange, isNull);
      });

      test('returns duration when lastModeChange is set', () {
        final now = DateTime.now();
        final metrics = DegradationMetrics(
          mode: DegradationMode.cacheOnly,
          timestamp: now,
          lastModeChange: now.subtract(const Duration(seconds: 30)),
        );
        final duration = metrics.timeSinceLastChange;
        expect(duration, isNotNull);
        expect(duration!.inSeconds, greaterThanOrEqualTo(30));
      });
    });

    group('copyWith', () {
      test('can update mode', () {
        final original = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
        );
        final updated = original.copyWith(
          mode: DegradationMode.cacheOnly,
        );
        expect(updated.mode, equals(DegradationMode.cacheOnly));
      });

      test('can increment degradation count', () {
        final original = DegradationMetrics(
          mode: DegradationMode.normal,
          timestamp: DateTime.now(),
          degradationCount: 5,
        );
        final updated = original.copyWith(
          degradationCount: 6,
        );
        expect(updated.degradationCount, equals(6));
      });
    });
  });
}
