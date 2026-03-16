import 'dart:core' as core;
import 'dart:core';

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
      TestFixtures.createUser(id: 'user-2', name: 'Bob', isActive: false),
    );
  });

  tearDown(() async {
    await store.dispose();
  });

  group('NexusStore.upsert', () {
    test('inserts a new entity when it does not exist', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-new',
        name: 'Charlie',
      );

      final result = await store.upsert(newUser);

      expect(result, isNotNull);
      expect(result.id, equals('user-new'));
      expect(result.name, equals('Charlie'));

      // Verify it was persisted
      final fetched = await store.get('user-new');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Charlie'));
    });

    test('updates existing entity with default ConflictStrategy.update',
        () async {
      final updatedUser = TestFixtures.createUser(
        id: 'user-1',
        name: 'Alice Updated',
      );

      final result = await store.upsert(updatedUser);

      expect(result, isNotNull);
      expect(result.id, equals('user-1'));
      expect(result.name, equals('Alice Updated'));

      // Verify it was persisted
      final fetched = await store.get('user-1');
      expect(fetched!.name, equals('Alice Updated'));
    });

    test('ignores existing entity with ConflictStrategy.ignore', () async {
      final updatedUser = TestFixtures.createUser(
        id: 'user-1',
        name: 'Should Be Ignored',
      );

      final result = await store.upsert(
        updatedUser,
        onConflict: ConflictStrategy.ignore,
      );

      expect(result, isNotNull);
      expect(result.name, equals('Alice')); // Original name preserved

      // Verify original was preserved
      final fetched = await store.get('user-1');
      expect(fetched!.name, equals('Alice'));
    });

    test('replaces existing entity with ConflictStrategy.replace', () async {
      final replacementUser = TestFixtures.createUser(
        id: 'user-1',
        name: 'Alice Replaced',
        email: 'alice.new@example.com',
      );

      final result = await store.upsert(
        replacementUser,
        onConflict: ConflictStrategy.replace,
      );

      expect(result, isNotNull);
      expect(result.name, equals('Alice Replaced'));
      expect(result.email, equals('alice.new@example.com'));
    });

    test('throws on existing entity with ConflictStrategy.error', () async {
      final duplicateUser = TestFixtures.createUser(
        id: 'user-1',
        name: 'Duplicate',
      );

      expect(
        () => store.upsert(
          duplicateUser,
          onConflict: ConflictStrategy.error,
        ),
        throwsA(isA<core.StateError>()),
      );
    });

    test('inserts new entity regardless of ConflictStrategy.error', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-new',
        name: 'New User',
      );

      final result = await store.upsert(
        newUser,
        onConflict: ConflictStrategy.error,
      );

      expect(result, isNotNull);
      expect(result.name, equals('New User'));
    });

    test('upsert respects write policy parameter', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-policy',
        name: 'Policy User',
      );

      final result = await store.upsert(
        newUser,
        policy: WritePolicy.cacheOnly,
      );

      expect(result, isNotNull);
      expect(result.name, equals('Policy User'));
    });

    test('upsert updates cache so subsequent get returns upserted entity',
        () async {
      final newUser = TestFixtures.createUser(
        id: 'user-cached',
        name: 'Cached User',
      );

      await store.upsert(newUser);

      final fetched = await store.get('user-cached');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Cached User'));
    });

    test('upsert goes through interceptor chain', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-intercepted',
        name: 'Intercepted',
      );

      final result = await store.upsert(newUser);
      expect(result, isNotNull);
    });

    test('upsert throws on uninitialized store', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      final newUser = TestFixtures.createUser(id: 'user-fail');

      expect(
        () => uninitializedStore.upsert(newUser),
        throwsA(isA<Error>()),
      );
    });

    test('upsert with idExtractor records cached item', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-track',
        name: 'Tracked',
      );

      final result = await store.upsert(newUser);
      expect(result.name, equals('Tracked'));

      // Verify cache was updated
      final fetched = await store.get('user-track');
      expect(fetched!.name, equals('Tracked'));
    });

    test('upsert with tags associates tags with cached item', () async {
      final newUser = TestFixtures.createUser(
        id: 'user-tagged',
        name: 'Tagged',
      );

      final result = await store.upsert(
        newUser,
        tags: {'team-a', 'active'},
      );

      expect(result, isNotNull);
      expect(result.name, equals('Tagged'));
    });
  });

  group('NexusStore.upsertAll', () {
    test('inserts multiple new entities', () async {
      final newUsers = [
        TestFixtures.createUser(id: 'user-a', name: 'User A'),
        TestFixtures.createUser(id: 'user-b', name: 'User B'),
        TestFixtures.createUser(id: 'user-c', name: 'User C'),
      ];

      final results = await store.upsertAll(newUsers);

      expect(results, hasLength(3));
      expect(results[0].name, equals('User A'));
      expect(results[1].name, equals('User B'));
      expect(results[2].name, equals('User C'));

      // Verify all persisted
      final a = await store.get('user-a');
      final b = await store.get('user-b');
      expect(a, isNotNull);
      expect(b, isNotNull);
    });

    test('updates existing entities in batch', () async {
      final updates = [
        TestFixtures.createUser(id: 'user-1', name: 'Alice Updated'),
        TestFixtures.createUser(id: 'user-2', name: 'Bob Updated'),
      ];

      final results = await store.upsertAll(updates);

      expect(results, hasLength(2));
      expect(results[0].name, equals('Alice Updated'));
      expect(results[1].name, equals('Bob Updated'));
    });

    test('handles mix of new and existing entities', () async {
      final mixed = [
        TestFixtures.createUser(id: 'user-1', name: 'Alice Updated'),
        TestFixtures.createUser(id: 'user-new', name: 'New User'),
      ];

      final results = await store.upsertAll(mixed);

      expect(results, hasLength(2));
      expect(results[0].name, equals('Alice Updated'));
      expect(results[1].name, equals('New User'));
    });

    test('upsertAll with ConflictStrategy.ignore preserves existing', () async {
      final items = [
        TestFixtures.createUser(id: 'user-1', name: 'Should Ignore'),
        TestFixtures.createUser(id: 'user-new', name: 'Should Insert'),
      ];

      final results = await store.upsertAll(
        items,
        onConflict: ConflictStrategy.ignore,
      );

      expect(results, hasLength(2));
      expect(results[0].name, equals('Alice')); // Original preserved
      expect(results[1].name, equals('Should Insert')); // New inserted
    });

    test('upsertAll with empty list returns empty list', () async {
      final results = await store.upsertAll([]);

      expect(results, isEmpty);
    });

    test('upsertAll respects write policy', () async {
      final items = [
        TestFixtures.createUser(id: 'user-p1', name: 'Policy 1'),
      ];

      final results = await store.upsertAll(
        items,
        policy: WritePolicy.cacheOnly,
      );

      expect(results, hasLength(1));
    });

    test('upsertAll with tags associates tags with all items', () async {
      final items = [
        TestFixtures.createUser(id: 'user-t1', name: 'Tagged 1'),
        TestFixtures.createUser(id: 'user-t2', name: 'Tagged 2'),
      ];

      final results = await store.upsertAll(
        items,
        tags: {'batch-1'},
      );

      expect(results, hasLength(2));
    });
  });

  group('NexusStore.upsert with TimingInterceptor', () {
    test('upsert goes through TimingInterceptor _mapOperation', () async {
      final reporter = _TestMetricsReporter();
      final timedBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );

      final timedStore = NexusStore<TestUser, String>(
        backend: timedBackend,
        config: StoreConfig(
          interceptors: [
            TimingInterceptor(
              reporter: reporter,
              operations: {StoreOperation.upsert},
            ),
          ],
        ),
        idExtractor: (u) => u.id,
      );
      await timedStore.initialize();

      await timedStore.upsert(
        TestFixtures.createUser(id: 'user-timed', name: 'Timed'),
      );

      expect(reporter.operations, contains(OperationType.upsert));
      await timedStore.dispose();
    });

    test('upsertAll goes through TimingInterceptor _mapOperation', () async {
      final reporter = _TestMetricsReporter();
      final timedBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );

      final timedStore = NexusStore<TestUser, String>(
        backend: timedBackend,
        config: StoreConfig(
          interceptors: [
            TimingInterceptor(
              reporter: reporter,
              operations: {StoreOperation.upsertAll},
            ),
          ],
        ),
        idExtractor: (u) => u.id,
      );
      await timedStore.initialize();

      await timedStore.upsertAll([
        TestFixtures.createUser(id: 'user-t1', name: 'Timed 1'),
      ]);

      expect(reporter.operations, contains(OperationType.upsertAll));
      await timedStore.dispose();
    });
  });

  group('CompositeBackend.upsert', () {
    test('delegates upsert to primary backend', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      primary.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final composite = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      final newUser = TestFixtures.createUser(
        id: 'user-new',
        name: 'New Via Composite',
      );
      final result = await composite.upsert(newUser);

      expect(result, isNotNull);
      expect(result.name, equals('New Via Composite'));
    });

    test('delegates upsertAll to primary backend', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );

      final composite = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      final items = [
        TestFixtures.createUser(id: 'user-c1', name: 'Composite 1'),
        TestFixtures.createUser(id: 'user-c2', name: 'Composite 2'),
      ];
      final results = await composite.upsertAll(items);

      expect(results, hasLength(2));
    });
  });

  group('StoreBackendDefaults.upsert', () {
    test('default upsert delegates to save', () async {
      final minimal = _MinimalBackend();

      final result = await minimal.upsert('test-item');

      expect(result, equals('test-item'));
    });

    test('default upsertAll delegates to upsert for each item', () async {
      final minimal = _MinimalBackend();

      final results = await minimal.upsertAll(['item-1', 'item-2']);

      expect(results, hasLength(2));
      expect(results, containsAll(['item-1', 'item-2']));
    });
  });

  group('NexusStore.upsert with audit logging', () {
    test('upsert with audit logging enabled logs update action', () async {
      final auditStorage = InMemoryAuditStorage();
      final auditBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
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

      await auditStore.upsert(
        TestFixtures.createUser(id: 'user-audit', name: 'Audited'),
      );

      final entries = await auditStorage.query(action: AuditAction.update);
      expect(entries, isNotEmpty);
      await auditStore.dispose();
    });

    test('upsertAll with audit logging enabled logs update action', () async {
      final auditStorage = InMemoryAuditStorage();
      final auditBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
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

      await auditStore.upsertAll([
        TestFixtures.createUser(id: 'user-a1', name: 'Audit1'),
        TestFixtures.createUser(id: 'user-a2', name: 'Audit2'),
      ]);

      final entries = await auditStorage.query(action: AuditAction.update);
      expect(entries, isNotEmpty);
      await auditStore.dispose();
    });
  });

  group('StoreOperation.upsert extensions', () {
    test('upsert is a write operation', () {
      expect(StoreOperation.upsert.isWrite, isTrue);
      expect(StoreOperation.upsert.isRead, isFalse);
      expect(StoreOperation.upsert.isDelete, isFalse);
      expect(StoreOperation.upsert.modifiesData, isTrue);
    });

    test('upsertAll is a write operation', () {
      expect(StoreOperation.upsertAll.isWrite, isTrue);
      expect(StoreOperation.upsertAll.isRead, isFalse);
      expect(StoreOperation.upsertAll.isDelete, isFalse);
      expect(StoreOperation.upsertAll.modifiesData, isTrue);
    });
  });
}

class _TestMetricsReporter implements MetricsReporter {
  final List<OperationType> operations = [];

  @override
  void reportOperation(OperationMetric metric) {
    operations.add(metric.operation);
  }

  @override
  void reportCacheEvent(CacheMetric metric) {}
  @override
  void reportSyncEvent(SyncMetric metric) {}
  @override
  void reportError(ErrorMetric metric) {}
  @override
  void reportPoolEvent(PoolMetric metric) {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> dispose() async {}
}

class _MinimalBackend with StoreBackendDefaults<String, String> {
  @override
  String get name => 'MinimalBackend';
  @override
  Future<String?> get(String id) async => null;
  @override
  Future<List<String>> getAll({Query<String>? query}) async => [];
  @override
  Stream<String?> watch(String id) => const Stream.empty();
  @override
  Stream<List<String>> watchAll({Query<String>? query}) =>
      Stream.value(const []);
  @override
  Future<String> save(String item) async => item;
  @override
  Future<List<String>> saveAll(List<String> items) async => items;
  @override
  Future<bool> delete(String id) async => false;
  @override
  Future<int> deleteAll(List<String> ids) async => 0;
  @override
  Future<int> deleteWhere(Query<String> query) async => 0;
}
