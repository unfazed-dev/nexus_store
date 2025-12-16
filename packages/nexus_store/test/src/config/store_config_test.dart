import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('StoreConfig', () {
    group('default constructor', () {
      test('should have cacheFirst as default fetchPolicy', () {
        const config = StoreConfig();
        expect(config.fetchPolicy, equals(FetchPolicy.cacheFirst));
      });

      test('should have cacheAndNetwork as default writePolicy', () {
        const config = StoreConfig();
        expect(config.writePolicy, equals(WritePolicy.cacheAndNetwork));
      });

      test('should have realtime as default syncMode', () {
        const config = StoreConfig();
        expect(config.syncMode, equals(SyncMode.realtime));
      });

      test('should have serverWins as default conflictResolution', () {
        const config = StoreConfig();
        expect(
          config.conflictResolution,
          equals(ConflictResolution.serverWins),
        );
      });

      test('should have RetryConfig.defaults as default retryConfig', () {
        const config = StoreConfig();
        expect(config.retryConfig, equals(RetryConfig.defaults));
      });

      test('should have EncryptionConfig.none() as default encryption', () {
        const config = StoreConfig();
        expect(config.encryption, isA<EncryptionNone>());
      });

      test('should have enableAuditLogging as false by default', () {
        const config = StoreConfig();
        expect(config.enableAuditLogging, isFalse);
      });

      test('should have enableGdpr as false by default', () {
        const config = StoreConfig();
        expect(config.enableGdpr, isFalse);
      });

      test('should have staleDuration as null by default', () {
        const config = StoreConfig();
        expect(config.staleDuration, isNull);
      });

      test('should have syncInterval as null by default', () {
        const config = StoreConfig();
        expect(config.syncInterval, isNull);
      });

      test('should have tableName as null by default', () {
        const config = StoreConfig();
        expect(config.tableName, isNull);
      });
    });

    group('defaults preset', () {
      test('should match default constructor', () {
        expect(StoreConfig.defaults, equals(const StoreConfig()));
      });
    });

    group('offlineFirst preset', () {
      test('should have cacheFirst as fetchPolicy', () {
        expect(
          StoreConfig.offlineFirst.fetchPolicy,
          equals(FetchPolicy.cacheFirst),
        );
      });

      test('should have cacheFirst as writePolicy', () {
        expect(
          StoreConfig.offlineFirst.writePolicy,
          equals(WritePolicy.cacheFirst),
        );
      });

      test('should have eventDriven as syncMode', () {
        expect(
          StoreConfig.offlineFirst.syncMode,
          equals(SyncMode.eventDriven),
        );
      });
    });

    group('onlineOnly preset', () {
      test('should have networkOnly as fetchPolicy', () {
        expect(
          StoreConfig.onlineOnly.fetchPolicy,
          equals(FetchPolicy.networkOnly),
        );
      });

      test('should have networkFirst as writePolicy', () {
        expect(
          StoreConfig.onlineOnly.writePolicy,
          equals(WritePolicy.networkFirst),
        );
      });

      test('should have disabled as syncMode', () {
        expect(
          StoreConfig.onlineOnly.syncMode,
          equals(SyncMode.disabled),
        );
      });
    });

    group('realtime preset', () {
      test('should have cacheAndNetwork as fetchPolicy', () {
        expect(
          StoreConfig.realtime.fetchPolicy,
          equals(FetchPolicy.cacheAndNetwork),
        );
      });

      test('should have cacheAndNetwork as writePolicy', () {
        expect(
          StoreConfig.realtime.writePolicy,
          equals(WritePolicy.cacheAndNetwork),
        );
      });

      test('should have realtime as syncMode', () {
        expect(
          StoreConfig.realtime.syncMode,
          equals(SyncMode.realtime),
        );
      });
    });

    group('copyWith', () {
      test('should create new instance with changed fetchPolicy', () {
        const original = StoreConfig();
        final modified = original.copyWith(
          fetchPolicy: FetchPolicy.networkOnly,
        );

        expect(modified.fetchPolicy, equals(FetchPolicy.networkOnly));
        expect(original.fetchPolicy, equals(FetchPolicy.cacheFirst));
      });

      test('should create new instance with changed writePolicy', () {
        const original = StoreConfig();
        final modified = original.copyWith(writePolicy: WritePolicy.cacheOnly);

        expect(modified.writePolicy, equals(WritePolicy.cacheOnly));
        expect(original.writePolicy, equals(WritePolicy.cacheAndNetwork));
      });

      test('should create new instance with changed enableAuditLogging', () {
        const original = StoreConfig();
        final modified = original.copyWith(enableAuditLogging: true);

        expect(modified.enableAuditLogging, isTrue);
        expect(original.enableAuditLogging, isFalse);
      });

      test('should create new instance with changed staleDuration', () {
        const original = StoreConfig();
        final modified = original.copyWith(
          staleDuration: const Duration(minutes: 5),
        );

        expect(modified.staleDuration, equals(const Duration(minutes: 5)));
        expect(original.staleDuration, isNull);
      });

      test('should create new instance with changed tableName', () {
        const original = StoreConfig();
        final modified = original.copyWith(tableName: 'custom_table');

        expect(modified.tableName, equals('custom_table'));
        expect(original.tableName, isNull);
      });

      test('should preserve unchanged values', () {
        const original = StoreConfig(
          fetchPolicy: FetchPolicy.networkFirst,
          enableAuditLogging: true,
        );
        final modified = original.copyWith(writePolicy: WritePolicy.cacheOnly);

        expect(modified.fetchPolicy, equals(FetchPolicy.networkFirst));
        expect(modified.enableAuditLogging, isTrue);
        expect(modified.writePolicy, equals(WritePolicy.cacheOnly));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        const config1 = StoreConfig();
        const config2 = StoreConfig();

        expect(config1, equals(config2));
      });

      test('should not be equal when fetchPolicy differs', () {
        const config1 = StoreConfig();
        const config2 = StoreConfig(fetchPolicy: FetchPolicy.networkFirst);

        expect(config1, isNot(equals(config2)));
      });

      test('should have same hashCode for equal configs', () {
        const config1 = StoreConfig();
        const config2 = StoreConfig();

        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });
}
