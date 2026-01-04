import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_config.dart';

void main() {
  group('BackgroundSyncConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = BackgroundSyncConfig();

        expect(config.enabled, isTrue);
        expect(config.minInterval, equals(const Duration(minutes: 15)));
        expect(config.requiresNetwork, isTrue);
        expect(config.requiresCharging, isFalse);
        expect(config.requiresBatteryNotLow, isTrue);
      });

      test('accepts custom enabled value', () {
        const config = BackgroundSyncConfig(enabled: false);

        expect(config.enabled, isFalse);
      });

      test('accepts custom minInterval', () {
        const config = BackgroundSyncConfig(
          minInterval: Duration(hours: 1),
        );

        expect(config.minInterval, equals(const Duration(hours: 1)));
      });

      test('accepts custom requiresNetwork value', () {
        const config = BackgroundSyncConfig(requiresNetwork: false);

        expect(config.requiresNetwork, isFalse);
      });

      test('accepts custom requiresCharging value', () {
        const config = BackgroundSyncConfig(requiresCharging: true);

        expect(config.requiresCharging, isTrue);
      });

      test('accepts custom requiresBatteryNotLow value', () {
        const config = BackgroundSyncConfig(requiresBatteryNotLow: false);

        expect(config.requiresBatteryNotLow, isFalse);
      });

      test('accepts all custom values', () {
        const config = BackgroundSyncConfig(
          enabled: false,
          minInterval: Duration(minutes: 30),
          requiresNetwork: false,
          requiresCharging: true,
          requiresBatteryNotLow: false,
        );

        expect(config.enabled, isFalse);
        expect(config.minInterval, equals(const Duration(minutes: 30)));
        expect(config.requiresNetwork, isFalse);
        expect(config.requiresCharging, isTrue);
        expect(config.requiresBatteryNotLow, isFalse);
      });
    });

    group('copyWith', () {
      test('returns identical config when no arguments provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith();

        expect(copy.enabled, equals(original.enabled));
        expect(copy.minInterval, equals(original.minInterval));
        expect(copy.requiresNetwork, equals(original.requiresNetwork));
        expect(copy.requiresCharging, equals(original.requiresCharging));
        expect(
          copy.requiresBatteryNotLow,
          equals(original.requiresBatteryNotLow),
        );
      });

      test('updates enabled when provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith(enabled: false);

        expect(copy.enabled, isFalse);
        expect(copy.minInterval, equals(original.minInterval));
      });

      test('updates minInterval when provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith(minInterval: const Duration(hours: 2));

        expect(copy.minInterval, equals(const Duration(hours: 2)));
        expect(copy.enabled, equals(original.enabled));
      });

      test('updates requiresNetwork when provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith(requiresNetwork: false);

        expect(copy.requiresNetwork, isFalse);
      });

      test('updates requiresCharging when provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith(requiresCharging: true);

        expect(copy.requiresCharging, isTrue);
      });

      test('updates requiresBatteryNotLow when provided', () {
        const original = BackgroundSyncConfig();
        final copy = original.copyWith(requiresBatteryNotLow: false);

        expect(copy.requiresBatteryNotLow, isFalse);
      });
    });

    group('equality', () {
      test('two configs with same values are equal', () {
        const config1 = BackgroundSyncConfig();
        const config2 = BackgroundSyncConfig();

        expect(config1, equals(config2));
      });

      test('two configs with different values are not equal', () {
        const config1 = BackgroundSyncConfig();
        const config2 = BackgroundSyncConfig(enabled: false);

        expect(config1, isNot(equals(config2)));
      });

      test('hashCode is consistent for equal objects', () {
        const config1 = BackgroundSyncConfig();
        const config2 = BackgroundSyncConfig();

        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    group('toString', () {
      test('returns meaningful string representation', () {
        const config = BackgroundSyncConfig();
        final str = config.toString();

        expect(str, contains('BackgroundSyncConfig'));
        expect(str, contains('enabled'));
        expect(str, contains('minInterval'));
      });
    });

    group('presets', () {
      test('disabled preset has enabled set to false', () {
        const config = BackgroundSyncConfig.disabled();

        expect(config.enabled, isFalse);
      });

      test('conservative preset requires charging and battery', () {
        const config = BackgroundSyncConfig.conservative();

        expect(config.enabled, isTrue);
        expect(config.minInterval, equals(const Duration(hours: 1)));
        expect(config.requiresNetwork, isTrue);
        expect(config.requiresCharging, isTrue);
        expect(config.requiresBatteryNotLow, isTrue);
      });

      test('aggressive preset has shorter interval and fewer constraints', () {
        const config = BackgroundSyncConfig.aggressive();

        expect(config.enabled, isTrue);
        expect(config.minInterval, equals(const Duration(minutes: 15)));
        expect(config.requiresNetwork, isTrue);
        expect(config.requiresCharging, isFalse);
        expect(config.requiresBatteryNotLow, isFalse);
      });
    });
  });
}
