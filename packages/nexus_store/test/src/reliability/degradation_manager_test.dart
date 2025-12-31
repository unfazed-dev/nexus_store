import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/circuit_breaker.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_config.dart';
import 'package:nexus_store/src/reliability/circuit_breaker_state.dart';
import 'package:nexus_store/src/reliability/degradation_config.dart';
import 'package:nexus_store/src/reliability/degradation_manager.dart';
import 'package:nexus_store/src/reliability/degradation_mode.dart';
import 'package:nexus_store/src/reliability/health_status.dart';

void main() {
  group('DegradationManager', () {
    late DegradationManager manager;
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker(
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          successThreshold: 2,
          openDuration: Duration(milliseconds: 100),
        ),
      );
    });

    tearDown(() {
      manager.dispose();
      circuitBreaker.dispose();
    });

    group('construction', () {
      test('creates with default config', () {
        manager = DegradationManager();
        expect(manager.config, equals(DegradationConfig.defaults));
      });

      test('creates with custom config', () {
        const config = DegradationConfig(
          fallbackMode: DegradationMode.readOnly,
          cooldown: Duration(seconds: 30),
        );
        manager = DegradationManager(config: config);
        expect(manager.config, equals(config));
      });

      test('starts in normal mode', () {
        manager = DegradationManager();
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('starts not degraded', () {
        manager = DegradationManager();
        expect(manager.isDegraded, isFalse);
      });
    });

    group('currentMode', () {
      test('returns the current degradation mode', () {
        manager = DegradationManager();
        expect(manager.currentMode, equals(DegradationMode.normal));
      });
    });

    group('metrics', () {
      test('provides metrics snapshot', () {
        manager = DegradationManager();
        final metrics = manager.metrics;
        expect(metrics.mode, equals(DegradationMode.normal));
        expect(metrics.degradationCount, equals(0));
        expect(metrics.recoveryCount, equals(0));
      });
    });

    group('modeStream', () {
      test('emits current mode immediately', () async {
        manager = DegradationManager();
        final mode = await manager.modeStream.first;
        expect(mode, equals(DegradationMode.normal));
      });

      test('emits mode changes', () async {
        manager = DegradationManager();
        final modes = <DegradationMode>[];
        final subscription = manager.modeStream.listen(modes.add);

        // Trigger manual degradation
        manager.degrade(DegradationMode.cacheOnly);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(modes, contains(DegradationMode.cacheOnly));
        await subscription.cancel();
      });
    });

    group('metricsStream', () {
      test('emits metrics snapshot immediately', () async {
        manager = DegradationManager();
        final metrics = await manager.metricsStream.first;
        expect(metrics.mode, equals(DegradationMode.normal));
      });
    });

    group('degrade', () {
      test('changes mode to specified degradation', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        expect(manager.currentMode, equals(DegradationMode.cacheOnly));
      });

      test('increments degradation count', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        expect(manager.metrics.degradationCount, equals(1));
      });

      test('does nothing when disabled', () {
        manager = DegradationManager(config: DegradationConfig.disabled);
        manager.degrade(DegradationMode.cacheOnly);
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('updates lastModeChange timestamp', () {
        manager = DegradationManager();
        final before = DateTime.now();
        manager.degrade(DegradationMode.cacheOnly);
        final after = DateTime.now();

        final lastChange = manager.metrics.lastModeChange;
        expect(lastChange, isNotNull);
        expect(lastChange!.isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            lastChange.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('can degrade to worse mode', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        manager.degrade(DegradationMode.offline);
        expect(manager.currentMode, equals(DegradationMode.offline));
      });
    });

    group('recover', () {
      test('returns to normal mode', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        manager.recover();
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('returns to specified mode', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.offline);
        manager.recover(to: DegradationMode.cacheOnly);
        expect(manager.currentMode, equals(DegradationMode.cacheOnly));
      });

      test('increments recovery count', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        manager.recover();
        expect(manager.metrics.recoveryCount, equals(1));
      });

      test('does nothing when already normal', () {
        manager = DegradationManager();
        manager.recover();
        expect(manager.metrics.recoveryCount, equals(0));
      });
    });

    group('setMode', () {
      test('directly sets the mode', () {
        manager = DegradationManager();
        manager.setMode(DegradationMode.readOnly);
        expect(manager.currentMode, equals(DegradationMode.readOnly));
      });

      test('tracks degradation when moving to degraded mode', () {
        manager = DegradationManager();
        manager.setMode(DegradationMode.cacheOnly);
        expect(manager.metrics.degradationCount, equals(1));
      });

      test('tracks recovery when moving to normal mode', () {
        manager = DegradationManager();
        manager.setMode(DegradationMode.cacheOnly);
        manager.setMode(DegradationMode.normal);
        expect(manager.metrics.recoveryCount, equals(1));
      });
    });

    group('auto degradation with circuit breaker', () {
      test('degrades when circuit breaker opens', () async {
        manager = DegradationManager(
          circuitBreaker: circuitBreaker,
          config: const DegradationConfig(
            autoDegradation: true,
            fallbackMode: DegradationMode.cacheOnly,
          ),
        );

        // Open the circuit breaker
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(manager.currentMode, equals(DegradationMode.cacheOnly));
      });

      test('recovers when circuit breaker closes', () async {
        manager = DegradationManager(
          circuitBreaker: circuitBreaker,
          config: const DegradationConfig(
            autoDegradation: true,
            fallbackMode: DegradationMode.cacheOnly,
            cooldown: Duration.zero,
          ),
        );

        // Open the circuit breaker
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(manager.currentMode, equals(DegradationMode.cacheOnly));

        // Wait for circuit breaker to go half-open
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Record successes to close it
        circuitBreaker.recordSuccess();
        circuitBreaker.recordSuccess();

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(circuitBreaker.currentState, equals(CircuitBreakerState.closed));
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('does not auto-degrade when disabled', () async {
        manager = DegradationManager(
          circuitBreaker: circuitBreaker,
          config: const DegradationConfig(
            autoDegradation: false,
          ),
        );

        // Open the circuit breaker
        for (var i = 0; i < 3; i++) {
          circuitBreaker.recordFailure();
        }

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(manager.currentMode, equals(DegradationMode.normal));
      });
    });

    group('onHealthChange', () {
      test('degrades when health becomes unhealthy', () {
        manager = DegradationManager(
          config: const DegradationConfig(
            autoDegradation: true,
            fallbackMode: DegradationMode.cacheOnly,
          ),
        );

        manager.onHealthChange(HealthStatus.unhealthy);
        expect(manager.currentMode, equals(DegradationMode.cacheOnly));
      });

      test('does not degrade for degraded health status', () {
        manager = DegradationManager(
          config: const DegradationConfig(
            autoDegradation: true,
          ),
        );

        manager.onHealthChange(HealthStatus.degraded);
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('recovers when health becomes healthy', () {
        manager = DegradationManager(
          config: const DegradationConfig(
            autoDegradation: true,
            cooldown: Duration.zero,
          ),
        );

        manager.onHealthChange(HealthStatus.unhealthy);
        expect(manager.isDegraded, isTrue);

        manager.onHealthChange(HealthStatus.healthy);
        expect(manager.currentMode, equals(DegradationMode.normal));
      });

      test('respects cooldown before recovery', () async {
        manager = DegradationManager(
          config: const DegradationConfig(
            autoDegradation: true,
            cooldown: Duration(milliseconds: 100),
          ),
        );

        manager.onHealthChange(HealthStatus.unhealthy);
        expect(manager.isDegraded, isTrue);

        // Immediately try to recover - should be blocked by cooldown
        manager.onHealthChange(HealthStatus.healthy);
        expect(manager.isDegraded, isTrue);

        // Wait for cooldown
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Now recovery should work
        manager.onHealthChange(HealthStatus.healthy);
        expect(manager.isDegraded, isFalse);
      });
    });

    group('canRecover', () {
      test('returns true when cooldown has passed', () async {
        manager = DegradationManager(
          config: const DegradationConfig(
            cooldown: Duration(milliseconds: 50),
          ),
        );

        manager.degrade(DegradationMode.cacheOnly);
        expect(manager.canRecover, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(manager.canRecover, isTrue);
      });

      test('returns true when not degraded', () {
        manager = DegradationManager();
        expect(manager.canRecover, isTrue);
      });
    });

    group('dispose', () {
      test('closes streams', () async {
        manager = DegradationManager();
        manager.dispose();

        // After dispose, the stream is closed
        // Verify by checking stream is done
        var isDone = false;
        manager.modeStream.listen(
          (_) {},
          onDone: () => isDone = true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(isDone, isTrue);
      });

      test('cancels circuit breaker subscription', () {
        manager = DegradationManager(circuitBreaker: circuitBreaker);
        manager.dispose();
        // No exception means subscription was properly cancelled
      });
    });

    group('edge cases', () {
      test('handles multiple rapid degradations', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        manager.degrade(DegradationMode.readOnly);
        manager.degrade(DegradationMode.offline);

        expect(manager.currentMode, equals(DegradationMode.offline));
        expect(manager.metrics.degradationCount, equals(3));
      });

      test('handles degradation to same mode', () {
        manager = DegradationManager();
        manager.degrade(DegradationMode.cacheOnly);
        final countBefore = manager.metrics.degradationCount;
        manager.degrade(DegradationMode.cacheOnly);

        // Should not increment count for same mode
        expect(manager.metrics.degradationCount, equals(countBefore));
      });
    });
  });
}
