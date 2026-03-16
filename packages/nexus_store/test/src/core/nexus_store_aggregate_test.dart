import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

/// Mock backend that tracks aggregate calls.
class MockAggregateBackend
    with StoreBackendDefaults<Map<String, dynamic>, String> {
  num? aggregateResult;
  String? lastField;
  AggregateType? lastType;
  Query<Map<String, dynamic>>? lastQuery;
  int aggregateCallCount = 0;

  @override
  String get name => 'MockAggregateBackend';

  @override
  Future<Map<String, dynamic>?> get(String id) async => null;

  @override
  Future<List<Map<String, dynamic>>> getAll(
          {Query<Map<String, dynamic>>? query}) async =>
      [];

  @override
  Stream<Map<String, dynamic>?> watch(String id) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAll(
          {Query<Map<String, dynamic>>? query}) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> item) async => item;

  @override
  Future<List<Map<String, dynamic>>> saveAll(
          List<Map<String, dynamic>> items) async =>
      items;

  @override
  Future<bool> delete(String id) async => false;

  @override
  Future<int> deleteAll(List<String> ids) async => 0;

  @override
  Future<int> deleteWhere(Query<Map<String, dynamic>> query) async => 0;

  @override
  Future<num?> aggregate(
    String field,
    AggregateType type, {
    Query<Map<String, dynamic>>? query,
  }) async {
    aggregateCallCount++;
    lastField = field;
    lastType = type;
    lastQuery = query;
    return aggregateResult;
  }
}

