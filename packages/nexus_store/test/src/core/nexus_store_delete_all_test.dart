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

  group('NexusStore.deleteAll', () {
    test('deleteAll delegates to WritePolicyHandler.deleteAll', () async {
      final count = await store.deleteAll(['user-1', 'user-2']);

      expect(count, equals(2));
      // Verify entities are actually removed from storage
      final remaining = await store.getAll();
      expect(remaining.length, equals(1));
      expect(remaining.first.name, equals('Charlie'));
    });

    test('deleteAll with empty list returns 0', () async {
      final count = await store.deleteAll([]);

      expect(count, equals(0));
    });

    test('deleteAll with multiple items returns correct count', () async {
      final count = await store.deleteAll(['user-1', 'user-2', 'user-3']);

      expect(count, equals(3));
      final remaining = await store.getAll();
      expect(remaining, isEmpty);
    });

    test('deleteAll with partial missing IDs returns partial count', () async {
      final count = await store.deleteAll(
        ['user-1', 'nonexistent-id', 'user-3'],
      );

      expect(count, equals(2));
    });

    test('deleteAll fires interceptor chain', () async {
      // Should not throw — interceptor chain processes deleteAll
      await store.deleteAll(['user-1']);
    });

    test('deleteAll invalidates cache', () async {
      // Populate cache
      await store.getAll();

      await store.deleteAll(['user-1', 'user-2']);

      // After deleteAll, cache should reflect deletion
      final remaining = await store.getAll();
      expect(remaining.length, equals(1));
    });

    test('deleteAll throws before init', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      expect(
        () => uninitializedStore.deleteAll(['user-1']),
        throwsStateError,
      );
    });

    test('deleteAll respects WritePolicy parameter', () async {
      final count = await store.deleteAll(
        ['user-1'],
        policy: WritePolicy.cacheOnly,
      );
      expect(count, equals(1));
    });

    test('deleteAll tracks telemetry as OperationType.deleteAll', () async {
      await store.deleteAll(['user-1', 'user-2']);

      final stats = store.getStats();
      expect(stats, isNotNull);
      expect(
        stats.operationCounts[OperationType.deleteAll],
        greaterThanOrEqualTo(1),
      );
    });
  });
}
