import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter_widgets/src/background/sync_priority.dart';

void main() {
  group('SyncPriority', () {
    test('has all expected values', () {
      expect(SyncPriority.values, hasLength(4));
      expect(SyncPriority.values, contains(SyncPriority.critical));
      expect(SyncPriority.values, contains(SyncPriority.high));
      expect(SyncPriority.values, contains(SyncPriority.normal));
      expect(SyncPriority.values, contains(SyncPriority.low));
    });

    test('critical has highest priority (index 0)', () {
      expect(SyncPriority.critical.index, equals(0));
    });

    test('high has second highest priority (index 1)', () {
      expect(SyncPriority.high.index, equals(1));
    });

    test('normal has third priority (index 2)', () {
      expect(SyncPriority.normal.index, equals(2));
    });

    test('low has lowest priority (index 3)', () {
      expect(SyncPriority.low.index, equals(3));
    });

    group('comparison', () {
      test('critical is higher priority than high', () {
        expect(SyncPriority.critical.index < SyncPriority.high.index, isTrue);
      });

      test('high is higher priority than normal', () {
        expect(SyncPriority.high.index < SyncPriority.normal.index, isTrue);
      });

      test('normal is higher priority than low', () {
        expect(SyncPriority.normal.index < SyncPriority.low.index, isTrue);
      });
    });
  });
}
