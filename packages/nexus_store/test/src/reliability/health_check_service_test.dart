import 'package:test/test.dart';
import 'package:nexus_store/src/reliability/component_health.dart';
import 'package:nexus_store/src/reliability/health_check_config.dart';
import 'package:nexus_store/src/reliability/health_check_service.dart';
import 'package:nexus_store/src/reliability/health_status.dart';

void main() {
  group('HealthChecker', () {
    test('can be implemented', () {
      final checker = _TestHealthChecker('test', HealthStatus.healthy);
      expect(checker.name, equals('test'));
    });

    test('check returns ComponentHealth', () async {
      final checker = _TestHealthChecker('backend', HealthStatus.healthy);
      final health = await checker.check();
      expect(health.name, equals('backend'));
      expect(health.status, equals(HealthStatus.healthy));
    });

    test('check can return degraded status', () async {
      final checker = _TestHealthChecker(
        'cache',
        HealthStatus.degraded,
        message: 'High latency',
      );
      final health = await checker.check();
      expect(health.status, equals(HealthStatus.degraded));
      expect(health.message, equals('High latency'));
    });

    test('check can return unhealthy status', () async {
      final checker = _TestHealthChecker(
        'database',
        HealthStatus.unhealthy,
        message: 'Connection refused',
      );
      final health = await checker.check();
      expect(health.status, equals(HealthStatus.unhealthy));
      expect(health.message, equals('Connection refused'));
    });
  });

  group('HealthCheckService', () {
    late HealthCheckService service;

    setUp(() {
      service = HealthCheckService(
        config: const HealthCheckConfig(autoStart: false),
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('constructor', () {
      test('creates with default config', () {
        final defaultService = HealthCheckService();
        expect(defaultService, isNotNull);
        defaultService.dispose();
      });

      test('creates with custom config', () {
        final customService = HealthCheckService(
          config: const HealthCheckConfig(
            checkInterval: Duration(seconds: 10),
            autoStart: false,
          ),
        );
        expect(customService, isNotNull);
        customService.dispose();
      });
    });

    group('registerChecker', () {
      test('registers a health checker', () {
        final checker = _TestHealthChecker('test', HealthStatus.healthy);
        service.registerChecker(checker);
        expect(service.checkerNames, contains('test'));
      });

      test('can register multiple checkers', () {
        service.registerChecker(
            _TestHealthChecker('backend', HealthStatus.healthy));
        service
            .registerChecker(_TestHealthChecker('cache', HealthStatus.healthy));
        expect(service.checkerNames, containsAll(['backend', 'cache']));
      });

      test('replaces existing checker with same name', () {
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));
        service.registerChecker(
            _TestHealthChecker('test', HealthStatus.unhealthy));
        expect(
            service.checkerNames.where((n) => n == 'test').length, equals(1));
      });
    });

    group('unregisterChecker', () {
      test('removes a registered checker', () {
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));
        expect(service.checkerNames, contains('test'));
        service.unregisterChecker('test');
        expect(service.checkerNames, isNot(contains('test')));
      });

      test('does nothing if checker not found', () {
        service.unregisterChecker('nonexistent');
        // Should not throw
      });
    });

    group('checkHealth', () {
      test('returns healthy when no checkers registered', () async {
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.healthy));
        expect(health.components, isEmpty);
      });

      test('returns health from single checker', () async {
        service.registerChecker(
            _TestHealthChecker('backend', HealthStatus.healthy));
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.healthy));
        expect(health.components.length, equals(1));
        expect(health.components.first.name, equals('backend'));
      });

      test('returns worst status from multiple checkers', () async {
        service.registerChecker(
            _TestHealthChecker('backend', HealthStatus.healthy));
        service.registerChecker(_TestHealthChecker(
          'cache',
          HealthStatus.degraded,
          message: 'Slow',
        ));
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.degraded));
      });

      test('returns unhealthy when any checker is unhealthy', () async {
        service.registerChecker(
            _TestHealthChecker('backend', HealthStatus.healthy));
        service.registerChecker(_TestHealthChecker(
          'database',
          HealthStatus.unhealthy,
          message: 'Down',
        ));
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.unhealthy));
      });

      test('handles checker timeout', () async {
        service = HealthCheckService(
          config: const HealthCheckConfig(
            timeout: Duration(milliseconds: 100),
            autoStart: false,
          ),
        );
        service.registerChecker(_SlowHealthChecker(
          'slow',
          const Duration(milliseconds: 500),
        ));
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.unhealthy));
        expect(health.components.first.message, contains('timeout'));
      });

      test('handles checker exception', () async {
        service.registerChecker(_FailingHealthChecker('failing'));
        final health = await service.checkHealth();
        expect(health.overallStatus, equals(HealthStatus.unhealthy));
        expect(health.components.first.message, contains('Test error'));
      });
    });

    group('healthStream', () {
      test('emits initial health on subscription', () async {
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));
        await service.checkHealth(); // Populate initial state
        final health = await service.healthStream.first;
        expect(health.overallStatus, equals(HealthStatus.healthy));
      });

      test('emits health updates after checkHealth', () async {
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));
        final healthFuture = service.healthStream.take(2).toList();
        await service.checkHealth();
        await service.checkHealth();
        final healthList = await healthFuture;
        expect(healthList.length, equals(2));
      });
    });

    group('currentHealth', () {
      test('returns null before first check', () {
        expect(service.currentHealth, isNull);
      });

      test('returns last health after check', () async {
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));
        await service.checkHealth();
        expect(service.currentHealth, isNotNull);
        expect(
            service.currentHealth!.overallStatus, equals(HealthStatus.healthy));
      });
    });

    group('start and stop', () {
      test('starts periodic checks', () async {
        service = HealthCheckService(
          config: const HealthCheckConfig(
            checkInterval: Duration(milliseconds: 50),
            autoStart: false,
          ),
        );
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));

        final healthList = <SystemHealth>[];
        final sub = service.healthStream.listen(healthList.add);

        service.start();
        await Future.delayed(const Duration(milliseconds: 150));
        service.stop();
        await sub.cancel();

        expect(healthList.length, greaterThanOrEqualTo(2));
      });

      test('stop prevents further checks', () async {
        service = HealthCheckService(
          config: const HealthCheckConfig(
            checkInterval: Duration(milliseconds: 50),
            autoStart: false,
          ),
        );
        service
            .registerChecker(_TestHealthChecker('test', HealthStatus.healthy));

        service.start();
        await Future.delayed(const Duration(milliseconds: 30));
        service.stop();

        final countAfterStop = service.currentHealth != null ? 1 : 0;
        await Future.delayed(const Duration(milliseconds: 100));

        // Should not have more checks after stop
        expect(
          service.currentHealth != null ? 1 : 0,
          equals(countAfterStop),
        );
      });

      test('isRunning reflects state', () {
        expect(service.isRunning, isFalse);
        service.start();
        expect(service.isRunning, isTrue);
        service.stop();
        expect(service.isRunning, isFalse);
      });
    });

    group('dispose', () {
      test('stops checks and closes stream', () async {
        service.start();
        expect(service.isRunning, isTrue);
        service.dispose();
        expect(service.isRunning, isFalse);
      });
    });

    group('checkComponent', () {
      test('checks single component by name', () async {
        service.registerChecker(
            _TestHealthChecker('backend', HealthStatus.healthy));
        service.registerChecker(_TestHealthChecker(
            'cache', HealthStatus.degraded,
            message: 'Slow'));

        final health = await service.checkComponent('backend');
        expect(health, isNotNull);
        expect(health!.name, equals('backend'));
        expect(health.status, equals(HealthStatus.healthy));
      });

      test('returns null for unknown component', () async {
        final health = await service.checkComponent('unknown');
        expect(health, isNull);
      });
    });
  });
}

/// Test implementation of HealthChecker.
class _TestHealthChecker implements HealthChecker {
  _TestHealthChecker(this.name, this._status, {String? message})
      : _message = message;

  @override
  final String name;

  final HealthStatus _status;
  final String? _message;

  @override
  Future<ComponentHealth> check() async {
    switch (_status) {
      case HealthStatus.healthy:
        return ComponentHealth.healthy(name);
      case HealthStatus.degraded:
        return ComponentHealth.degraded(name, _message ?? 'Degraded');
      case HealthStatus.unhealthy:
        return ComponentHealth.unhealthy(name, _message ?? 'Unhealthy');
    }
  }
}

/// Health checker that simulates slow response.
class _SlowHealthChecker implements HealthChecker {
  _SlowHealthChecker(this.name, this._delay);

  @override
  final String name;

  final Duration _delay;

  @override
  Future<ComponentHealth> check() async {
    await Future.delayed(_delay);
    return ComponentHealth.healthy(name);
  }
}

/// Health checker that throws an exception.
class _FailingHealthChecker implements HealthChecker {
  _FailingHealthChecker(this.name);

  @override
  final String name;

  @override
  Future<ComponentHealth> check() async {
    throw Exception('Test error');
  }
}
