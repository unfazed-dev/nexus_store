import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

import '../../fixtures/mock_backend.dart';
import '../../fixtures/test_entities.dart';

void main() {
  group('NexusStore.getDiagnostics', () {
    late FakeStoreBackend<TestUser, String> backend;
    late NexusStore<TestUser, String> store;

    setUp(() async {
      backend = FakeStoreBackend<TestUser, String>(
        idExtractor: (u) => u.id,
      );
      store = NexusStore<TestUser, String>(
        backend: backend,
        config: StoreConfig(
          metricsConfig: const MetricsConfig(sampleRate: 1.0),
        ),
        idExtractor: (u) => u.id,
      );
      await store.initialize();
    });

    tearDown(() async {
      await store.dispose();
    });

    test('returns StoreDiagnostics with correct type', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics, isA<StoreDiagnostics>());
    });

    test('reports isInitialized correctly', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.isInitialized, isTrue);
    });

    test('reports entity count from backend', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      backend.addToStorage(
        'user-2',
        TestFixtures.createUser(id: 'user-2', name: 'Bob'),
      );

      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.entityCount, equals(2));
    });

    test('includes cache stats', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.cacheStats, isA<CacheStats>());
    });

    test('includes store stats with operation counts', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      await store.get('user-1');
      await store.count();

      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.storeStats.totalOperations, greaterThanOrEqualTo(2));
    });

    test('reports cache hit rate', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.cacheHitPercentage, isA<double>());
    });

    test('reports average latency', () async {
      backend.addToStorage(
        'user-1',
        TestFixtures.createUser(id: 'user-1', name: 'Alice'),
      );
      await store.get('user-1');

      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.averageLatency, isA<Duration>());
    });

    test('reports pending changes count', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.pendingChangesCount, isA<int>());
    });

    test('reports healthy status on fresh store', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.healthStatus, equals(HealthStatus.healthy));
    });

    test('includes timestamp', () async {
      final before = DateTime.now();
      final diagnostics = await store.getDiagnostics();
      final after = DateTime.now();

      expect(
          diagnostics.timestamp.isAfter(before) ||
              diagnostics.timestamp.isAtSameMomentAs(before),
          isTrue);
      expect(
          diagnostics.timestamp.isBefore(after) ||
              diagnostics.timestamp.isAtSameMomentAs(after),
          isTrue);
    });

    test('includes slow operation threshold', () async {
      final diagnostics = await store.getDiagnostics();
      expect(diagnostics.slowOperationThreshold, isA<Duration>());
    });

    test('toString provides summary', () async {
      final diagnostics = await store.getDiagnostics();
      final str = diagnostics.toString();
      expect(str, contains('StoreDiagnostics'));
      expect(str, contains('health:'));
    });
  });

  group('StoreDiagnostics.healthStatus', () {
    test('returns unhealthy when error rate exceeds 10%', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats(
          operationCounts: {OperationType.get: 10},
          totalDurations: {},
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 2, // 20% error rate
        ),
        cacheStats: CacheStats.empty(),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 0,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(diagnostics.healthStatus, equals(HealthStatus.unhealthy));
    });

    test('returns unhealthy on critical memory pressure', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats.empty(),
        cacheStats: CacheStats.empty(),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 0,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
        memoryPressure: MemoryPressureLevel.critical,
      );

      expect(diagnostics.healthStatus, equals(HealthStatus.unhealthy));
    });

    test('returns degraded when slow operations exist', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats.empty(),
        cacheStats: CacheStats.empty(),
        slowOperations: [
          SlowOperation(
            operation: OperationType.get,
            duration: const Duration(milliseconds: 200),
            threshold: const Duration(milliseconds: 100),
            timestamp: DateTime.now(),
          ),
        ],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 0,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(diagnostics.healthStatus, equals(HealthStatus.degraded));
    });

    test('returns degraded when stale cache percentage is high', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats.empty(),
        cacheStats: const CacheStats(
          totalCount: 10,
          staleCount: 6, // 60% stale
          tagCounts: {},
        ),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 10,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(diagnostics.healthStatus, equals(HealthStatus.degraded));
    });

    test('returns healthy when no issues', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats(
          operationCounts: {OperationType.get: 100},
          totalDurations: {
            OperationType.get: const Duration(seconds: 1),
          },
          cacheHits: 90,
          cacheMisses: 10,
          syncSuccessCount: 5,
          syncFailureCount: 0,
          errorCount: 1, // 1% error rate — healthy
        ),
        cacheStats: const CacheStats(
          totalCount: 50,
          staleCount: 5, // 10% stale — healthy
          tagCounts: {},
        ),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 50,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(diagnostics.healthStatus, equals(HealthStatus.healthy));
    });
  });

  group('SlowOperation', () {
    test('calculates ratio correctly', () {
      final slow = SlowOperation(
        operation: OperationType.get,
        duration: const Duration(milliseconds: 300),
        threshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(slow.ratio, closeTo(3.0, 0.01));
    });

    test('equality and hashCode', () {
      final now = DateTime(2026, 3, 16);
      final a = SlowOperation(
        operation: OperationType.get,
        duration: const Duration(milliseconds: 200),
        threshold: const Duration(milliseconds: 100),
        timestamp: now,
      );
      final b = SlowOperation(
        operation: OperationType.get,
        duration: const Duration(milliseconds: 200),
        threshold: const Duration(milliseconds: 100),
        timestamp: now,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes details', () {
      final slow = SlowOperation(
        operation: OperationType.get,
        duration: const Duration(milliseconds: 200),
        threshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(slow.toString(), contains('SlowOperation'));
      expect(slow.toString(), contains('200ms'));
      expect(slow.toString(), contains('100ms'));
    });
  });

  group('StoreDiagnostics.averageLatency', () {
    test('returns zero when no operations', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats.empty(),
        cacheStats: CacheStats.empty(),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 0,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      expect(diagnostics.averageLatency, equals(Duration.zero));
    });

    test('calculates average across operation types', () {
      final diagnostics = StoreDiagnostics(
        storeStats: StoreStats(
          operationCounts: {
            OperationType.get: 10,
            OperationType.save: 10,
          },
          totalDurations: {
            OperationType.get: const Duration(milliseconds: 100), // 10ms avg
            OperationType.save: const Duration(milliseconds: 200), // 20ms avg
          },
          cacheHits: 0,
          cacheMisses: 0,
          syncSuccessCount: 0,
          syncFailureCount: 0,
          errorCount: 0,
        ),
        cacheStats: CacheStats.empty(),
        slowOperations: [],
        pendingChangesCount: 0,
        isInitialized: true,
        entityCount: 0,
        slowOperationThreshold: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      // (100ms + 200ms) / 20 ops = 15ms avg
      expect(
          diagnostics.averageLatency, equals(const Duration(milliseconds: 15)));
    });
  });
}
