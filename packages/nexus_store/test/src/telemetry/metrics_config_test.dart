import 'package:nexus_store/src/telemetry/metrics_config.dart';
import 'package:test/test.dart';

void main() {
  group('MetricsConfig', () {
    group('construction', () {
      test('should create with default values', () {
        const config = MetricsConfig();

        expect(config.sampleRate, equals(1.0));
        expect(config.bufferSize, equals(100));
        expect(config.flushInterval, equals(const Duration(seconds: 30)));
        expect(config.includeStackTraces, isTrue);
        expect(config.trackTiming, isTrue);
      });

      test('should accept custom sampleRate', () {
        const config = MetricsConfig(sampleRate: 0.5);

        expect(config.sampleRate, equals(0.5));
      });

      test('should accept custom bufferSize', () {
        const config = MetricsConfig(bufferSize: 50);

        expect(config.bufferSize, equals(50));
      });

      test('should accept custom flushInterval', () {
        const config = MetricsConfig(
          flushInterval: Duration(minutes: 1),
        );

        expect(config.flushInterval, equals(const Duration(minutes: 1)));
      });

      test('should accept custom includeStackTraces', () {
        const config = MetricsConfig(includeStackTraces: false);

        expect(config.includeStackTraces, isFalse);
      });

      test('should accept custom trackTiming', () {
        const config = MetricsConfig(trackTiming: false);

        expect(config.trackTiming, isFalse);
      });

      test('should accept all custom values', () {
        const config = MetricsConfig(
          sampleRate: 0.25,
          bufferSize: 200,
          flushInterval: Duration(minutes: 5),
          includeStackTraces: false,
          trackTiming: false,
        );

        expect(config.sampleRate, equals(0.25));
        expect(config.bufferSize, equals(200));
        expect(config.flushInterval, equals(const Duration(minutes: 5)));
        expect(config.includeStackTraces, isFalse);
        expect(config.trackTiming, isFalse);
      });
    });

    group('preset configurations', () {
      test('defaults should have full sampling', () {
        const config = MetricsConfig.defaults;

        expect(config.sampleRate, equals(1.0));
        expect(config.trackTiming, isTrue);
        expect(config.includeStackTraces, isTrue);
      });

      test('minimal should have low sampling and no stack traces', () {
        const config = MetricsConfig.minimal;

        expect(config.sampleRate, equals(0.1));
        expect(config.includeStackTraces, isFalse);
      });

      test('disabled should have zero sampling', () {
        const config = MetricsConfig.disabled;

        expect(config.sampleRate, equals(0.0));
        expect(config.trackTiming, isFalse);
      });
    });

    group('sampleRate validation', () {
      test('should accept 0.0 sample rate', () {
        const config = MetricsConfig(sampleRate: 0.0);

        expect(config.sampleRate, equals(0.0));
      });

      test('should accept 1.0 sample rate', () {
        const config = MetricsConfig(sampleRate: 1.0);

        expect(config.sampleRate, equals(1.0));
      });

      test('should accept fractional sample rate', () {
        const config = MetricsConfig(sampleRate: 0.33);

        expect(config.sampleRate, equals(0.33));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        const config1 = MetricsConfig(
          sampleRate: 0.5,
          bufferSize: 50,
        );

        const config2 = MetricsConfig(
          sampleRate: 0.5,
          bufferSize: 50,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should not be equal with different sampleRate', () {
        const config1 = MetricsConfig(sampleRate: 0.5);
        const config2 = MetricsConfig(sampleRate: 0.75);

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal with different bufferSize', () {
        const config1 = MetricsConfig(bufferSize: 50);
        const config2 = MetricsConfig(bufferSize: 100);

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal with different flushInterval', () {
        const config1 = MetricsConfig(flushInterval: Duration(seconds: 30));
        const config2 = MetricsConfig(flushInterval: Duration(minutes: 1));

        expect(config1, isNot(equals(config2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified sampleRate', () {
        const original = MetricsConfig(sampleRate: 1.0);

        final copy = original.copyWith(sampleRate: 0.5);

        expect(copy.sampleRate, equals(0.5));
        expect(copy.bufferSize, equals(original.bufferSize));
      });

      test('should create copy with modified bufferSize', () {
        const original = MetricsConfig(bufferSize: 100);

        final copy = original.copyWith(bufferSize: 200);

        expect(copy.bufferSize, equals(200));
      });

      test('should create copy with modified flushInterval', () {
        const original = MetricsConfig(
          flushInterval: Duration(seconds: 30),
        );

        final copy = original.copyWith(
          flushInterval: const Duration(minutes: 2),
        );

        expect(copy.flushInterval, equals(const Duration(minutes: 2)));
      });

      test('should preserve original when copying', () {
        const original = MetricsConfig(sampleRate: 1.0);

        original.copyWith(sampleRate: 0.5);

        expect(original.sampleRate, equals(1.0));
      });
    });

    group('computed properties', () {
      test('isEnabled should be true when sampleRate > 0', () {
        const config = MetricsConfig(sampleRate: 0.5);

        expect(config.isEnabled, isTrue);
      });

      test('isEnabled should be false when sampleRate is 0', () {
        const config = MetricsConfig(sampleRate: 0.0);

        expect(config.isEnabled, isFalse);
      });

      test('isFullSampling should be true when sampleRate is 1.0', () {
        const config = MetricsConfig(sampleRate: 1.0);

        expect(config.isFullSampling, isTrue);
      });

      test('isFullSampling should be false when sampleRate < 1.0', () {
        const config = MetricsConfig(sampleRate: 0.99);

        expect(config.isFullSampling, isFalse);
      });
    });

    group('toString', () {
      test('should include sampleRate', () {
        const config = MetricsConfig(sampleRate: 0.5);

        expect(config.toString(), contains('0.5'));
      });

      test('should include bufferSize', () {
        const config = MetricsConfig(bufferSize: 150);

        expect(config.toString(), contains('150'));
      });
    });
  });
}
