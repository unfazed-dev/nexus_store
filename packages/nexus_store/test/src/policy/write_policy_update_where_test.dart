import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  late FakeStoreBackend<TestUser, String> backend;
  late WritePolicyHandler<TestUser, String> handler;

  setUp(() {
    backend = FakeStoreBackend<TestUser, String>(
      idExtractor: (u) => u.id,
    );
    handler = WritePolicyHandler(
      backend: backend,
      defaultPolicy: WritePolicy.cacheOnly,
    );
  });

  group('WritePolicyHandler.updateWhere', () {
    test('updateWhere with default policy', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.updateWhere(query, {'isActive': false});

      expect(count, isA<int>());
    });

    test('updateWhere with cacheOnly policy', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.updateWhere(
        query,
        {'isActive': false},
        policy: WritePolicy.cacheOnly,
      );

      expect(count, isA<int>());
    });

    test('updateWhere with cacheAndNetwork policy triggers sync', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.updateWhere(
        query,
        {'isActive': false},
        policy: WritePolicy.cacheAndNetwork,
      );

      expect(count, isA<int>());
    });

    test('updateWhere with networkFirst policy waits for sync', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.updateWhere(
        query,
        {'isActive': false},
        policy: WritePolicy.networkFirst,
      );

      expect(count, isA<int>());
    });

    test('updateWhere with cacheFirst policy schedules background sync',
        () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.updateWhere(
        query,
        {'isActive': false},
        policy: WritePolicy.cacheFirst,
      );

      expect(count, isA<int>());
    });

    test('cacheAndNetwork rethrows StoreError when sync fails', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      backend.shouldFailOnSync = true;
      backend.errorToThrow = const SyncError(message: 'Sync failed');

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');

      expect(
        () => handler.updateWhere(
          query,
          {'isActive': false},
          policy: WritePolicy.cacheAndNetwork,
        ),
        throwsA(isA<StoreError>()),
      );
    });
  });
}
