import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/health_status.dart';

void main() {
  group('HealthStatus', () {
    group('values', () {
      test('has healthy status', () {
        expect(HealthStatus.healthy, isNotNull);
      });

      test('has degraded status', () {
        expect(HealthStatus.degraded, isNotNull);
      });

      test('has unhealthy status', () {
        expect(HealthStatus.unhealthy, isNotNull);
      });

      test('has exactly 3 values', () {
        expect(HealthStatus.values.length, equals(3));
      });
    });

    group('isHealthy', () {
      test('returns true for healthy', () {
        expect(HealthStatus.healthy.isHealthy, isTrue);
      });

      test('returns false for degraded', () {
        expect(HealthStatus.degraded.isHealthy, isFalse);
      });

      test('returns false for unhealthy', () {
        expect(HealthStatus.unhealthy.isHealthy, isFalse);
      });
    });

    group('isDegraded', () {
      test('returns false for healthy', () {
        expect(HealthStatus.healthy.isDegraded, isFalse);
      });

      test('returns true for degraded', () {
        expect(HealthStatus.degraded.isDegraded, isTrue);
      });

      test('returns false for unhealthy', () {
        expect(HealthStatus.unhealthy.isDegraded, isFalse);
      });
    });

    group('isUnhealthy', () {
      test('returns false for healthy', () {
        expect(HealthStatus.healthy.isUnhealthy, isFalse);
      });

      test('returns false for degraded', () {
        expect(HealthStatus.degraded.isUnhealthy, isFalse);
      });

      test('returns true for unhealthy', () {
        expect(HealthStatus.unhealthy.isUnhealthy, isTrue);
      });
    });

    group('isWorseThan', () {
      test('healthy is not worse than healthy', () {
        expect(HealthStatus.healthy.isWorseThan(HealthStatus.healthy), isFalse);
      });

      test('degraded is worse than healthy', () {
        expect(HealthStatus.degraded.isWorseThan(HealthStatus.healthy), isTrue);
      });

      test('unhealthy is worse than healthy', () {
        expect(
            HealthStatus.unhealthy.isWorseThan(HealthStatus.healthy), isTrue);
      });

      test('unhealthy is worse than degraded', () {
        expect(
            HealthStatus.unhealthy.isWorseThan(HealthStatus.degraded), isTrue);
      });

      test('healthy is not worse than unhealthy', () {
        expect(
            HealthStatus.healthy.isWorseThan(HealthStatus.unhealthy), isFalse);
      });
    });

    group('worst', () {
      test('returns unhealthy when comparing healthy and unhealthy', () {
        expect(
          HealthStatus.worst([HealthStatus.healthy, HealthStatus.unhealthy]),
          equals(HealthStatus.unhealthy),
        );
      });

      test('returns degraded when comparing healthy and degraded', () {
        expect(
          HealthStatus.worst([HealthStatus.healthy, HealthStatus.degraded]),
          equals(HealthStatus.degraded),
        );
      });

      test('returns healthy when all healthy', () {
        expect(
          HealthStatus.worst([HealthStatus.healthy, HealthStatus.healthy]),
          equals(HealthStatus.healthy),
        );
      });

      test('returns healthy for empty list', () {
        expect(HealthStatus.worst([]), equals(HealthStatus.healthy));
      });
    });
  });
}
