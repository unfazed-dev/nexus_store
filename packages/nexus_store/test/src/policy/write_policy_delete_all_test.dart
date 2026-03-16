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
    // Seed data
    backend.addToStorage(
      'user-1',
      TestFixtures.createUser(id: 'user-1', name: 'Alice'),
    );
    backend.addToStorage(
      'user-2',
      TestFixtures.createUser(id: 'user-2', name: 'Bob'),
    );
    backend.addToStorage(
      'user-3',
      TestFixtures.createUser(id: 'user-3', name: 'Charlie'),
    );
  });

  group('WritePolicyHandler.deleteAll', () {
    test('cacheAndNetwork policy - deletes then syncs', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      final count = await handler.deleteAll(
        ['user-1', 'user-2'],
      );

      expect(count, equals(2));
    });

    test('networkFirst policy - deletes then syncs', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.networkFirst,
      );
      final count = await handler.deleteAll(
        ['user-1', 'user-2'],
      );

      expect(count, equals(2));
    });

    test('cacheFirst policy - deletes and schedules background sync', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheFirst,
      );
      final count = await handler.deleteAll(
        ['user-1', 'user-2'],
      );

      expect(count, equals(2));
    });

    test('cacheOnly policy - deletes without sync', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheOnly,
      );
      final count = await handler.deleteAll(
        ['user-1', 'user-3'],
      );

      expect(count, equals(2));
    });

    test('respects explicit policy override', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      // Override with cacheOnly
      final count = await handler.deleteAll(
        ['user-1'],
        policy: WritePolicy.cacheOnly,
      );

      expect(count, equals(1));
    });

    test('cacheAndNetwork rethrows StoreError when sync fails', () async {
      backend.shouldFailOnSync = true;
      backend.errorToThrow = const SyncError(message: 'Sync failed');

      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );

      expect(
        () => handler.deleteAll(['user-1']),
        throwsA(isA<StoreError>()),
      );
    });
  });
}
