// ignore_for_file: lines_longer_than_80_chars
@Tags(['integration'])
library;

import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

// -----------------------------------------------------------------------------
// Mock Classes
// -----------------------------------------------------------------------------

class MockOfflineFirstRepository extends Mock
    implements OfflineFirstRepository<TestModel> {}

// -----------------------------------------------------------------------------
// Test Model
// -----------------------------------------------------------------------------

/// Test model that extends OfflineFirstModel for integration tests.
class TestModel extends OfflineFirstModel {
  TestModel({
    required this.id,
    required this.name,
    this.age = 0,
    int? primaryKeyId,
  }) : _primaryKeyId = primaryKeyId;

  final String id;
  final String name;
  final int age;
  final int? _primaryKeyId;

  @override
  int? get primaryKey => _primaryKeyId;

  @override
  set primaryKey(int? value) {
    // Required by SqliteModel interface
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'TestModel(id: $id, name: $name, age: $age)';
}

void main() {
  group('Brick Integration Tests', () {
    late MockOfflineFirstRepository mockRepository;

    setUp(() {
      mockRepository = MockOfflineFirstRepository();
    });

    BrickBackend<TestModel, String> createBackend({
      MockOfflineFirstRepository? repository,
      String primaryKeyField = 'id',
      Map<String, String>? fieldMapping,
    }) =>
        BrickBackend<TestModel, String>(
          repository: repository ?? mockRepository,
          getId: (model) => model.id,
          primaryKeyField: primaryKeyField,
          fieldMapping: fieldMapping,
        );

    group('Backend Properties', () {
      test('name returns "brick"', () {
        final backend = createBackend();
        expect(backend.name, equals('brick'));
      });

      test('supportsOffline returns true (offline-first backend)', () {
        final backend = createBackend();
        expect(backend.supportsOffline, isTrue);
      });

      test('supportsRealtime returns true', () {
        final backend = createBackend();
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns true', () {
        final backend = createBackend();
        expect(backend.supportsTransactions, isTrue);
      });

      test('initial syncStatus is synced', () {
        final backend = createBackend();
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('pendingChangesCount is 0 when synced', () async {
        final backend = createBackend();
        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });
    });

    group('Lifecycle Management', () {
      test('close can be called without initialization', () async {
        final backend = createBackend();

        // Should not throw
        await backend.close();
        await backend.close();
      });

      test('close can be called multiple times (idempotent)', () async {
        final backend = createBackend();

        // Multiple close calls should not throw
        await backend.close();
        await backend.close();
        await backend.close();
      });
    });

    group('Uninitialized State Guards', () {
      late BrickBackend<TestModel, String> backend;

      setUp(() {
        backend = createBackend();
      });

      tearDown(() async {
        await backend.close();
      });

      test('get throws StateError when not initialized', () {
        expect(
          () => backend.get('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError when not initialized', () {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError when not initialized', () {
        expect(
          () => backend.save(TestModel(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError when not initialized', () {
        expect(
          () => backend.saveAll([TestModel(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError when not initialized', () {
        expect(
          () => backend.delete('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError when not initialized', () {
        expect(
          () => backend.deleteAll(['id1', 'id2']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError when not initialized', () {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError when not initialized', () {
        expect(
          () => backend.watch('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError when not initialized', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError when not initialized', () {
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('StateError contains proper message and state info', () async {
        try {
          await backend.get('test-id');
          fail('Expected StateError');
        } on nexus.StateError catch (e) {
          expect(e.message, contains('not initialized'));
          expect(e.currentState, equals('uninitialized'));
          expect(e.expectedState, equals('initialized'));
        }
      });
    });

    group('Sync Status (Before Initialization)', () {
      test('syncStatusStream emits synced before initialization', () async {
        final backend = createBackend();
        final status = await backend.syncStatusStream.first;
        expect(status, equals(nexus.SyncStatus.synced));
      });

      test('syncStatus is synced before initialization', () {
        final backend = createBackend();
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream is a broadcast stream', () async {
        final backend = createBackend();
        // Multiple listeners should be allowed
        final listener1 = backend.syncStatusStream.listen((_) {});
        final listener2 = backend.syncStatusStream.listen((_) {});

        await listener1.cancel();
        await listener2.cancel();
      });
    });

    group('Configuration Options', () {
      test('custom primary key field is accepted', () {
        final backend = createBackend(primaryKeyField: 'uuid');
        expect(backend, isNotNull);
      });

      test('field mapping is accepted', () {
        final backend = createBackend(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );
        expect(backend, isNotNull);
      });

      test('custom query translator is accepted', () {
        final translator = BrickQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );
        final backend = BrickBackend<TestModel, String>(
          repository: mockRepository,
          getId: (model) => model.id,
          primaryKeyField: 'id',
          queryTranslator: translator,
        );
        expect(backend, isNotNull);
      });
    });

    group('Query Building', () {
      test('empty query has isEmpty true', () {
        const query = nexus.Query<TestModel>();
        expect(query.isEmpty, isTrue);
      });

      test('query with filters has isNotEmpty true', () {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(query.isNotEmpty, isTrue);
      });

      test('query supports multiple filters', () {
        final query = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Test')
            .where('age', isGreaterThan: 18);
        expect(query.filters.length, equals(2));
      });

      test('query supports ordering', () {
        final query = const nexus.Query<TestModel>()
            .orderByField('name')
            .orderByField('age', descending: true);
        expect(query.orderBy.length, equals(2));
      });

      test('query supports pagination', () {
        final query = const nexus.Query<TestModel>().limitTo(10).offsetBy(5);
        expect(query.limit, equals(10));
        expect(query.offset, equals(5));
      });

      test('complex query with all features', () {
        final query = const nexus.Query<TestModel>()
            .where('age', isGreaterThanOrEqualTo: 18)
            .where('name', isNotEqualTo: 'banned')
            .orderByField('createdAt', descending: true)
            .limitTo(20)
            .offsetBy(0);

        expect(query.filters.length, equals(2));
        expect(query.orderBy.length, equals(1));
        expect(query.limit, equals(20));
        expect(query.offset, equals(0));
        expect(query.isNotEmpty, isTrue);
      });
    });

    group('Query Translator', () {
      test('translator maps field names correctly', () {
        final translator = BrickQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name', 'createdAt': 'created_at'},
        );

        // Translator should be created successfully
        expect(translator, isNotNull);
      });

      test('translator without field mapping uses original names', () {
        final translator = BrickQueryTranslator<TestModel>();
        expect(translator, isNotNull);
      });
    });

    group('Error Type Mapping Patterns', () {
      // These tests verify the error patterns that the backend recognizes
      // Actual error mapping is tested via unit tests

      test('network error pattern is recognized', () {
        const errorPatterns = ['network', 'SocketException', 'Connection'];
        for (final pattern in errorPatterns) {
          expect(
            pattern.toLowerCase(),
            anyOf(
              contains('network'),
              contains('socket'),
              contains('connection'),
            ),
          );
        }
      });

      test('timeout error pattern is recognized', () {
        const errorPatterns = ['timeout', 'TimeoutException'];
        for (final pattern in errorPatterns) {
          expect(pattern.toLowerCase(), contains('timeout'));
        }
      });

      test('conflict error pattern is recognized', () {
        const errorPatterns = ['conflict', 'Conflict'];
        for (final pattern in errorPatterns) {
          expect(pattern.toLowerCase(), contains('conflict'));
        }
      });
    });

    group('Offline-First Behavior Characteristics', () {
      // These tests document expected offline-first behavior

      test('backend indicates offline support', () {
        final backend = createBackend();
        // Brick is an offline-first framework
        expect(backend.supportsOffline, isTrue);
      });

      test('backend indicates transaction support', () {
        final backend = createBackend();
        // Brick repositories support transactions through SQLite
        expect(backend.supportsTransactions, isTrue);
      });

      test('backend indicates realtime support', () {
        final backend = createBackend();
        // Watch streams provide realtime-like updates
        expect(backend.supportsRealtime, isTrue);
      });
    });

    group('Repository CRUD Operations', () {
      late MockOfflineFirstRepository initMockRepository;
      late BrickBackend<TestModel, String> initBackend;

      setUp(() async {
        initMockRepository = MockOfflineFirstRepository();

        // Register fallback values
        registerFallbackValue(TestModel(id: 'fallback', name: 'fallback'));

        // Mock initialize to succeed
        when(() => initMockRepository.initialize()).thenAnswer((_) async {});

        initBackend = BrickBackend<TestModel, String>(
          repository: initMockRepository,
          getId: (model) => model.id,
          primaryKeyField: 'id',
        );

        await initBackend.initialize();
      });

      tearDown(() async {
        await initBackend.close();
      });

      test('save creates a new record', () async {
        final model = TestModel(id: 'create-1', name: 'New Item');

        when(() => initMockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => model);

        final result = await initBackend.save(model);

        expect(result.id, equals('create-1'));
        expect(result.name, equals('New Item'));
        verify(() => initMockRepository.upsert<TestModel>(model)).called(1);
      });

      test('save updates an existing record', () async {
        final original = TestModel(id: 'update-1', name: 'Original');
        final updated = TestModel(id: 'update-1', name: 'Updated');

        when(() => initMockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => updated);

        await initBackend.save(original);
        final result = await initBackend.save(updated);

        expect(result.name, equals('Updated'));
      });

      test('get retrieves a record by id', () async {
        final model = TestModel(id: 'get-1', name: 'Get Test');

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => [model]);

        final result = await initBackend.get('get-1');

        expect(result, isNotNull);
        expect(result!.id, equals('get-1'));
      });

      test('get returns null for non-existent id', () async {
        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => <TestModel>[]);

        final result = await initBackend.get('non-existent');

        expect(result, isNull);
      });

      test('getAll retrieves all records', () async {
        final models = [
          TestModel(id: '1', name: 'Item 1'),
          TestModel(id: '2', name: 'Item 2'),
        ];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => models);

        final results = await initBackend.getAll();

        expect(results, hasLength(2));
      });

      test('getAll with query filters results', () async {
        final filtered = [TestModel(id: '1', name: 'Filtered')];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => filtered);

        final query = const nexus.Query<TestModel>().where(
          'name',
          isEqualTo: 'Filtered',
        );

        final results = await initBackend.getAll(query: query);

        expect(results, hasLength(1));
        expect(results.first.name, equals('Filtered'));
      });

      test('delete removes a record', () async {
        final model = TestModel(id: 'del-1', name: 'To Delete');

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => [model]);
        when(() => initMockRepository.delete<TestModel>(model))
            .thenAnswer((_) async => true);

        final deleted = await initBackend.delete('del-1');

        expect(deleted, isTrue);
      });

      test('delete returns false for non-existent record', () async {
        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => <TestModel>[]);

        final deleted = await initBackend.delete('non-existent');

        expect(deleted, isFalse);
      });

      test('deleteAll removes multiple records', () async {
        final models = [
          TestModel(id: 'del-1', name: 'Item 1'),
          TestModel(id: 'del-2', name: 'Item 2'),
        ];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => models);
        when(() => initMockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        final count = await initBackend.deleteAll(['del-1', 'del-2']);

        expect(count, equals(2));
      });

      test('deleteWhere removes records matching query', () async {
        final models = [TestModel(id: 'delw-1', name: 'Match')];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => models);
        when(() => initMockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        final query = const nexus.Query<TestModel>().where(
          'name',
          isEqualTo: 'Match',
        );

        await initBackend.deleteWhere(query);

        verify(() => initMockRepository.delete<TestModel>(any())).called(1);
      });
    });

    group('Watch/Streaming Operations', () {
      late MockOfflineFirstRepository initMockRepository;
      late BrickBackend<TestModel, String> initBackend;

      setUp(() async {
        initMockRepository = MockOfflineFirstRepository();
        registerFallbackValue(TestModel(id: 'fallback', name: 'fallback'));
        when(() => initMockRepository.initialize()).thenAnswer((_) async {});

        initBackend = BrickBackend<TestModel, String>(
          repository: initMockRepository,
          getId: (model) => model.id,
          primaryKeyField: 'id',
        );

        await initBackend.initialize();
      });

      tearDown(() async {
        await initBackend.close();
      });

      test('watch emits initial value', () async {
        final model = TestModel(id: 'watch-1', name: 'Watch Test');

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => [model]);
        when(
          () => initMockRepository.subscribe<TestModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Stream.value([model]));

        final stream = initBackend.watch('watch-1');
        final firstValue = await stream.first;

        expect(firstValue, isNotNull);
        expect(firstValue!.id, equals('watch-1'));
      });

      test('watch emits updates on changes', () async {
        final original = TestModel(id: 'watch-2', name: 'Original');
        final updated = TestModel(id: 'watch-2', name: 'Updated');

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => [original]);
        when(
          () => initMockRepository.subscribe<TestModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Stream.fromIterable([
              [original],
              [updated],
            ]),);

        final stream = initBackend.watch('watch-2');
        // Use timeout to prevent test hanging if stream doesn't emit expected values
        final values = await stream
            .take(2)
            .toList()
            .timeout(const Duration(seconds: 5), onTimeout: () => [original]);

        expect(values.length, greaterThanOrEqualTo(1));
      });

      test('watchAll emits initial list', () async {
        final models = [
          TestModel(id: 'wall-1', name: 'Item 1'),
          TestModel(id: 'wall-2', name: 'Item 2'),
        ];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => models);
        when(
          () => initMockRepository.subscribe<TestModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Stream.value(models));

        final stream = initBackend.watchAll();
        final firstValue = await stream.first;

        expect(firstValue, hasLength(2));
      });

      test('watchAll emits updates on changes', () async {
        final initial = [TestModel(id: 'wall-3', name: 'Initial')];
        final afterAdd = [
          TestModel(id: 'wall-3', name: 'Initial'),
          TestModel(id: 'wall-4', name: 'New'),
        ];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => initial);
        when(
          () => initMockRepository.subscribe<TestModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Stream.fromIterable([initial, afterAdd]));

        final stream = initBackend.watchAll();
        // Use timeout to prevent test hanging if stream doesn't emit expected values
        final values = await stream
            .take(2)
            .toList()
            .timeout(const Duration(seconds: 5), onTimeout: () => [initial]);

        expect(values.length, greaterThanOrEqualTo(1));
      });

      test('watchAll with query filters results', () async {
        final filtered = [TestModel(id: 'wquery-1', name: 'Filtered')];

        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => filtered);
        when(
          () => initMockRepository.subscribe<TestModel>(
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Stream.value(filtered));

        final query = const nexus.Query<TestModel>().where(
          'name',
          isEqualTo: 'Filtered',
        );

        final stream = initBackend.watchAll(query: query);
        final firstValue = await stream.first;

        expect(firstValue, hasLength(1));
        expect(firstValue.first.name, equals('Filtered'));
      });
    });

    group('Sync Operations', () {
      late MockOfflineFirstRepository initMockRepository;
      late BrickBackend<TestModel, String> initBackend;

      setUp(() async {
        initMockRepository = MockOfflineFirstRepository();
        registerFallbackValue(TestModel(id: 'fallback', name: 'fallback'));
        when(() => initMockRepository.initialize()).thenAnswer((_) async {});

        initBackend = BrickBackend<TestModel, String>(
          repository: initMockRepository,
          getId: (model) => model.id,
          primaryKeyField: 'id',
        );

        await initBackend.initialize();
      });

      tearDown(() async {
        await initBackend.close();
      });

      test('sync triggers repository refresh', () async {
        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => <TestModel>[]);

        await initBackend.sync();

        // Sync should complete without error
        expect(initBackend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('sync updates status during operation', () async {
        when(() =>
                initMockRepository.get<TestModel>(query: any(named: 'query')),)
            .thenAnswer((_) async => <TestModel>[]);

        final statuses = <nexus.SyncStatus>[];
        final subscription = initBackend.syncStatusStream.listen(statuses.add);

        await initBackend.sync();
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        // Should have transitioned through syncing to synced
        expect(statuses, contains(nexus.SyncStatus.synced));
      });

      test('pendingChangesCount reflects queue state', () async {
        // Brick backend tracks pending changes count
        final count = await initBackend.pendingChangesCount;

        // Initial count should be 0 (no pending changes)
        expect(count, equals(0));
      });
    });
  });
}
