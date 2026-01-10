import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('BrickSyncPolicy', () {
    test('has all expected values', () {
      expect(BrickSyncPolicy.values, hasLength(3));
      expect(BrickSyncPolicy.values, contains(BrickSyncPolicy.immediate));
      expect(BrickSyncPolicy.values, contains(BrickSyncPolicy.batch));
      expect(BrickSyncPolicy.values, contains(BrickSyncPolicy.manual));
    });
  });

  group('BrickConflictResolution', () {
    test('has all expected values', () {
      expect(BrickConflictResolution.values, hasLength(4));
      expect(
        BrickConflictResolution.values,
        contains(BrickConflictResolution.serverWins),
      );
      expect(
        BrickConflictResolution.values,
        contains(BrickConflictResolution.clientWins),
      );
      expect(
        BrickConflictResolution.values,
        contains(BrickConflictResolution.lastWriteWins),
      );
      expect(
        BrickConflictResolution.values,
        contains(BrickConflictResolution.merge),
      );
    });
  });

  group('BrickRetryPolicy', () {
    test('creates with default values', () {
      const policy = BrickRetryPolicy();

      expect(policy.maxAttempts, 3);
      expect(policy.backoffMs, 1000);
      expect(policy.exponentialBackoff, isTrue);
      expect(policy.maxBackoffMs, 30000);
    });

    test('creates with custom values', () {
      const policy = BrickRetryPolicy(
        maxAttempts: 5,
        backoffMs: 500,
        exponentialBackoff: false,
        maxBackoffMs: 10000,
      );

      expect(policy.maxAttempts, 5);
      expect(policy.backoffMs, 500);
      expect(policy.exponentialBackoff, isFalse);
      expect(policy.maxBackoffMs, 10000);
    });

    test('getBackoffDuration returns correct duration for attempt', () {
      const policy = BrickRetryPolicy(
        maxBackoffMs: 10000,
      );

      expect(policy.getBackoffDuration(0), const Duration(milliseconds: 1000));
      expect(policy.getBackoffDuration(1), const Duration(milliseconds: 2000));
      expect(policy.getBackoffDuration(2), const Duration(milliseconds: 4000));
      expect(policy.getBackoffDuration(3), const Duration(milliseconds: 8000));
      // Capped at maxBackoffMs
      expect(policy.getBackoffDuration(4), const Duration(milliseconds: 10000));
    });

    test('getBackoffDuration with linear backoff', () {
      const policy = BrickRetryPolicy(
        exponentialBackoff: false,
        maxBackoffMs: 10000,
      );

      expect(policy.getBackoffDuration(0), const Duration(milliseconds: 1000));
      expect(policy.getBackoffDuration(1), const Duration(milliseconds: 1000));
      expect(policy.getBackoffDuration(5), const Duration(milliseconds: 1000));
    });

    test('copyWith creates new instance with overrides', () {
      const original = BrickRetryPolicy();
      final copy = original.copyWith(maxAttempts: 10);

      expect(copy.maxAttempts, 10);
      expect(copy.backoffMs, original.backoffMs);
      expect(copy.exponentialBackoff, original.exponentialBackoff);
    });

    test('copyWith preserves maxAttempts when not overridden', () {
      const original = BrickRetryPolicy(maxAttempts: 7);
      final copy = original.copyWith(backoffMs: 2000);

      expect(copy.maxAttempts, 7);
      expect(copy.backoffMs, 2000);
    });
  });

  group('BrickSyncConfig', () {
    test('creates with default values', () {
      const config = BrickSyncConfig();

      expect(config.syncPolicy, BrickSyncPolicy.immediate);
      expect(config.conflictResolution, BrickConflictResolution.serverWins);
      expect(config.retryPolicy, isNotNull);
      expect(config.batchSize, 50);
      expect(config.syncIntervalMs, isNull);
    });

    test('creates with custom values', () {
      const retryPolicy = BrickRetryPolicy(maxAttempts: 5);
      const config = BrickSyncConfig(
        syncPolicy: BrickSyncPolicy.batch,
        conflictResolution: BrickConflictResolution.clientWins,
        retryPolicy: retryPolicy,
        batchSize: 100,
        syncIntervalMs: 5000,
      );

      expect(config.syncPolicy, BrickSyncPolicy.batch);
      expect(config.conflictResolution, BrickConflictResolution.clientWins);
      expect(config.retryPolicy.maxAttempts, 5);
      expect(config.batchSize, 100);
      expect(config.syncIntervalMs, 5000);
    });

    test('copyWith creates new instance with overrides', () {
      const original = BrickSyncConfig();
      final copy = original.copyWith(
        syncPolicy: BrickSyncPolicy.manual,
        batchSize: 200,
      );

      expect(copy.syncPolicy, BrickSyncPolicy.manual);
      expect(copy.batchSize, 200);
      expect(copy.conflictResolution, original.conflictResolution);
    });

    test('copyWith preserves syncPolicy when not overridden', () {
      const original = BrickSyncConfig(syncPolicy: BrickSyncPolicy.batch);
      final copy = original.copyWith(
        conflictResolution: BrickConflictResolution.clientWins,
      );

      expect(copy.syncPolicy, BrickSyncPolicy.batch);
      expect(copy.conflictResolution, BrickConflictResolution.clientWins);
    });

    test('copyWith preserves batchSize when not overridden', () {
      const original = BrickSyncConfig(batchSize: 100);
      final copy = original.copyWith(syncIntervalMs: 5000);

      expect(copy.batchSize, 100);
      expect(copy.syncIntervalMs, 5000);
    });

    test('provides convenience factory for immediate sync', () {
      const config = BrickSyncConfig.immediate();

      expect(config.syncPolicy, BrickSyncPolicy.immediate);
    });

    test('provides convenience factory for batch sync', () {
      const config = BrickSyncConfig.batch(batchSize: 25);

      expect(config.syncPolicy, BrickSyncPolicy.batch);
      expect(config.batchSize, 25);
    });

    test('provides convenience factory for manual sync', () {
      const config = BrickSyncConfig.manual();

      expect(config.syncPolicy, BrickSyncPolicy.manual);
    });
  });
}
