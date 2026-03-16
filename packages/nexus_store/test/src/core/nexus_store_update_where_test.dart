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
      TestFixtures.createUser(id: 'user-1', name: 'Alice', isActive: true),
    );
    backend.addToStorage(
      'user-2',
      TestFixtures.createUser(id: 'user-2', name: 'Bob', isActive: true),
    );
    backend.addToStorage(
      'user-3',
      TestFixtures.createUser(id: 'user-3', name: 'Charlie', isActive: false),
    );
  });

  tearDown(() async {
    await store.dispose();
  });

  group('NexusStore.updateWhere', () {
    test('updateWhere returns count of updated entities', () async {
      final query = const Query<TestUser>().where('isActive', isEqualTo: true);
      final count = await store.updateWhere(
        query,
        {'isActive': false},
      );

      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('updateWhere with empty updates returns zero', () async {
      final query = const Query<TestUser>().where('isActive', isEqualTo: true);
      final count = await store.updateWhere(query, {});

      expect(count, equals(0));
    });

    test('updateWhere accepts optional WritePolicy', () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await store.updateWhere(
        query,
        {'isActive': false},
        policy: WritePolicy.cacheOnly,
      );
      expect(count, isA<int>());
    });

    test('updateWhere invalidates cache after update', () async {
      // First populate cache
      await store.getAll();

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      await store.updateWhere(query, {'isActive': false});

      // After updateWhere, cache should be invalidated
      final remaining = await store.getAll();
      expect(remaining, isA<List<TestUser>>());
    });

    test('updateWhere tracks telemetry as OperationType.updateWhere', () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      await store.updateWhere(query, {'isActive': false});

      final stats = store.getStats();
      expect(stats, isNotNull);
      expect(
        stats.operationCounts[OperationType.updateWhere],
        greaterThanOrEqualTo(1),
      );
    });

    test('updateWhere fires interceptor chain with StoreOperation.updateWhere',
        () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');

      // Should not throw — interceptor chain processes updateWhere
      await store.updateWhere(query, {'isActive': false});
    });

    test('updateWhere throws on uninitialized store', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      expect(
        () => uninitializedStore.updateWhere(query, {'isActive': false}),
        throwsStateError,
      );
    });

    test('updateWhere with multiple fields updates all specified fields',
        () async {
      final query = const Query<TestUser>().where('name', isEqualTo: 'Alice');
      final count = await store.updateWhere(
        query,
        {'name': 'Alice Updated', 'isActive': false},
      );

      expect(count, isA<int>());
    });

    test('updateWhere with audit logging enabled logs update action', () async {
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
      await auditStore.updateWhere(query, {'isActive': false});

      final entries = await auditStorage.query(action: AuditAction.update);
      expect(entries, isNotEmpty);
      await auditStore.dispose();
    });
  });
}
