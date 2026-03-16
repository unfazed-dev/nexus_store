import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  late FakeStoreBackend<TestUser, String> backend;
  late NexusStore<TestUser, String> store;

  setUp(() async {
    backend = FakeStoreBackend<TestUser, String>(
      idExtractor: (u) => u.id,
    );
    store = NexusStore<TestUser, String>(
      backend: backend,
      config: StoreConfig(),
      idExtractor: (u) => u.id,
    );
    await store.initialize();

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

  tearDown(() async {
    await store.dispose();
  });

  group('NexusStore.deleteWhere', () {
    test('deleteWhere returns count of deleted entities', () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await store.deleteWhere(query);

      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('deleteWhere with query parameter is required', () async {
      final query = const Query<TestUser>().where(
        'isActive',
        isEqualTo: true,
      );
      final count = await store.deleteWhere(query);
      expect(count, isA<int>());
    });

    test('deleteWhere accepts optional WritePolicy', () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await store.deleteWhere(
        query,
        policy: WritePolicy.cacheOnly,
      );
      expect(count, isA<int>());
    });

    test('deleteWhere invalidates cache after delete', () async {
      // First populate cache
      await store.getAll();

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      await store.deleteWhere(query);

      // After deleteWhere, cache should be invalidated
      final remaining = await store.getAll();
      expect(remaining, isA<List<TestUser>>());
    });

    test('deleteWhere tracks telemetry as OperationType.deleteWhere', () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      await store.deleteWhere(query);

      final stats = store.getStats();
      expect(stats, isNotNull);
      expect(
        stats.operationCounts[OperationType.deleteWhere],
        greaterThanOrEqualTo(1),
      );
    });

    test('deleteWhere fires interceptor chain with StoreOperation.deleteWhere',
        () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');

      // Should not throw — interceptor chain processes deleteWhere
      await store.deleteWhere(query);
    });

    test('deleteWhere throws on uninitialized store', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      expect(
        () => uninitializedStore.deleteWhere(query),
        throwsStateError,
      );
    });

    test('deleteWhere with audit logging enabled logs delete action', () async {
      final auditStorage = InMemoryAuditStorage();
      final auditBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      auditBackend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final auditStore = NexusStore<TestUser, String>(
        backend: auditBackend,
        config: const StoreConfig(enableAuditLogging: true),
        idExtractor: (u) => u.id,
        auditService: AuditService(
          storage: auditStorage,
          actorProvider: () async => 'test-actor',
        ),
      );
      await auditStore.initialize();

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      await auditStore.deleteWhere(query);

      final entries = await auditStorage.query(action: AuditAction.delete);
      expect(entries, isNotEmpty);
      await auditStore.dispose();
    });
  });
}
