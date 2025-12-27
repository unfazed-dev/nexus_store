import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';

/// Test implementation of BackgroundSyncTask
class TestSyncTask implements BackgroundSyncTask {
  TestSyncTask({
    required this.taskId,
    this.shouldSucceed = true,
    this.executionDelay = Duration.zero,
  });

  @override
  final String taskId;

  final bool shouldSucceed;
  final Duration executionDelay;

  int executeCount = 0;

  @override
  Future<bool> execute() async {
    executeCount++;
    if (executionDelay > Duration.zero) {
      await Future<void>.delayed(executionDelay);
    }
    return shouldSucceed;
  }
}

void main() {
  group('BackgroundSyncTask', () {
    group('interface contract', () {
      test('taskId returns unique identifier', () {
        final task = TestSyncTask(taskId: 'test-task-1');

        expect(task.taskId, equals('test-task-1'));
      });

      test('taskId can be any string', () {
        final task1 = TestSyncTask(taskId: 'simple');
        final task2 = TestSyncTask(taskId: 'com.example.sync.users');
        final task3 = TestSyncTask(taskId: 'task_with_underscore');

        expect(task1.taskId, equals('simple'));
        expect(task2.taskId, equals('com.example.sync.users'));
        expect(task3.taskId, equals('task_with_underscore'));
      });
    });

    group('execute', () {
      test('returns true on success', () async {
        final task = TestSyncTask(taskId: 'test', shouldSucceed: true);

        final result = await task.execute();

        expect(result, isTrue);
      });

      test('returns false on failure', () async {
        final task = TestSyncTask(taskId: 'test', shouldSucceed: false);

        final result = await task.execute();

        expect(result, isFalse);
      });

      test('can be called multiple times', () async {
        final task = TestSyncTask(taskId: 'test');

        await task.execute();
        await task.execute();
        await task.execute();

        expect(task.executeCount, equals(3));
      });

      test('executes asynchronously', () async {
        final task = TestSyncTask(
          taskId: 'test',
          executionDelay: const Duration(milliseconds: 10),
        );

        final stopwatch = Stopwatch()..start();
        await task.execute();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(10));
      });
    });
  });
}
