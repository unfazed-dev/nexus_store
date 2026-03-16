import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('Background Refetch Manager (A5)', () {
    group('RefetchConfig', () {
      test('construction with defaults', () {
        const config = RefetchConfig();

        expect(config.interval, isNull);
        expect(config.refetchOnReconnect, isFalse);
        expect(config.refetchOnResume, isFalse);
        expect(config.isEnabled, isFalse);
      });

      test('with interval only', () {
        const config = RefetchConfig(
          interval: Duration(minutes: 5),
        );

        expect(config.interval, equals(const Duration(minutes: 5)));
        expect(config.isEnabled, isTrue);
      });

      test('with reconnect only', () {
        const config = RefetchConfig(refetchOnReconnect: true);

        expect(config.refetchOnReconnect, isTrue);
        expect(config.isEnabled, isTrue);
      });

      test('with resume only', () {
        const config = RefetchConfig(refetchOnResume: true);

        expect(config.refetchOnResume, isTrue);
        expect(config.isEnabled, isTrue);
      });

      test('equality', () {
        const a = RefetchConfig(interval: Duration(minutes: 5));
        const b = RefetchConfig(interval: Duration(minutes: 5));
        const c = RefetchConfig(interval: Duration(minutes: 10));

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });

      test('toString', () {
        const config = RefetchConfig(interval: Duration(minutes: 5));

        expect(config.toString(), contains('interval'));
      });
    });

    group('RefetchManager', () {
      test('starts timer on start', () {
        var refetchCount = 0;
        final manager = RefetchManager(
          config: const RefetchConfig(
            interval: Duration(milliseconds: 50),
          ),
          onRefetch: () async => refetchCount++,
        );

        manager.start();

        expect(manager.isTimerActive, isTrue);
        manager.dispose();
      });

      test('triggers refetch at interval', () async {
        var refetchCount = 0;
        final manager = RefetchManager(
          config: const RefetchConfig(
            interval: Duration(milliseconds: 50),
          ),
          onRefetch: () async => refetchCount++,
        );

        manager.start();
        await Future<void>.delayed(const Duration(milliseconds: 130));
        manager.dispose();

        expect(refetchCount, greaterThanOrEqualTo(2));
      });

      test('cancels timer on dispose', () {
        final manager = RefetchManager(
          config: const RefetchConfig(
            interval: Duration(milliseconds: 50),
          ),
          onRefetch: () async {},
        );

        manager.start();
        expect(manager.isTimerActive, isTrue);

        manager.dispose();
        expect(manager.isTimerActive, isFalse);
        expect(manager.isDisposed, isTrue);
      });

      test('fires on connectivity restored', () async {
        var refetchCount = 0;
        final connectivityController = StreamController<bool>.broadcast();

        final manager = RefetchManager(
          config: const RefetchConfig(refetchOnReconnect: true),
          onRefetch: () async => refetchCount++,
          connectivityStream: connectivityController.stream,
        );

        manager.start();
        connectivityController.add(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        manager.dispose();
        await connectivityController.close();

        expect(refetchCount, equals(1));
      });

      test('does not fire on connectivity lost', () async {
        var refetchCount = 0;
        final connectivityController = StreamController<bool>.broadcast();

        final manager = RefetchManager(
          config: const RefetchConfig(refetchOnReconnect: true),
          onRefetch: () async => refetchCount++,
          connectivityStream: connectivityController.stream,
        );

        manager.start();
        connectivityController.add(false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        manager.dispose();
        await connectivityController.close();

        expect(refetchCount, equals(0));
      });

      test('fires on app resume', () async {
        var refetchCount = 0;
        final resumeController = StreamController<void>.broadcast();

        final manager = RefetchManager(
          config: const RefetchConfig(refetchOnResume: true),
          onRefetch: () async => refetchCount++,
          resumeStream: resumeController.stream,
        );

        manager.start();
        resumeController.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        manager.dispose();
        await resumeController.close();

        expect(refetchCount, equals(1));
      });

      test('no-ops when config is not enabled', () {
        var refetchCount = 0;
        final manager = RefetchManager(
          config: const RefetchConfig(),
          onRefetch: () async => refetchCount++,
        );

        manager.start();

        expect(manager.isTimerActive, isFalse);
        manager.dispose();
        expect(refetchCount, equals(0));
      });

      test('dispose cleans up subscriptions', () async {
        final connectivityController = StreamController<bool>.broadcast();
        final resumeController = StreamController<void>.broadcast();

        final manager = RefetchManager(
          config: const RefetchConfig(
            interval: Duration(milliseconds: 50),
            refetchOnReconnect: true,
            refetchOnResume: true,
          ),
          onRefetch: () async {},
          connectivityStream: connectivityController.stream,
          resumeStream: resumeController.stream,
        );

        manager.start();
        manager.dispose();

        expect(manager.isDisposed, isTrue);
        expect(manager.isTimerActive, isFalse);

        await connectivityController.close();
        await resumeController.close();
      });

      test('silently ignores refetch errors', () async {
        var callCount = 0;
        final manager = RefetchManager(
          config: const RefetchConfig(
            interval: Duration(milliseconds: 50),
          ),
          onRefetch: () async {
            callCount++;
            throw Exception('Network error');
          },
        );

        manager.start();
        await Future<void>.delayed(const Duration(milliseconds: 130));
        manager.dispose();

        // Should have been called despite errors
        expect(callCount, greaterThanOrEqualTo(2));
      });

      test('does not refetch after dispose', () async {
        var refetchCount = 0;
        final connectivityController = StreamController<bool>.broadcast();

        final manager = RefetchManager(
          config: const RefetchConfig(refetchOnReconnect: true),
          onRefetch: () async => refetchCount++,
          connectivityStream: connectivityController.stream,
        );

        manager.start();
        manager.dispose();

        // Send event after dispose — should not trigger refetch
        connectivityController.add(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await connectivityController.close();

        expect(refetchCount, equals(0));
      });
    });
  });
}
