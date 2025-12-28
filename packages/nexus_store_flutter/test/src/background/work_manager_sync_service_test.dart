
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';
import 'package:nexus_store_flutter/src/background/work_manager_sync_service.dart';

/// Test implementation of BackgroundSyncTask
class TestSyncTask implements BackgroundSyncTask {
  TestSyncTask({this.taskId = 'test-task', this.shouldSucceed = true});

  @override
  final String taskId;

  final bool shouldSucceed;
  int executeCount = 0;

  @override
  Future<bool> execute() async {
    executeCount++;
    return shouldSucceed;
  }
}

void main() {
  group('WorkManagerSyncService', () {
    late WorkManagerSyncService service;

    setUp(() {
      service = WorkManagerSyncService();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('isSupported', () {
      test('returns true (supported on Android/iOS)', () {
        expect(service.isSupported, isTrue);
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

      test('stores configuration', () async {
        const config = BackgroundSyncConfig(
          minInterval: Duration(hours: 1),
          requiresCharging: true,
        );

        await service.initialize(config);

        expect(service.config, equals(config));
      });

      test('can be called multiple times to update config', () async {
        await service.initialize(const BackgroundSyncConfig());

        const newConfig = BackgroundSyncConfig(
          minInterval: Duration(hours: 2),
        );
        await service.initialize(newConfig);

        expect(service.config?.minInterval, equals(const Duration(hours: 2)));
      });
    });

    group('registerTask', () {
      test('adds task to registered tasks', () async {
        final task = TestSyncTask(taskId: 'task-1');

        await service.registerTask(task);

        expect(service.registeredTasks, contains(task));
      });

      test('can register multiple tasks', () async {
        final task1 = TestSyncTask(taskId: 'task-1');
        final task2 = TestSyncTask(taskId: 'task-2');

        await service.registerTask(task1);
        await service.registerTask(task2);

        expect(service.registeredTasks.length, equals(2));
      });

      test('replaces task with same id', () async {
        final task1 = TestSyncTask(taskId: 'same-id');
        final task2 = TestSyncTask(taskId: 'same-id');

        await service.registerTask(task1);
        await service.registerTask(task2);

        expect(service.registeredTasks.length, equals(1));
        expect(service.registeredTasks.first, equals(task2));
      });
    });

    group('scheduleSync', () {
      test('throws if not initialized', () async {
        expect(
          () => service.scheduleSync(),
          throwsStateError,
        );
      });

      test('throws if sync is disabled in config', () async {
        await service.initialize(const BackgroundSyncConfig.disabled());

        expect(
          () => service.scheduleSync(),
          throwsStateError,
        );
      });

      test('emits scheduled status when called', () async {
        await service.initialize(const BackgroundSyncConfig());

        final statusFuture = service.statusStream.first;
        await service.scheduleSync();

        expect(await statusFuture, equals(BackgroundSyncStatus.scheduled));
      });

      test('sets isScheduled to true', () async {
        await service.initialize(const BackgroundSyncConfig());

        await service.scheduleSync();

        expect(service.isScheduled, isTrue);
      });
    });

    group('cancelSync', () {
      test('emits idle status', () async {
        await service.initialize(const BackgroundSyncConfig());
        await service.scheduleSync();

        final statusFuture = service.statusStream.first;
        await service.cancelSync();

        expect(await statusFuture, equals(BackgroundSyncStatus.idle));
      });

      test('sets isScheduled to false', () async {
        await service.initialize(const BackgroundSyncConfig());
        await service.scheduleSync();

        await service.cancelSync();

        expect(service.isScheduled, isFalse);
      });

      test('can be called even if not scheduled', () async {
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

      test('emits status updates in order', () async {
        await service.initialize(const BackgroundSyncConfig());

        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        await service.scheduleSync();
        await service.cancelSync();

        await Future<void>.delayed(Duration.zero);

        expect(statuses, [
          BackgroundSyncStatus.scheduled,
          BackgroundSyncStatus.idle,
        ]);

        await subscription.cancel();
      });
    });

    group('executeRegisteredTasks', () {
      test('executes all registered tasks', () async {
        final task1 = TestSyncTask(taskId: 'task-1');
        final task2 = TestSyncTask(taskId: 'task-2');

        await service.registerTask(task1);
        await service.registerTask(task2);

        final result = await service.executeRegisteredTasks();

        expect(task1.executeCount, equals(1));
        expect(task2.executeCount, equals(1));
        expect(result, isTrue);
      });

      test('returns true if all tasks succeed', () async {
        final task1 = TestSyncTask(taskId: 'task-1');
        final task2 = TestSyncTask(taskId: 'task-2');

        await service.registerTask(task1);
        await service.registerTask(task2);

        final result = await service.executeRegisteredTasks();

        expect(result, isTrue);
      });

      test('returns false if any task fails', () async {
        final task1 = TestSyncTask(taskId: 'task-1');
        final task2 = TestSyncTask(taskId: 'task-2', shouldSucceed: false);

        await service.registerTask(task1);
        await service.registerTask(task2);

        final result = await service.executeRegisteredTasks();

        expect(result, isFalse);
      });

      test('returns true when no tasks registered', () async {
        final result = await service.executeRegisteredTasks();

        expect(result, isTrue);
      });

      test('emits running then completed status', () async {
        await service.initialize(const BackgroundSyncConfig());
        final task = TestSyncTask(taskId: 'task-1');
        await service.registerTask(task);

        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        await service.executeRegisteredTasks();

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(BackgroundSyncStatus.running));
        expect(statuses, contains(BackgroundSyncStatus.completed));

        await subscription.cancel();
      });

      test('emits failed status on task failure', () async {
        await service.initialize(const BackgroundSyncConfig());
        final task = TestSyncTask(taskId: 'task-1', shouldSucceed: false);
        await service.registerTask(task);

        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        await service.executeRegisteredTasks();

        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(BackgroundSyncStatus.running));
        expect(statuses, contains(BackgroundSyncStatus.failed));

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('closes status stream', () async {
        await service.dispose();

        expect(
          service.statusStream.isEmpty,
          completion(isTrue),
        );
      });

      test('clears registered tasks', () async {
        final task = TestSyncTask(taskId: 'task-1');
        await service.registerTask(task);

        await service.dispose();

        expect(service.registeredTasks, isEmpty);
      });
    });
  });
}
