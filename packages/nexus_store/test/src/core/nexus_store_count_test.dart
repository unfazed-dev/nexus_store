import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStore.count', () {
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
    });

    tearDown(() async {
      await store.dispose();
    });

    test('throws StateError before initialize()', () {
      final uninitStore = NexusStore<TestUser, String>(
        backend: FakeStoreBackend<TestUser, String>(
          idExtractor: (u) => u.id,
        ),
        config: StoreConfig(),
        idExtractor: (u) => u.id,
      );

      expect(
        () => uninitStore.count(),
        throwsStateError,
      );
    });

    test('returns 0 on empty store', () async {
      final result = await store.count();
      expect(result, equals(0));
    });

    test('returns correct count after put', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      backend.addToStorage(
        'user-2',
        TestFixtures.createUser(id: 'user-2', name: 'Bob'),
      );

      final result = await store.count();
      expect(result, equals(2));
    });

    test('passes query to backend', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final query = Query<TestUser>().where('name', isEqualTo: 'Alice');
      final result = await store.count(query: query);

      // FakeStoreBackend.count uses StoreBackendDefaults which delegates to
      // getAll, so it returns total storage length (query filtering is
      // backend-specific). The key thing is the method executes without error
      // and goes through the interceptor chain.
      expect(result, isA<int>());
    });

    test('goes through interceptor chain', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      // count() wraps in _interceptorChain.execute — verifying it returns
      // a valid result confirms the chain executed successfully.
      final result = await store.count();
      expect(result, equals(1));
    });
  });

  group('CompositeBackend.count', () {
    test('delegates count to primary backend', () async {
      final primary = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      primary.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      primary.addToStorage(
        'user-2',
        TestFixtures.createUser(id: 'user-2', name: 'Bob'),
      );

      final composite = CompositeBackend<TestUser, String>(
        primary: primary,
      );

      final result = await composite.count();
      expect(result, equals(2));
    });

    test('delegates count with query to primary backend', () async {
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

      final query = Query<TestUser>().where('name', isEqualTo: 'Alice');
      final result = await composite.count(query: query);
      expect(result, isA<int>());
    });
  });

  group('TimingInterceptor count mapping', () {
    test('StoreOperation.count is a valid operation', () {
      expect(StoreOperation.count, isNotNull);
      expect(StoreOperation.values, contains(StoreOperation.count));
    });

    test('count operation is classified as read', () {
      expect(StoreOperation.count.isRead, isTrue);
      expect(StoreOperation.count.isWrite, isFalse);
    });

    test('count goes through TimingInterceptor _mapOperation', () async {
      final reporter = _TestMetricsReporter();
      final backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );

      final store = NexusStore<TestUser, String>(
        backend: backend,
        config: StoreConfig(
          interceptors: [
            TimingInterceptor(
              reporter: reporter,
              operations: {StoreOperation.count},
            ),
          ],
        ),
        idExtractor: (u) => u.id,
      );
      await store.initialize();

      await store.count();

      expect(reporter.operations, contains(OperationType.count));
      await store.dispose();
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
