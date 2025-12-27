import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';

void main() {
  group('BackgroundSyncStatus', () {
    test('has all expected values', () {
      expect(BackgroundSyncStatus.values, hasLength(5));
      expect(BackgroundSyncStatus.values, contains(BackgroundSyncStatus.idle));
      expect(
          BackgroundSyncStatus.values, contains(BackgroundSyncStatus.scheduled));
      expect(
          BackgroundSyncStatus.values, contains(BackgroundSyncStatus.running));
      expect(
          BackgroundSyncStatus.values, contains(BackgroundSyncStatus.completed));
      expect(BackgroundSyncStatus.values, contains(BackgroundSyncStatus.failed));
    });

    group('state transitions', () {
      test('idle is the initial state', () {
        expect(BackgroundSyncStatus.idle.index, equals(0));
      });

      test('scheduled follows idle', () {
        expect(BackgroundSyncStatus.scheduled.index, equals(1));
      });

      test('running follows scheduled', () {
        expect(BackgroundSyncStatus.running.index, equals(2));
      });

      test('completed follows running', () {
        expect(BackgroundSyncStatus.completed.index, equals(3));
      });

      test('failed is a terminal state', () {
        expect(BackgroundSyncStatus.failed.index, equals(4));
      });
    });

    group('isActive', () {
      test('idle is not active', () {
        expect(BackgroundSyncStatus.idle.isActive, isFalse);
      });

      test('scheduled is active', () {
        expect(BackgroundSyncStatus.scheduled.isActive, isTrue);
      });

      test('running is active', () {
        expect(BackgroundSyncStatus.running.isActive, isTrue);
      });

      test('completed is not active', () {
        expect(BackgroundSyncStatus.completed.isActive, isFalse);
      });

      test('failed is not active', () {
        expect(BackgroundSyncStatus.failed.isActive, isFalse);
      });
    });

    group('isTerminal', () {
      test('idle is not terminal', () {
        expect(BackgroundSyncStatus.idle.isTerminal, isFalse);
      });

      test('scheduled is not terminal', () {
        expect(BackgroundSyncStatus.scheduled.isTerminal, isFalse);
      });

      test('running is not terminal', () {
        expect(BackgroundSyncStatus.running.isTerminal, isFalse);
      });

      test('completed is terminal', () {
        expect(BackgroundSyncStatus.completed.isTerminal, isTrue);
      });

      test('failed is terminal', () {
        expect(BackgroundSyncStatus.failed.isTerminal, isTrue);
      });
    });
  });
}
