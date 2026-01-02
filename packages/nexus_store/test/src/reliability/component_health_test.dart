import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/component_health.dart';
import 'package:nexus_store/src/reliability/health_status.dart';

void main() {
  group('ComponentHealth', () {
    group('factory healthy', () {
      test('creates healthy component', () {
        final health = ComponentHealth.healthy('backend');
        expect(health.name, equals('backend'));
        expect(health.status, equals(HealthStatus.healthy));
      });

      test('sets checkedAt to current time', () {
        final before = DateTime.now();
        final health = ComponentHealth.healthy('backend');
        final after = DateTime.now();

        expect(
          health.checkedAt.isAfter(before) ||
              health.checkedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          health.checkedAt.isBefore(after) ||
              health.checkedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('can include response time', () {
        final health = ComponentHealth.healthy(
          'backend',
          responseTime: const Duration(milliseconds: 50),
        );
        expect(health.responseTime, equals(const Duration(milliseconds: 50)));
      });
    });

    group('factory degraded', () {
      test('creates degraded component', () {
        final health = ComponentHealth.degraded('cache', 'High latency');
        expect(health.name, equals('cache'));
        expect(health.status, equals(HealthStatus.degraded));
        expect(health.message, equals('High latency'));
      });
    });

    group('factory unhealthy', () {
      test('creates unhealthy component', () {
        final health = ComponentHealth.unhealthy('sync', 'Connection refused');
        expect(health.name, equals('sync'));
        expect(health.status, equals(HealthStatus.unhealthy));
        expect(health.message, equals('Connection refused'));
      });
    });

    group('custom values', () {
      test('can create with all values', () {
        final checkedAt = DateTime.now();
        final health = ComponentHealth(
          name: 'database',
          status: HealthStatus.healthy,
          checkedAt: checkedAt,
          message: 'OK',
          responseTime: const Duration(milliseconds: 10),
          details: {'connections': 5},
        );

        expect(health.name, equals('database'));
        expect(health.status, equals(HealthStatus.healthy));
        expect(health.checkedAt, equals(checkedAt));
        expect(health.message, equals('OK'));
        expect(health.responseTime, equals(const Duration(milliseconds: 10)));
        expect(health.details, equals({'connections': 5}));
      });
    });

    group('equality', () {
      test('equal components are equal', () {
        final time = DateTime.now();
        final health1 = ComponentHealth(
          name: 'backend',
          status: HealthStatus.healthy,
          checkedAt: time,
        );
        final health2 = ComponentHealth(
          name: 'backend',
          status: HealthStatus.healthy,
          checkedAt: time,
        );
        expect(health1, equals(health2));
      });
    });
  });

  group('SystemHealth', () {
    group('factory fromComponents', () {
      test('creates healthy when all components healthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.healthy('cache'),
        ]);

        expect(health.overallStatus, equals(HealthStatus.healthy));
        expect(health.components.length, equals(2));
      });

      test('creates degraded when any component degraded', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.degraded('cache', 'Slow'),
        ]);

        expect(health.overallStatus, equals(HealthStatus.degraded));
      });

      test('creates unhealthy when any component unhealthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.degraded('cache', 'Slow'),
          ComponentHealth.unhealthy('sync', 'Failed'),
        ]);

        expect(health.overallStatus, equals(HealthStatus.unhealthy));
      });

      test('creates healthy for empty components', () {
        final health = SystemHealth.fromComponents([]);
        expect(health.overallStatus, equals(HealthStatus.healthy));
        expect(health.components, isEmpty);
      });
    });

    group('factory empty', () {
      test('creates healthy system with no components', () {
        final health = SystemHealth.empty();
        expect(health.overallStatus, equals(HealthStatus.healthy));
        expect(health.components, isEmpty);
      });
    });

    group('getComponent', () {
      test('returns component by name', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.degraded('cache', 'Slow'),
        ]);

        final backend = health.getComponent('backend');
        expect(backend, isNotNull);
        expect(backend!.name, equals('backend'));
        expect(backend.status, equals(HealthStatus.healthy));
      });

      test('returns null for unknown component', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
        ]);

        expect(health.getComponent('unknown'), isNull);
      });
    });

    group('hasUnhealthyComponents', () {
      test('returns false when all healthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.healthy('cache'),
        ]);

        expect(health.hasUnhealthyComponents, isFalse);
      });

      test('returns false when degraded but not unhealthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.degraded('cache', 'Slow'),
        ]);

        expect(health.hasUnhealthyComponents, isFalse);
      });

      test('returns true when any unhealthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.unhealthy('sync', 'Failed'),
        ]);

        expect(health.hasUnhealthyComponents, isTrue);
      });
    });

    group('hasDegradedComponents', () {
      test('returns false when all healthy', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.healthy('cache'),
        ]);

        expect(health.hasDegradedComponents, isFalse);
      });

      test('returns true when any degraded', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
          ComponentHealth.degraded('cache', 'Slow'),
        ]);

        expect(health.hasDegradedComponents, isTrue);
      });
    });

    group('copyWith', () {
      test('can update overall status', () {
        final health = SystemHealth.fromComponents([
          ComponentHealth.healthy('backend'),
        ]);
        final updated = health.copyWith(overallStatus: HealthStatus.degraded);

        expect(updated.overallStatus, equals(HealthStatus.degraded));
        expect(updated.components.length, equals(1));
      });
    });
  });
}
