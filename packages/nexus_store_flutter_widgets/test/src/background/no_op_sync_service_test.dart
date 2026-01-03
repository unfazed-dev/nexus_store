import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_task.dart';
import 'package:nexus_store_flutter_widgets/src/background/no_op_sync_service.dart';

/// Test implementation of BackgroundSyncTask
class TestSyncTask implements BackgroundSyncTask {
  @override
  final String taskId = 'test-task';

  @override
  Future<bool> execute() async => true;
}

void main() {
  group('NoOpSyncService', () {
    late NoOpSyncService service;

    setUp(() {
      service = NoOpSyncService();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('isSupported', () {
      test('returns false', () {
        expect(service.isSupported, isFalse);
      });
    });

    group('isInitialized', () {
      test('returns false initially', () {
        expect(service.isInitialized, isFalse);
      });

      test('returns true after initialize', () async {
        await service.initialize(const BackgroundSyncConfig());

        expect(service.isInitialized, isTrue);
      });
    });

    group('initialize', () {
      test('completes without error', () async {
        await expectLater(
          service.initialize(const BackgroundSyncConfig()),
          completes,
        );
      });

      test('accepts any configuration', () async {
        const config = BackgroundSyncConfig(
          enabled: false,
          minInterval: Duration(hours: 2),
          requiresCharging: true,
        );

        await expectLater(
          service.initialize(config),
          completes,
        );
      });
    });

    group('registerTask', () {
      test('completes without error', () async {
        final task = TestSyncTask();

        await expectLater(
          service.registerTask(task),
          completes,
        );
      });
    });

    group('scheduleSync', () {
      test('completes without error', () async {
        await service.initialize(const BackgroundSyncConfig());

        await expectLater(
          service.scheduleSync(),
          completes,
        );
      });

      test('does not change status (no-op)', () async {
        await service.initialize(const BackgroundSyncConfig());

        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        await service.scheduleSync();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // No status changes expected in no-op implementation
        expect(statuses, isEmpty);

        await subscription.cancel();
      });
    });

    group('cancelSync', () {
      test('completes without error', () async {
        await expectLater(
          service.cancelSync(),
          completes,
        );
      });
    });

    group('statusStream', () {
      test('is a broadcast stream', () {
        expect(service.statusStream.isBroadcast, isTrue);
      });

      test('does not emit any values', () async {
        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        await service.initialize(const BackgroundSyncConfig());
        await service.scheduleSync();
        await service.cancelSync();

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(statuses, isEmpty);

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('completes without error', () async {
        await expectLater(
          service.dispose(),
          completes,
        );
      });

      test('can be called multiple times', () async {
        await service.dispose();

        await expectLater(
          service.dispose(),
          completes,
        );
      });
    });
  });
}
