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
    handler = WritePolicyHandler<TestUser, String>(
      backend: backend,
      defaultPolicy: WritePolicy.cacheOnly,
    );

    // Seed data
    backend.addToStorage(
      'user-1',
      TestFixtures.createUser(id: 'user-1', name: 'Alice'),
    );
  });

  group('WritePolicyHandler.upsert', () {
    test('upsert with cacheOnly policy delegates to backend', () async {
      final newUser = TestFixtures.createUser(id: 'user-new', name: 'New');

      final result = await handler.upsert(newUser);

      expect(result, isNotNull);
      expect(result.name, equals('New'));
    });

    test('upsert with cacheAndNetwork policy syncs after save', () async {
      final handler2 = WritePolicyHandler<TestUser, String>(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      final newUser = TestFixtures.createUser(id: 'user-sync', name: 'Sync');

      final result = await handler2.upsert(newUser);

      expect(result, isNotNull);
      expect(result.name, equals('Sync'));
    });

    test('upsert with networkFirst policy waits for sync', () async {
      final handler3 = WritePolicyHandler<TestUser, String>(
        backend: backend,
        defaultPolicy: WritePolicy.networkFirst,
      );
      final newUser = TestFixtures.createUser(id: 'user-net', name: 'Network');

      final result = await handler3.upsert(newUser);

      expect(result, isNotNull);
      expect(result.name, equals('Network'));
    });

    test('upsert with cacheFirst policy does background sync', () async {
      final handler4 = WritePolicyHandler<TestUser, String>(
        backend: backend,
        defaultPolicy: WritePolicy.cacheFirst,
      );
      final newUser = TestFixtures.createUser(id: 'user-cf', name: 'CacheF');

      final result = await handler4.upsert(newUser);

      expect(result, isNotNull);
      expect(result.name, equals('CacheF'));
    });

    test('upsert with explicit policy override', () async {
      final newUser = TestFixtures.createUser(id: 'user-ov', name: 'Override');

      final result = await handler.upsert(
        newUser,
        policy: WritePolicy.cacheOnly,
      );

      expect(result, isNotNull);
      expect(result.name, equals('Override'));
    });
  });

  group('WritePolicyHandler.upsertAll', () {
    test('upsertAll with cacheOnly policy delegates to backend', () async {
      final items = [
        TestFixtures.createUser(id: 'user-a', name: 'A'),
        TestFixtures.createUser(id: 'user-b', name: 'B'),
      ];

      final results = await handler.upsertAll(items);

      expect(results, hasLength(2));
    });

    test('upsertAll with cacheAndNetwork policy syncs after save', () async {
      final handler2 = WritePolicyHandler<TestUser, String>(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      final items = [
        TestFixtures.createUser(id: 'user-s1', name: 'Sync1'),
      ];

      final results = await handler2.upsertAll(items);

      expect(results, hasLength(1));
    });

    test('upsertAll with explicit policy override', () async {
      final items = [
        TestFixtures.createUser(id: 'user-o1', name: 'Ov1'),
      ];

      final results = await handler.upsertAll(
        items,
        policy: WritePolicy.cacheOnly,
      );

      expect(results, hasLength(1));
    });
  });
}
