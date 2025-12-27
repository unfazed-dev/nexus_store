import 'package:nexus_store/src/pool/connection_pool_config.dart';
import 'package:test/test.dart';

void main() {
  group('ConnectionPoolConfig', () {
    group('default values', () {
      test('should have minConnections of 1', () {
        const config = ConnectionPoolConfig();
        expect(config.minConnections, equals(1));
      });

      test('should have maxConnections of 10', () {
        const config = ConnectionPoolConfig();
        expect(config.maxConnections, equals(10));
      });

      test('should have acquireTimeout of 30 seconds', () {
        const config = ConnectionPoolConfig();
        expect(config.acquireTimeout, equals(const Duration(seconds: 30)));
      });

      test('should have idleTimeout of 10 minutes', () {
        const config = ConnectionPoolConfig();
        expect(config.idleTimeout, equals(const Duration(minutes: 10)));
      });

      test('should have maxLifetime of 1 hour', () {
        const config = ConnectionPoolConfig();
        expect(config.maxLifetime, equals(const Duration(hours: 1)));
      });

      test('should have healthCheckInterval of 1 minute', () {
        const config = ConnectionPoolConfig();
        expect(config.healthCheckInterval, equals(const Duration(minutes: 1)));
      });

      test('should have testOnBorrow as true', () {
        const config = ConnectionPoolConfig();
        expect(config.testOnBorrow, isTrue);
      });

      test('should have testOnReturn as false', () {
        const config = ConnectionPoolConfig();
        expect(config.testOnReturn, isFalse);
      });
    });

    group('custom values', () {
      test('should accept custom minConnections', () {
        const config = ConnectionPoolConfig(minConnections: 5);
        expect(config.minConnections, equals(5));
      });

      test('should accept custom maxConnections', () {
        const config = ConnectionPoolConfig(maxConnections: 50);
        expect(config.maxConnections, equals(50));
      });

      test('should accept custom acquireTimeout', () {
        const config = ConnectionPoolConfig(
          acquireTimeout: Duration(seconds: 60),
        );
        expect(config.acquireTimeout, equals(const Duration(seconds: 60)));
      });

      test('should accept custom idleTimeout', () {
        const config = ConnectionPoolConfig(
          idleTimeout: Duration(minutes: 5),
        );
        expect(config.idleTimeout, equals(const Duration(minutes: 5)));
      });

      test('should accept custom maxLifetime', () {
        const config = ConnectionPoolConfig(
          maxLifetime: Duration(hours: 2),
        );
        expect(config.maxLifetime, equals(const Duration(hours: 2)));
      });

      test('should accept custom healthCheckInterval', () {
        const config = ConnectionPoolConfig(
          healthCheckInterval: Duration(seconds: 30),
        );
        expect(
          config.healthCheckInterval,
          equals(const Duration(seconds: 30)),
        );
      });

      test('should accept testOnBorrow as false', () {
        const config = ConnectionPoolConfig(testOnBorrow: false);
        expect(config.testOnBorrow, isFalse);
      });

      test('should accept testOnReturn as true', () {
        const config = ConnectionPoolConfig(testOnReturn: true);
        expect(config.testOnReturn, isTrue);
      });
    });

    group('presets', () {
      test('defaults should have standard values', () {
        const config = ConnectionPoolConfig.defaults;
        expect(config.minConnections, equals(1));
        expect(config.maxConnections, equals(10));
        expect(config.acquireTimeout, equals(const Duration(seconds: 30)));
      });

      test('highPerformance should have more connections', () {
        const config = ConnectionPoolConfig.highPerformance;
        expect(config.minConnections, equals(5));
        expect(config.maxConnections, equals(50));
        expect(config.idleTimeout, equals(const Duration(minutes: 5)));
      });
    });

    group('validation', () {
      test('isValid should return true for valid config', () {
        const config = ConnectionPoolConfig();
        expect(config.isValid, isTrue);
      });

      test('isValid should return true when minConnections equals maxConnections', () {
        const config = ConnectionPoolConfig(
          minConnections: 5,
          maxConnections: 5,
        );
        expect(config.isValid, isTrue);
      });

      test('isValid should return false when minConnections > maxConnections', () {
        const config = ConnectionPoolConfig(
          minConnections: 20,
          maxConnections: 10,
        );
        expect(config.isValid, isFalse);
      });

      test('isValid should return false when minConnections is negative', () {
        const config = ConnectionPoolConfig(minConnections: -1);
        expect(config.isValid, isFalse);
      });

      test('isValid should return false when acquireTimeout is zero', () {
        const config = ConnectionPoolConfig(acquireTimeout: Duration.zero);
        expect(config.isValid, isFalse);
      });

      test('isValid should return false when acquireTimeout is negative', () {
        const config = ConnectionPoolConfig(
          acquireTimeout: Duration(seconds: -1),
        );
        expect(config.isValid, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with modified minConnections', () {
        const original = ConnectionPoolConfig();
        final copy = original.copyWith(minConnections: 3);
        expect(copy.minConnections, equals(3));
        expect(copy.maxConnections, equals(original.maxConnections));
      });

      test('should create copy with modified maxConnections', () {
        const original = ConnectionPoolConfig();
        final copy = original.copyWith(maxConnections: 20);
        expect(copy.maxConnections, equals(20));
        expect(copy.minConnections, equals(original.minConnections));
      });

      test('should create copy with multiple modified fields', () {
        const original = ConnectionPoolConfig();
        final copy = original.copyWith(
          minConnections: 2,
          maxConnections: 25,
          testOnBorrow: false,
        );
        expect(copy.minConnections, equals(2));
        expect(copy.maxConnections, equals(25));
        expect(copy.testOnBorrow, isFalse);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const config1 = ConnectionPoolConfig();
        const config2 = ConnectionPoolConfig();
        expect(config1, equals(config2));
      });

      test('should not be equal for different values', () {
        const config1 = ConnectionPoolConfig(minConnections: 1);
        const config2 = ConnectionPoolConfig(minConnections: 2);
        expect(config1, isNot(equals(config2)));
      });

      test('should have same hashCode for equal configs', () {
        const config1 = ConnectionPoolConfig();
        const config2 = ConnectionPoolConfig();
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });
}
