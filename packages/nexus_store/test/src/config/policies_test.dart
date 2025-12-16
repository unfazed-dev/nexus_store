import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('FetchPolicy', () {
    test('should have 6 policy variants', () {
      expect(FetchPolicy.values, hasLength(6));
    });

    test('should contain cacheFirst', () {
      expect(FetchPolicy.values, contains(FetchPolicy.cacheFirst));
    });

    test('should contain networkFirst', () {
      expect(FetchPolicy.values, contains(FetchPolicy.networkFirst));
    });

    test('should contain cacheAndNetwork', () {
      expect(FetchPolicy.values, contains(FetchPolicy.cacheAndNetwork));
    });

    test('should contain cacheOnly', () {
      expect(FetchPolicy.values, contains(FetchPolicy.cacheOnly));
    });

    test('should contain networkOnly', () {
      expect(FetchPolicy.values, contains(FetchPolicy.networkOnly));
    });

    test('should contain staleWhileRevalidate', () {
      expect(FetchPolicy.values, contains(FetchPolicy.staleWhileRevalidate));
    });
  });

  group('WritePolicy', () {
    test('should have 4 policy variants', () {
      expect(WritePolicy.values, hasLength(4));
    });

    test('should contain cacheAndNetwork', () {
      expect(WritePolicy.values, contains(WritePolicy.cacheAndNetwork));
    });

    test('should contain networkFirst', () {
      expect(WritePolicy.values, contains(WritePolicy.networkFirst));
    });

    test('should contain cacheFirst', () {
      expect(WritePolicy.values, contains(WritePolicy.cacheFirst));
    });

    test('should contain cacheOnly', () {
      expect(WritePolicy.values, contains(WritePolicy.cacheOnly));
    });
  });

  group('SyncStatus', () {
    test('should have 6 status variants', () {
      expect(SyncStatus.values, hasLength(6));
    });

    test('should contain synced', () {
      expect(SyncStatus.values, contains(SyncStatus.synced));
    });

    test('should contain pending', () {
      expect(SyncStatus.values, contains(SyncStatus.pending));
    });

    test('should contain syncing', () {
      expect(SyncStatus.values, contains(SyncStatus.syncing));
    });

    test('should contain error', () {
      expect(SyncStatus.values, contains(SyncStatus.error));
    });

    test('should contain paused', () {
      expect(SyncStatus.values, contains(SyncStatus.paused));
    });

    test('should contain conflict', () {
      expect(SyncStatus.values, contains(SyncStatus.conflict));
    });
  });

  group('ConflictResolution', () {
    test('should have 6 strategy variants', () {
      expect(ConflictResolution.values, hasLength(6));
    });

    test('should contain serverWins', () {
      expect(
        ConflictResolution.values,
        contains(ConflictResolution.serverWins),
      );
    });

    test('should contain clientWins', () {
      expect(
        ConflictResolution.values,
        contains(ConflictResolution.clientWins),
      );
    });

    test('should contain latestWins', () {
      expect(
        ConflictResolution.values,
        contains(ConflictResolution.latestWins),
      );
    });

    test('should contain merge', () {
      expect(ConflictResolution.values, contains(ConflictResolution.merge));
    });

    test('should contain crdt', () {
      expect(ConflictResolution.values, contains(ConflictResolution.crdt));
    });

    test('should contain custom', () {
      expect(ConflictResolution.values, contains(ConflictResolution.custom));
    });
  });

  group('SyncMode', () {
    test('should have 5 mode variants', () {
      expect(SyncMode.values, hasLength(5));
    });

    test('should contain realtime', () {
      expect(SyncMode.values, contains(SyncMode.realtime));
    });

    test('should contain periodic', () {
      expect(SyncMode.values, contains(SyncMode.periodic));
    });

    test('should contain manual', () {
      expect(SyncMode.values, contains(SyncMode.manual));
    });

    test('should contain eventDriven', () {
      expect(SyncMode.values, contains(SyncMode.eventDriven));
    });

    test('should contain disabled', () {
      expect(SyncMode.values, contains(SyncMode.disabled));
    });
  });
}
