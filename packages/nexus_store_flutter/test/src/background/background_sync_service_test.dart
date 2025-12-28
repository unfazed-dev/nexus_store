import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter/src/background/background_sync_service.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';

/// Test implementation of BackgroundSyncTask
class TestSyncTask implements BackgroundSyncTask {
  TestSyncTask({required this.taskId});

  @override
  final String taskId;

  @override
  Future<bool> execute() async => true;
}

/// Test implementation of BackgroundSyncService
class TestBackgroundSyncService extends BackgroundSyncService {
  TestBackgroundSyncService({this.platformSupported = true});

  final bool platformSupported;
  BackgroundSyncConfig? currentConfig;
  bool _initialized = false;
  bool _syncScheduled = false;
  final _statusController =
      StreamController<BackgroundSyncStatus>.broadcast();

  @override
  bool get isSupported => platformSupported;

  @override
  bool get isInitialized => _initialized;

  @override
  Stream<BackgroundSyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize(BackgroundSyncConfig config) async {
    currentConfig = config;
    _initialized = true;
  }

  @override
  Future<void> registerTask(BackgroundSyncTask task) async {
    // Store task for testing
  }

  @override
  Future<void> scheduleSync() async {
    _syncScheduled = true;
    _statusController.add(BackgroundSyncStatus.scheduled);
  }

  @override
  Future<void> cancelSync() async {
    _syncScheduled = false;
    _statusController.add(BackgroundSyncStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  // Test helper
  void emitStatus(BackgroundSyncStatus status) {
    _statusController.add(status);
  }

  bool get isSyncScheduled => _syncScheduled;
}

void main() {
  group('BackgroundSyncService', () {
    late TestBackgroundSyncService service;

    setUp(() {
      service = TestBackgroundSyncService();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('isSupported', () {
      test('returns true when platform is supported', () {
        final supportedService = TestBackgroundSyncService(
          
        );

        expect(supportedService.isSupported, isTrue);
      });

      test('returns false when platform is not supported', () {
        final unsupportedService = TestBackgroundSyncService(
          platformSupported: false,
        );

        expect(unsupportedService.isSupported, isFalse);
      });
    });

    group('initialize', () {
      test('stores configuration', () async {
        const config = BackgroundSyncConfig();

        await service.initialize(config);

        expect(service.currentConfig, equals(config));
      });

      test('marks service as initialized', () async {
        expect(service.isInitialized, isFalse);

        await service.initialize(const BackgroundSyncConfig());

        expect(service.isInitialized, isTrue);
      });

      test('accepts custom configuration', () async {
        const config = BackgroundSyncConfig(
          minInterval: Duration(hours: 1),
          requiresCharging: true,
        );

        await service.initialize(config);

        expect(service.currentConfig?.minInterval, equals(
          const Duration(hours: 1),
        ),);
        expect(service.currentConfig?.requiresCharging, isTrue);
      });
    });

    group('registerTask', () {
      test('registers task without error', () async {
        final task = TestSyncTask(taskId: 'test-task');

        await expectLater(
          service.registerTask(task),
          completes,
        );
      });
    });

    group('scheduleSync', () {
      test('schedules sync', () async {
        await service.initialize(const BackgroundSyncConfig());

        await service.scheduleSync();

        expect(service.isSyncScheduled, isTrue);
      });

      test('emits scheduled status', () async {
        await service.initialize(const BackgroundSyncConfig());

        final statusFuture = service.statusStream.first;
        await service.scheduleSync();

        expect(await statusFuture, equals(BackgroundSyncStatus.scheduled));
      });
    });

    group('cancelSync', () {
      test('cancels scheduled sync', () async {
        await service.initialize(const BackgroundSyncConfig());
        await service.scheduleSync();

        await service.cancelSync();

        expect(service.isSyncScheduled, isFalse);
      });

      test('emits idle status', () async {
        await service.initialize(const BackgroundSyncConfig());
        await service.scheduleSync();

        final statusFuture = service.statusStream.first;
        await service.cancelSync();

        expect(await statusFuture, equals(BackgroundSyncStatus.idle));
      });
    });

    group('statusStream', () {
      test('is a broadcast stream', () {
        expect(service.statusStream.isBroadcast, isTrue);
      });

      test('emits status updates', () async {
        final statuses = <BackgroundSyncStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        service.emitStatus(BackgroundSyncStatus.scheduled);
        service.emitStatus(BackgroundSyncStatus.running);
        service.emitStatus(BackgroundSyncStatus.completed);

        await Future<void>.delayed(Duration.zero);

        expect(statuses, [
          BackgroundSyncStatus.scheduled,
          BackgroundSyncStatus.running,
          BackgroundSyncStatus.completed,
        ]);

        await subscription.cancel();
      });

      test('supports multiple listeners', () async {
        final statuses1 = <BackgroundSyncStatus>[];
        final statuses2 = <BackgroundSyncStatus>[];

        final sub1 = service.statusStream.listen(statuses1.add);
        final sub2 = service.statusStream.listen(statuses2.add);

        service.emitStatus(BackgroundSyncStatus.running);

        await Future<void>.delayed(Duration.zero);

        expect(statuses1, [BackgroundSyncStatus.running]);
        expect(statuses2, [BackgroundSyncStatus.running]);

        await sub1.cancel();
        await sub2.cancel();
      });
    });

    group('dispose', () {
      test('closes status stream', () async {
        final testService = TestBackgroundSyncService();

        await testService.dispose();

        expect(
          () => testService.emitStatus(BackgroundSyncStatus.idle),
          throwsStateError,
        );
      });
    });
  });
}
