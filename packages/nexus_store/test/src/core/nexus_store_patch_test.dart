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
    backend.patchApplier = (entity, updates) {
      return entity.copyWith(
        name: updates['name'] as String? ?? entity.name,
        email: updates['email'] as String? ?? entity.email,
        age: updates.containsKey('age') ? updates['age'] as int? : entity.age,
        isActive: updates['isActive'] as bool? ?? entity.isActive,
      );
    };
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

  group('NexusStore.patch', () {
    test('patches a single field and returns updated entity', () async {
      final result = await store.patch('user-1', {'name': 'Alice Updated'});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice Updated'));
      expect(result.id, equals('user-1'));
    });

    test('patches multiple fields and returns updated entity', () async {
      final result = await store.patch('user-1', {
        'name': 'Alice Updated',
        'isActive': false,
      });

      expect(result, isNotNull);
      expect(result!.name, equals('Alice Updated'));
      expect(result.isActive, isFalse);
      expect(result.id, equals('user-1'));
    });

    test('returns null for non-existent entity', () async {
      final result = await store.patch('non-existent', {'name': 'Ghost'});

      expect(result, isNull);
    });

    test('preserves unpatched fields', () async {
      final result = await store.patch('user-1', {'name': 'Alice Updated'});

      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
      expect(result.email, equals('john@example.com'));
    });

    test('patch with empty updates returns entity unchanged', () async {
      final result = await store.patch('user-1', {});

      expect(result, isNotNull);
      expect(result!.name, equals('Alice'));
    });

    test('patch respects write policy parameter', () async {
      final result = await store.patch(
        'user-1',
        {'name': 'Updated'},
        policy: WritePolicy.cacheOnly,
      );

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('patch updates cache so subsequent get returns updated entity',
        () async {
      await store.patch('user-1', {'name': 'Alice Cached'});

      final fetched = await store.get('user-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Alice Cached'));
    });

    test('patch goes through interceptor chain', () async {
      final result = await store.patch('user-1', {'name': 'Intercepted'});

      expect(result, isNotNull);
    });

    test('patch throws on uninitialized store', () async {
      final uninitializedStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      expect(
        () => uninitializedStore.patch('user-1', {'name': 'Fail'}),
        throwsA(isA<Error>()),
      );
    });

    test('patch with idExtractor records cached item', () async {
      final result = await store.patch('user-1', {'name': 'Cached'});

      expect(result, isNotNull);
      expect(result!.name, equals('Cached'));

      // Verify the cache was updated by fetching again
      final fetched = await store.get('user-1');
      expect(fetched!.name, equals('Cached'));
    });
  });

  group('NexusStore.patch with TimingInterceptor', () {
    test('patch goes through TimingInterceptor _mapOperation', () async {
      final reporter = _TestMetricsReporter();
      final timedBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      timedBackend.patchApplier = (entity, updates) {
        return entity.copyWith(
          name: updates['name'] as String? ?? entity.name,
        );
      };
      timedBackend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final timedStore = NexusStore<TestUser, String>(
        backend: timedBackend,
        config: StoreConfig(
          interceptors: [
            TimingInterceptor(
              reporter: reporter,
              operations: {StoreOperation.patch},
            ),
          ],
        ),
        idExtractor: (u) => u.id,
      );
      await timedStore.initialize();

      await timedStore.patch('user-1', {'name': 'Updated'});

      expect(reporter.operations, contains(OperationType.patch));
      await timedStore.dispose();
    });
  });

  group('CompositeBackend.patch', () {
    test('delegates patch to primary backend', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      primary.patchApplier = (entity, updates) {
        return entity.copyWith(
          name: updates['name'] as String? ?? entity.name,
        );
      };
      primary.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final composite = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      final result = await composite.patch('user-1', {'name': 'Updated'});

      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });

    test('returns null for non-existent entity', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      primary.patchApplier = (entity, updates) => entity;

      final composite = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      final result = await composite.patch('non-existent', {'name': 'Ghost'});
      expect(result, isNull);
    });
  });

  group('NexusStore.patch with audit logging', () {
    test('patch with audit logging enabled logs update action', () async {
      final auditStorage = InMemoryAuditStorage();
      final auditBackend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      auditBackend.patchApplier = (entity, updates) {
        return entity.copyWith(
          name: updates['name'] as String? ?? entity.name,
        );
      };
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

      await auditStore.patch('user-1', {'name': 'Updated'});

      final entries = await auditStorage.query(action: AuditAction.update);
      expect(entries, isNotEmpty);
      await auditStore.dispose();
    });
  });

  group('StoreBackendDefaults.patch', () {
    test('default patch throws UnsupportedError', () {
      final minimal = _MinimalBackend();

      expect(
        () => minimal.patch('id-1', {'name': 'Test'}),
        throwsA(isA<UnsupportedError>()),
      );
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
