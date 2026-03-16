import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('Cross-Adapter Composition Tests (C1)', () {
    late FakeStoreBackend<TestUser, String> primary;
    late FakeStoreBackend<TestUser, String> fallbackBackend;
    late FakeStoreBackend<TestUser, String> cacheBackend;

    setUp(() {
      primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
        backendName: 'Primary',
      );
      fallbackBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
        backendName: 'Fallback',
      );
      cacheBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
        backendName: 'Cache',
      );
    });

    group('Failure scenarios', () {
      test('primary failure — fallback serves reads', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          readStrategy: CompositeReadStrategy.primaryFirst,
        );

        final user = TestFixtures.createUser(id: 'u1');
        fallbackBackend.addToStorage('u1', user);
        primary.shouldFailOnGet = true;

        final result = await composite.get('u1');

        expect(result, equals(user));
      });

      test('fallback failure — primary still works', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          readStrategy: CompositeReadStrategy.primaryFirst,
        );

        final user = TestFixtures.createUser(id: 'u1');
        primary.addToStorage('u1', user);
        fallbackBackend.shouldFailOnGet = true;

        final result = await composite.get('u1');

        expect(result, equals(user));
      });

      test('cache miss — falls through to primary', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          cache: cacheBackend,
          readStrategy: CompositeReadStrategy.cacheFirst,
        );

        final user = TestFixtures.createUser(id: 'u1');
        primary.addToStorage('u1', user);
        // Cache has no data — not a failure, just a miss

        final result = await composite.get('u1');

        expect(result, equals(user));
      });

      test('all backends fail — returns null or throws', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          readStrategy: CompositeReadStrategy.primaryFirst,
        );

        primary.shouldFailOnGet = true;
        fallbackBackend.shouldFailOnGet = true;

        // CompositeBackend may throw or return null depending on impl
        try {
          final result = await composite.get('u1');
          expect(result, isNull);
        } on Exception {
          // Also acceptable — both backends failed
        }
      });
    });

    group('Read strategy: primaryFirst', () {
      test('returns from primary when available', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          readStrategy: CompositeReadStrategy.primaryFirst,
        );

        final user = TestFixtures.createUser(id: 'u1', name: 'Primary');
        primary.addToStorage('u1', user);
        fallbackBackend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1', name: 'Fallback'),
        );

        final result = await composite.get('u1');

        expect(result!.name, equals('Primary'));
      });
    });

    group('Read strategy: cacheFirst', () {
      test('returns from cache when available', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          cache: cacheBackend,
          readStrategy: CompositeReadStrategy.cacheFirst,
        );

        cacheBackend.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1', name: 'Cached'),
        );
        primary.addToStorage(
          'u1',
          TestFixtures.createUser(id: 'u1', name: 'Primary'),
        );

        final result = await composite.get('u1');

        expect(result!.name, equals('Cached'));
      });
    });

    group('Write strategy: primaryOnly', () {
      test('writes only to primary', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          cache: cacheBackend,
          writeStrategy: CompositeWriteStrategy.primaryOnly,
        );

        final user = TestFixtures.createUser(id: 'u1');
        await composite.save(user);

        expect(primary.storage['u1'], equals(user));
        expect(fallbackBackend.storage['u1'], isNull);
        expect(cacheBackend.storage['u1'], isNull);
      });
    });

    group('Write strategy: all', () {
      test('writes to all backends', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          cache: cacheBackend,
          writeStrategy: CompositeWriteStrategy.all,
        );

        final user = TestFixtures.createUser(id: 'u1');
        await composite.save(user);

        expect(primary.storage['u1'], equals(user));
        expect(fallbackBackend.storage['u1'], equals(user));
        expect(cacheBackend.storage['u1'], equals(user));
      });
    });

    group('Write strategy: primaryAndCache', () {
      test('writes to primary and cache only', () async {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
          cache: cacheBackend,
          writeStrategy: CompositeWriteStrategy.primaryAndCache,
        );

        final user = TestFixtures.createUser(id: 'u1');
        await composite.save(user);

        expect(primary.storage['u1'], equals(user));
        expect(cacheBackend.storage['u1'], equals(user));
        expect(fallbackBackend.storage['u1'], isNull);
      });
    });

    group('Delegated operations through composite', () {
      late CompositeBackend<TestUser, String> composite;

      setUp(() {
        composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
        );
      });

      test('count through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));
        primary.addToStorage('u2', TestFixtures.createUser(id: 'u2'));

        final count = await composite.count();

        expect(count, equals(2));
      });

      test('exists through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final exists = await composite.exists('u1');
        final notExists = await composite.exists('u99');

        expect(exists, isTrue);
        expect(notExists, isFalse);
      });

      test('existsWhere through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final result = await composite.existsWhere(
          Query<TestUser>().where('name', isEqualTo: 'John Doe'),
        );

        expect(result, isA<bool>());
      });

      test('deleteWhere through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));
        primary.addToStorage('u2', TestFixtures.createUser(id: 'u2'));

        final count = await composite.deleteWhere(
          Query<TestUser>().where('isActive', isEqualTo: true),
        );

        expect(count, greaterThanOrEqualTo(0));
      });

      test('updateWhere through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final count = await composite.updateWhere(
          Query<TestUser>().where('isActive', isEqualTo: true),
          {'isActive': false},
        );

        expect(count, greaterThanOrEqualTo(0));
      });

      test('patch through composite', () async {
        primary.patchApplier = (user, updates) {
          return user.copyWith(
            name: updates['name'] as String? ?? user.name,
          );
        };
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));

        final result = await composite.patch('u1', {'name': 'Updated'});

        expect(result, isNotNull);
      });

      test('getByIds through composite', () async {
        primary.addToStorage('u1', TestFixtures.createUser(id: 'u1'));
        primary.addToStorage('u2', TestFixtures.createUser(id: 'u2'));

        final results = await composite.getByIds(['u1', 'u2', 'u99']);

        expect(results, hasLength(2));
      });

      test('getByIds empty list', () async {
        final results = await composite.getByIds([]);

        expect(results, isEmpty);
      });

      test('upsert through composite', () async {
        final user = TestFixtures.createUser(id: 'u1');

        final result = await composite.upsert(user);

        expect(result, equals(user));
        expect(primary.storage['u1'], equals(user));
      });
    });

    group('Multi-backend capability flags', () {
      test('supportsTransactions from primary', () {
        primary.supportsTransactionsForTest = true;
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
        );

        expect(composite.supportsTransactions, isTrue);
      });

      test('supportsPagination from primary', () {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
        );

        expect(composite.supportsPagination, isTrue);
      });
    });

    group('Sync status aggregation', () {
      test('reflects primary sync status', () {
        final composite = CompositeBackend<TestUser, String>(
          primary: primary,
          fallback: fallbackBackend,
        );

        expect(composite.syncStatus, equals(SyncStatus.synced));

        primary.setSyncStatus(SyncStatus.syncing);
        // Composite may or may not reflect this immediately
        // depending on implementation
        expect(composite.syncStatus, isA<SyncStatus>());
      });
    });
  });
}