void main() {
  group('NexusStore.aggregate', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockAggregateBackend backend;

    setUp(() {
      backend = MockAggregateBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('delegates to backend with correct parameters', () async {
      backend.aggregateResult = 42;

      final result = await store.aggregate('amount', AggregateType.sum);

      expect(result, equals(42));
      expect(backend.lastField, equals('amount'));
      expect(backend.lastType, equals(AggregateType.sum));
      expect(backend.lastQuery, isNull);
    });

    test('passes query to backend', () async {
      backend.aggregateResult = 100;
      final query =
          Query<Map<String, dynamic>>().where('status', isEqualTo: 'active');

      final result = await store.aggregate(
        'amount',
        AggregateType.sum,
        query: query,
      );

      expect(result, equals(100));
      expect(backend.lastQuery, isNotNull);
    });

    test('returns null when backend returns null', () async {
      backend.aggregateResult = null;

      final result = await store.aggregate('amount', AggregateType.sum);

      expect(result, isNull);
    });
  });

  group('NexusStore convenience methods', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockAggregateBackend backend;

    setUp(() {
      backend = MockAggregateBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('sum() delegates with AggregateType.sum', () async {
      backend.aggregateResult = 100;

      final result = await store.sum('amount');

      expect(result, equals(100));
      expect(backend.lastType, equals(AggregateType.sum));
      expect(backend.lastField, equals('amount'));
    });

    test('avg() delegates with AggregateType.avg', () async {
      backend.aggregateResult = 25.5;

      final result = await store.avg('rating');

      expect(result, equals(25.5));
      expect(backend.lastType, equals(AggregateType.avg));
      expect(backend.lastField, equals('rating'));
    });

    test('min() delegates with AggregateType.min', () async {
      backend.aggregateResult = 5;

      final result = await store.min('price');

      expect(result, equals(5));
      expect(backend.lastType, equals(AggregateType.min));
      expect(backend.lastField, equals('price'));
    });

    test('max() delegates with AggregateType.max', () async {
      backend.aggregateResult = 999;

      final result = await store.max('price');

      expect(result, equals(999));
      expect(backend.lastType, equals(AggregateType.max));
      expect(backend.lastField, equals('price'));
    });

    test('sum() passes query parameter', () async {
      backend.aggregateResult = 50;
      final query =
          Query<Map<String, dynamic>>().where('category', isEqualTo: 'food');

      final result = await store.sum('amount', query: query);

      expect(result, equals(50));
      expect(backend.lastQuery, isNotNull);
    });
  });

  group('NexusStore aggregate throws before init', () {
    test('aggregate throws StateError on uninitialized store', () {
      final uninitBackend = MockAggregateBackend();
      final uninitStore = NexusStore(
        backend: uninitBackend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitStore.aggregate('amount', AggregateType.sum),
        throwsStateError,
      );
    });

    test('sum throws StateError on uninitialized store', () {
      final uninitBackend = MockAggregateBackend();
      final uninitStore = NexusStore(
        backend: uninitBackend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitStore.sum('amount'),
        throwsStateError,
      );
    });

    test('avg throws StateError on uninitialized store', () {
      final uninitBackend = MockAggregateBackend();
      final uninitStore = NexusStore(
        backend: uninitBackend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitStore.avg('rating'),
        throwsStateError,
      );
    });

    test('min throws StateError on uninitialized store', () {
      final uninitBackend = MockAggregateBackend();
      final uninitStore = NexusStore(
        backend: uninitBackend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitStore.min('price'),
        throwsStateError,
      );
    });

    test('max throws StateError on uninitialized store', () {
      final uninitBackend = MockAggregateBackend();
      final uninitStore = NexusStore(
        backend: uninitBackend,
        config: const StoreConfig(),
      );

      expect(
        () => uninitStore.max('price'),
        throwsStateError,
      );
    });
  });

  group('NexusStore aggregate with interceptor chain', () {
    late NexusStore<Map<String, dynamic>, String> store;
    late MockAggregateBackend backend;

    setUp(() {
      backend = MockAggregateBackend();
      store = NexusStore(
        backend: backend,
        config: const StoreConfig(),
      );
      store.initialize();
    });

    test('aggregate tracks operation via _trackOperation', () async {
      backend.aggregateResult = 42;
      final result = await store.aggregate('amount', AggregateType.sum);
      expect(result, equals(42));
      expect(backend.aggregateCallCount, equals(1));
    });

    test('sum convenience calls aggregate with correct type', () async {
      backend.aggregateResult = 100;
      await store.sum('amount');
      expect(backend.lastType, equals(AggregateType.sum));
    });

    test('avg convenience calls aggregate with correct type', () async {
      backend.aggregateResult = 25.5;
      await store.avg('rating');
      expect(backend.lastType, equals(AggregateType.avg));
    });

    test('min convenience calls aggregate with correct type', () async {
      backend.aggregateResult = 1;
      await store.min('price');
      expect(backend.lastType, equals(AggregateType.min));
    });

    test('max convenience calls aggregate with correct type', () async {
      backend.aggregateResult = 999;
      await store.max('price');
      expect(backend.lastType, equals(AggregateType.max));
    });

    test('convenience methods pass query parameter', () async {
      backend.aggregateResult = 50;
      final query =
          Query<Map<String, dynamic>>().where('active', isEqualTo: true);

      await store.avg('rating', query: query);
      expect(backend.lastQuery, isNotNull);

      await store.min('price', query: query);
      expect(backend.lastQuery, isNotNull);

      await store.max('price', query: query);
      expect(backend.lastQuery, isNotNull);
    });
  });

  group('StoreOperation.aggregate', () {
    test('is classified as read operation', () {
      expect(StoreOperation.aggregate.isRead, isTrue);
    });

    test('is not a write operation', () {
      expect(StoreOperation.aggregate.isWrite, isFalse);
    });

    test('does not modify data', () {
      expect(StoreOperation.aggregate.modifiesData, isFalse);
    });
  });

  group('TimingInterceptor aggregate mapping', () {
    test('aggregate goes through TimingInterceptor _mapOperation', () async {
      final reporter = _TestMetricsReporter();
      final backend = MockAggregateBackend()..aggregateResult = 42;

      final store = NexusStore<Map<String, dynamic>, String>(
        backend: backend,
        config: StoreConfig(
          interceptors: [
            TimingInterceptor(
              reporter: reporter,
              operations: {StoreOperation.aggregate},
            ),
          ],
        ),
      );
      await store.initialize();

      await store.aggregate('amount', AggregateType.sum);

      expect(reporter.operations, contains(OperationType.aggregate));
      await store.dispose();
    });
  });

  group('CompositeBackend.aggregate', () {
    test('delegates aggregate to primary backend', () async {
      final primary = MockAggregateBackend()..aggregateResult = 100;

      final composite = CompositeBackend<Map<String, dynamic>, String>(
        primary: primary,
      );

      final result = await composite.aggregate('amount', AggregateType.sum);

      expect(result, equals(100));
      expect(primary.lastField, equals('amount'));
      expect(primary.lastType, equals(AggregateType.sum));
    });

    test('delegates aggregate with query to primary backend', () async {
      final primary = MockAggregateBackend()..aggregateResult = 50;
      final query =
          Query<Map<String, dynamic>>().where('active', isEqualTo: true);

      final composite = CompositeBackend<Map<String, dynamic>, String>(
        primary: primary,
      );

      final result = await composite.aggregate(
        'amount',
        AggregateType.avg,
        query: query,
      );

      expect(result, equals(50));
      expect(primary.lastQuery, isNotNull);
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
