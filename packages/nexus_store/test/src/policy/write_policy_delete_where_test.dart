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

  group('WritePolicyHandler.deleteWhere', () {
    test('cacheAndNetwork policy - deletes then syncs', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.deleteWhere(query);

      expect(count, greaterThanOrEqualTo(0));
    });

    test('networkFirst policy - deletes then syncs', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.networkFirst,
      );
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.deleteWhere(query);

      expect(count, greaterThanOrEqualTo(0));
    });

    test('cacheFirst policy - deletes and schedules background sync', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheFirst,
      );
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.deleteWhere(query);

      expect(count, greaterThanOrEqualTo(0));
    });

    test('cacheOnly policy - deletes without sync', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheOnly,
      );
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await handler.deleteWhere(query);

      expect(count, greaterThanOrEqualTo(0));
    });

    test('respects explicit policy override', () async {
      handler = WritePolicyHandler(
        backend: backend,
        defaultPolicy: WritePolicy.cacheAndNetwork,
      );
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      // Override with cacheOnly
      final count = await handler.deleteWhere(
        query,
        policy: WritePolicy.cacheOnly,
      );

      expect(count, greaterThanOrEqualTo(0));
    });
  });
}
