import 'package:brick_core/query.dart' as brick;
import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_brick_adapter/nexus_store_brick_adapter.dart';
import 'package:test/test.dart';

// Mock classes
class MockOfflineFirstRepository extends Mock
    implements OfflineFirstRepository<TestModel> {}

// Test model that extends OfflineFirstModel
class TestModel extends OfflineFirstModel {
  TestModel({required this.id, required this.name, int? primaryKeyId})
      : _primaryKeyId = primaryKeyId;

  final String id;
  final String name;
  final int? _primaryKeyId;

  @override
  int? get primaryKey => _primaryKeyId;

  @override
  set primaryKey(int? value) {
    // Required by SqliteModel
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(TestModel(id: 'fallback', name: 'fallback'));
    registerFallbackValue(const brick.Query());
  });

  group('BrickBackend', () {
    late MockOfflineFirstRepository mockRepository;
    late BrickBackend<TestModel, String> backend;

    setUp(() {
      mockRepository = MockOfflineFirstRepository();
      backend = BrickBackend<TestModel, String>(
        repository: mockRepository,
        getId: (model) => model.id,
        primaryKeyField: 'id',
      );
    });

    tearDown(() async {
      await backend.close();
    });

    group('backend info', () {
      test('name returns brick', () {
        expect(backend.name, 'brick');
      });

      test('supportsOffline returns true', () {
        expect(backend.supportsOffline, isTrue);
      });

      test('supportsRealtime returns true', () {
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns true', () {
        expect(backend.supportsTransactions, isTrue);
      });
    });

    group('lifecycle', () {
      test('initialize calls repository.initialize', () async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});

        await backend.initialize();

        verify(() => mockRepository.initialize()).called(1);
      });

      test('initialize throws SyncError on repository failure', () async {
        when(() => mockRepository.initialize())
            .thenThrow(Exception('Init failed'));

        expect(
          () => backend.initialize(),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('initialize is idempotent', () async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});

        await backend.initialize();
        await backend.initialize();

        verify(() => mockRepository.initialize()).called(1);
      });
    });

    group('read operations', () {
      setUp(() async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});
        await backend.initialize();
      });

      test('get returns item when found', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);

        final result = await backend.get('1');

        expect(result, testModel);
      });

      test('get returns null when not found', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final result = await backend.get('nonexistent');

        expect(result, isNull);
      });

      test('getAll returns all items', () async {
        final items = [
          TestModel(id: '1', name: 'Test 1'),
          TestModel(id: '2', name: 'Test 2'),
        ];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        final result = await backend.getAll();

        expect(result.length, 2);
        expect(result[0].name, 'Test 1');
        expect(result[1].name, 'Test 2');
      });

      test('getAll with query uses translator', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        await backend.getAll(query: query);

        verify(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .called(1);
      });

      test('watch returns stream with initial value', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);

        final stream = backend.watch('1');

        expect(await stream.first, testModel);
      });

      test('watchAll returns stream with initial values', () async {
        final items = [TestModel(id: '1', name: 'Test')];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        final stream = backend.watchAll();

        expect(await stream.first, items);
      });

      test('watch reuses cached subject for same id', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);

        // Call watch twice for same id
        backend.watch('1');
        backend.watch('1');

        // Allow initial load to complete
        await Future<void>.delayed(Duration.zero);

        // Repository should only be called once (cached on subsequent calls)
        verify(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .called(1);
      });

      test('watchAll reuses cached subject for same query', () async {
        final items = [TestModel(id: '1', name: 'Test')];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        // Call watchAll twice (no query = same key)
        backend.watchAll();
        backend.watchAll();

        // Allow initial load to complete
        await Future<void>.delayed(Duration.zero);

        // Repository should only be called once (cached on subsequent calls)
        verify(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .called(1);
      });

      test('watch handles error from repository', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('SocketException: Connection failed'));

        final stream = backend.watch('1');

        await expectLater(stream, emitsError(isA<nexus.NetworkError>()));
      });

      test('watchAll handles error from repository', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('SocketException: Connection failed'));

        final stream = backend.watchAll();

        await expectLater(stream, emitsError(isA<nexus.NetworkError>()));
      });

      test('getAll throws mapped exception on error', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('Database error'));

        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.SyncError>()),
        );
      });
    });

    group('write operations', () {
      setUp(() async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});
        await backend.initialize();
      });

      test('save upserts to repository', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => testModel);

        final result = await backend.save(testModel);

        expect(result, testModel);
        verify(() => mockRepository.upsert<TestModel>(testModel)).called(1);
      });

      test('save updates sync status', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => testModel);

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        await backend.save(testModel);

        await Future<void>.delayed(Duration.zero);
        expect(statuses, contains(nexus.SyncStatus.pending));
        expect(statuses.last, nexus.SyncStatus.synced);
      });

      test('saveAll upserts multiple items', () async {
        final items = [
          TestModel(id: '1', name: 'Test 1'),
          TestModel(id: '2', name: 'Test 2'),
        ];
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((inv) async => inv.positionalArguments[0] as TestModel);

        final result = await backend.saveAll(items);

        expect(result.length, 2);
        verify(() => mockRepository.upsert<TestModel>(any())).called(2);
      });

      test('delete removes item from repository', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        final result = await backend.delete('1');

        expect(result, isTrue);
        verify(() => mockRepository.delete<TestModel>(testModel)).called(1);
      });

      test('delete returns false when item not found', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final result = await backend.delete('nonexistent');

        expect(result, isFalse);
        verifyNever(() => mockRepository.delete<TestModel>(any()));
      });

      test('deleteAll deletes multiple items', () async {
        final items = [
          TestModel(id: '1', name: 'Test 1'),
          TestModel(id: '2', name: 'Test 2'),
        ];
        // Return item based on query
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((inv) async => [items.first]);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        final result = await backend.deleteAll(['1', '2']);

        expect(result, 2);
      });

      test('deleteWhere deletes matching items', () async {
        final items = [TestModel(id: '1', name: 'Test')];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        final query = const nexus.Query<TestModel>()
            .where('status', isEqualTo: 'deleted');
        final result = await backend.deleteWhere(query);

        expect(result, 1);
      });

      test('save notifies individual watchers', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        final updatedModel = TestModel(id: '1', name: 'Updated');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => updatedModel);

        // Start watching
        final stream = backend.watch('1');
        final values = <TestModel?>[];
        stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(Duration.zero);
        expect(values, [testModel]);

        // Save and trigger notification
        await backend.save(updatedModel);

        await Future<void>.delayed(Duration.zero);
        expect(values.last, updatedModel);
      });

      test('delete notifies individual watchers with null', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        // Start watching
        final stream = backend.watch('1');
        final values = <TestModel?>[];
        stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(Duration.zero);
        expect(values, [testModel]);

        // Delete and trigger notification
        await backend.delete('1');

        await Future<void>.delayed(Duration.zero);
        expect(values.last, isNull);
      });

      test('save refreshes watchAll subjects', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        final updatedModel = TestModel(id: '1', name: 'Updated');
        var callCount = 0;
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? [testModel] : [updatedModel];
        });
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => updatedModel);

        // Start watching all
        final stream = backend.watchAll();
        final values = <List<TestModel>>[];
        stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(Duration.zero);
        expect(values.first.first.name, 'Test');

        // Save triggers _refreshAllWatchers
        await backend.save(updatedModel);

        await Future<void>.delayed(Duration.zero);
        expect(values.last.first.name, 'Updated');
      });

      test('saveAll sets error status on failure', () async {
        final items = [TestModel(id: '1', name: 'Test')];
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenThrow(Exception('SaveAll failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        expect(
          () => backend.saveAll(items),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });

      test('delete sets error status on repository failure', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenThrow(Exception('Delete failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        expect(
          () => backend.delete('1'),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });

      test('deleteAll sets error status on failure', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => [testModel]);
        when(() => mockRepository.delete<TestModel>(any()))
            .thenThrow(Exception('Delete failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });

      test('deleteWhere sets error status on failure', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('Query failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        final query = const nexus.Query<TestModel>()
            .where('status', isEqualTo: 'deleted');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });
    });

    group('sync operations', () {
      setUp(() async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});
        await backend.initialize();
      });

      test('syncStatus is synced initially', () {
        expect(backend.syncStatus, nexus.SyncStatus.synced);
      });

      test('sync triggers repository get', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        await backend.sync();

        verify(() => mockRepository.get<TestModel>()).called(1);
      });

      test('sync updates status during operation', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => []);

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        await backend.sync();

        await Future<void>.delayed(Duration.zero);
        expect(statuses, contains(nexus.SyncStatus.syncing));
        expect(statuses.last, nexus.SyncStatus.synced);
      });

      test('pendingChangesCount returns 0 when synced', () async {
        expect(await backend.pendingChangesCount, 0);
      });

      test('sync sets error status on failure', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('Sync failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        expect(
          () => backend.sync(),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });

      test('refreshAllWatchers handles error gracefully', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        var shouldFail = false;
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async {
          if (shouldFail) throw Exception('Refresh failed');
          return [testModel];
        });
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => testModel);

        // Start watching all
        final stream = backend.watchAll();
        final values = <List<TestModel>>[];
        final errors = <Object>[];
        stream.listen(values.add, onError: errors.add);

        // Wait for initial value
        await Future<void>.delayed(Duration.zero);
        expect(values.first.first.name, 'Test');

        // Make refresh fail
        shouldFail = true;

        // Save triggers _refreshAllWatchers which should handle error
        await backend.save(testModel);

        await Future<void>.delayed(Duration.zero);
        expect(errors, isNotEmpty);
      });

      test('watchAll with query uses unique queryKey', () async {
        final items = [TestModel(id: '1', name: 'Test')];
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async => items);

        // Create two different queries
        final query1 = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Alice');
        final query2 = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Bob');

        // Watch with different queries
        backend.watchAll(query: query1);
        backend.watchAll(query: query2);
        backend.watchAll(); // _all_ key

        // Allow initial loads to complete
        await Future<void>.delayed(Duration.zero);

        // Each unique query should trigger its own load
        verify(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .called(3);
      });

      test('_refreshAllWatchers only refreshes _all_ subjects', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        final updatedModel = TestModel(id: '1', name: 'Updated');
        var allQueryCallCount = 0;
        var filteredQueryCallCount = 0;

        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((inv) async {
          final query = inv.namedArguments[const Symbol('query')];
          if (query == null) {
            allQueryCallCount++;
          } else {
            filteredQueryCallCount++;
          }
          return [testModel];
        });
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenAnswer((_) async => updatedModel);

        // Start watching with a query (filtered)
        final filteredQuery = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Test');
        backend.watchAll(query: filteredQuery);

        // Start watching all (no query)
        backend.watchAll();

        // Wait for initial values
        await Future<void>.delayed(Duration.zero);

        // Reset counts after initial loads
        allQueryCallCount = 0;
        filteredQueryCallCount = 0;

        // Save triggers _refreshAllWatchers
        await backend.save(updatedModel);

        await Future<void>.delayed(Duration.zero);

        // Only _all_ subject should be refreshed (queryKey == '_all_')
        expect(allQueryCallCount, 1);
        // Filtered query should NOT be refreshed by _refreshAllWatchers
        expect(filteredQueryCallCount, 0);
      });

      test('delete triggers _refreshAllWatchers', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        var callCount = 0;
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? [testModel] : [];
        });
        when(() => mockRepository.delete<TestModel>(any()))
            .thenAnswer((_) async => true);

        // Start watching all
        final stream = backend.watchAll();
        final values = <List<TestModel>>[];
        stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(Duration.zero);
        expect(values.first, hasLength(1));

        // Reset for tracking refresh
        callCount = 0;

        // Delete triggers _refreshAllWatchers
        await backend.delete('1');

        await Future<void>.delayed(Duration.zero);
        // Should have refreshed
        expect(callCount, greaterThan(0));
      });
    });

    group('error handling', () {
      setUp(() async {
        when(() => mockRepository.initialize()).thenAnswer((_) async {});
        await backend.initialize();
      });

      test('throws StateError when not initialized', () async {
        final uninitializedBackend = BrickBackend<TestModel, String>(
          repository: mockRepository,
          getId: (model) => model.id,
          primaryKeyField: 'id',
        );

        expect(
          () => uninitializedBackend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );

        await uninitializedBackend.close();
      });

      test('maps network exceptions to NetworkError', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('SocketException: Connection failed'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps timeout exceptions to TimeoutError', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('TimeoutException'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.TimeoutError>()),
        );
      });

      test('maps conflict exceptions to ConflictError', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('Conflict detected'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.ConflictError>()),
        );
      });

      test('maps unknown exceptions to SyncError', () async {
        when(() => mockRepository.get<TestModel>(query: any(named: 'query')))
            .thenThrow(Exception('Unknown error'));

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('save sets error status on failure', () async {
        final testModel = TestModel(id: '1', name: 'Test');
        when(() => mockRepository.upsert<TestModel>(any()))
            .thenThrow(Exception('Save failed'));

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        expect(
          () => backend.save(testModel),
          throwsA(isA<nexus.SyncError>()),
        );

        await Future<void>.delayed(Duration.zero);
        expect(statuses.last, nexus.SyncStatus.error);
      });
    });
  });
}
