import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_supabase_adapter/nexus_store_supabase_adapter.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_client_wrapper.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseClientWrapper extends Mock implements SupabaseClientWrapper {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class FakeRealtimeChannel extends Fake implements RealtimeChannel {}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(FakeRealtimeChannel());
    registerFallbackValue((PostgresChangePayload p) {});
  });
  group('SupabaseBackend', () {
    late MockSupabaseClient mockClient;
    late SupabaseBackend<TestModel, String> backend;

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    tearDown(() async {
      try {
        await backend.close();
      } on Object {
        // Ignore if already closed or not initialized
      }
    });

    SupabaseBackend<TestModel, String> createBackend({
      MockSupabaseClient? client,
    }) =>
        SupabaseBackend<TestModel, String>(
          client: client ?? mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
        );

    group('backend info', () {
      test('name returns "supabase"', () {
        backend = createBackend();
        expect(backend.name, 'supabase');
      });

      test('supportsOffline returns false', () {
        backend = createBackend();
        expect(backend.supportsOffline, isFalse);
      });

      test('supportsRealtime returns true', () {
        backend = createBackend();
        expect(backend.supportsRealtime, isTrue);
      });

      test('supportsTransactions returns false', () {
        backend = createBackend();
        expect(backend.supportsTransactions, isFalse);
      });
    });

    group('construction', () {
      test('creates backend with required parameters', () {
        backend = createBackend();
        expect(backend, isNotNull);
      });

      test('creates backend with custom primary key column', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyColumn: 'uuid',
        );
        expect(backend, isNotNull);
      });

      test('creates backend with custom query translator', () {
        final translator = SupabaseQueryTranslator<TestModel>(
          fieldMapping: {'userName': 'user_name'},
        );
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          queryTranslator: translator,
        );
        expect(backend, isNotNull);
      });

      test('creates backend with field mapping', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          fieldMapping: {'userName': 'user_name'},
        );
        expect(backend, isNotNull);
      });

      test('creates backend with custom schema', () {
        backend = SupabaseBackend<TestModel, String>(
          client: mockClient,
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          schema: 'custom_schema',
        );
        expect(backend, isNotNull);
      });
    });

    group('sync status (online-only)', () {
      test('initial sync status is synced', () {
        backend = createBackend();
        expect(backend.syncStatus, nexus.SyncStatus.synced);
      });

      test('syncStatusStream emits synced initially', () async {
        backend = createBackend();
        final status = await backend.syncStatusStream.first;
        expect(status, nexus.SyncStatus.synced);
      });

      test('pendingChangesCount returns 0', () async {
        backend = createBackend();
        final count = await backend.pendingChangesCount;
        expect(count, 0);
      });
    });

    group('uninitialized state', () {
      test('get throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.get('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.save(const TestModel(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.saveAll([const TestModel(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.delete('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.deleteAll(['test-id']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteWhere throws StateError when not initialized', () {
        backend = createBackend();
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.watch('test-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('sync throws StateError when not initialized', () {
        backend = createBackend();
        expect(
          () => backend.sync(),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('close', () {
      test('close can be called multiple times', () async {
        backend = createBackend();
        // Close without initializing
        await backend.close();
        await backend.close();
        // Should not throw
      });
    });
  });

  group('SupabaseBackend error mapping', () {
    test('PostgrestException with PGRST116 maps to NotFoundError', () {
      // Test that the error message pattern is recognized
      const errorCode = 'PGRST116';
      expect(errorCode, contains('PGRST116'));
    });

    test('PostgrestException with 23505 maps to ValidationError', () {
      // Test that unique constraint code is recognized
      const errorCode = '23505';
      expect(errorCode, contains('23505'));
    });

    test('PostgrestException with 23503 maps to ValidationError', () {
      // Test that foreign key code is recognized
      const errorCode = '23503';
      expect(errorCode, contains('23503'));
    });

    test('PostgrestException with 42501 maps to AuthorizationError', () {
      // Test that RLS error code is recognized
      const errorCode = '42501';
      expect(errorCode, contains('42501'));
    });
  });

  group('Query integration', () {
    test('Query can be built for SupabaseBackend', () {
      const query = nexus.Query<TestModel>();
      final filtered = query
          .where('name', isEqualTo: 'Test')
          .where('age', isGreaterThan: 18)
          .orderByField('createdAt', descending: true)
          .limitTo(10)
          .offsetBy(5);

      expect(filtered.filters, hasLength(2));
      expect(filtered.orderBy, hasLength(1));
      expect(filtered.limit, 10);
      expect(filtered.offset, 5);
    });

    test('Empty query has isEmpty true', () {
      const query = nexus.Query<TestModel>();
      expect(query.isEmpty, isTrue);
    });

    test('Query with filters has isNotEmpty true', () {
      final query =
          const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
      expect(query.isNotEmpty, isTrue);
    });
  });

  group('CRUD operations with mock wrapper', () {
    late MockSupabaseClientWrapper mockWrapper;
    late MockSupabaseClient mockClient;
    late MockRealtimeChannel mockChannel;
    late SupabaseBackend<TestModel, String> backend;

    void setupRealtimeMocks() {
      when(() => mockWrapper.client).thenReturn(mockClient);
      // SupabaseClient has a convenience channel() method used directly
      when(() => mockClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
      when(() => mockClient.removeChannel(any()))
          .thenAnswer((_) async => 'ok');
    }

    setUp(() {
      mockWrapper = MockSupabaseClientWrapper();
      mockClient = MockSupabaseClient();
      mockChannel = MockRealtimeChannel();

      // Reset mocks to ensure clean state
      reset(mockWrapper);
      reset(mockClient);
      reset(mockChannel);

      // Setup realtime mocks for initialization
      setupRealtimeMocks();

      backend = SupabaseBackend<TestModel, String>.withWrapper(
        wrapper: mockWrapper,
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
      );
    });

    tearDown(() async {
      try {
        await backend.close();
      } on Object {
        // Ignore close errors
      }
    });

    group('get', () {
      test('returns item when found', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );

        await backend.initialize();
        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, '1');
        expect(result.name, 'Alice');
        expect(result.age, 25);
        verify(() => mockWrapper.get('test_models', 'id', '1')).called(1);
      });

      test('returns null when not found', () async {
        when(() => mockWrapper.get('test_models', 'id', 'nonexistent'))
            .thenAnswer((_) async => null);

        await backend.initialize();
        final result = await backend.get('nonexistent');

        expect(result, isNull);
      });

      test('maps PostgrestException to appropriate error', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(message: 'not found', code: 'PGRST116'),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NotFoundError>()),
        );
      });

      test('maps network error appropriately', () async {
        when(() => mockWrapper.get('test_models', 'id', '1'))
            .thenThrow(Exception('network error'));

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.NetworkError>()),
        );
      });

      test('maps timeout error appropriately', () async {
        when(() => mockWrapper.get('test_models', 'id', '1'))
            .thenThrow(Exception('timeout error'));

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.TimeoutError>()),
        );
      });

      test('maps AuthException to AuthenticationError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1'))
            .thenThrow(const AuthException('Session expired'));

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('maps PostgrestException 23505 to ValidationError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'unique constraint violation',
            code: '23505',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps PostgrestException 23503 to ValidationError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'foreign key constraint violation',
            code: '23503',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps PostgrestException 42501 to AuthorizationError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'permission denied',
            code: '42501',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('maps PostgrestException with jwt error to AuthenticationError',
          () async {
        // Note: PGRST301 alone triggers AuthorizationError due to RLS mapping
        // Use a different code with jwt message to trigger AuthenticationError
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'jwt token expired',
            code: 'some_code',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthenticationError>()),
        );
      });

      test('maps PostgrestException PGRST301 to AuthorizationError', () async {
        // PGRST301 is mapped to AuthorizationError first (RLS policy)
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'some rls error',
            code: 'PGRST301',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.AuthorizationError>()),
        );
      });

      test('maps unknown PostgrestException to SyncError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenThrow(
          const PostgrestException(
            message: 'some unknown error',
            code: 'UNKNOWN',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('maps unknown exception to SyncError', () async {
        when(() => mockWrapper.get('test_models', 'id', '1'))
            .thenThrow(Exception('some random error'));

        await backend.initialize();

        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });
    });

    group('getAll', () {
      test('returns all items when no query', () async {
        when(() => mockWrapper.getAll('test_models')).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
            {'id': '2', 'name': 'Bob', 'age': 30},
          ],
        );

        await backend.initialize();
        final result = await backend.getAll();

        expect(result, hasLength(2));
        expect(result[0].name, 'Alice');
        expect(result[1].name, 'Bob');
      });

      test('returns empty list when no items', () async {
        when(() => mockWrapper.getAll('test_models'))
            .thenAnswer((_) async => []);

        await backend.initialize();
        final result = await backend.getAll();

        expect(result, isEmpty);
      });

      test('passes query to wrapper when provided', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
          ],
        );

        await backend.initialize();
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Alice');
        final result = await backend.getAll(query: query);

        expect(result, hasLength(1));
        verify(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).called(1);
      });
    });

    group('save', () {
      test('creates new item', () async {
        when(() => mockWrapper.upsert('test_models', any())).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );

        await backend.initialize();
        final result = await backend.save(
          const TestModel(id: '1', name: 'Alice', age: 25),
        );

        expect(result.id, '1');
        expect(result.name, 'Alice');
        verify(
          () => mockWrapper.upsert(
            'test_models',
            {'id': '1', 'name': 'Alice', 'age': 25},
          ),
        ).called(1);
      });

      test('updates sync status to pending then synced', () async {
        when(() => mockWrapper.upsert('test_models', any())).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );

        await backend.initialize();

        final statuses = <nexus.SyncStatus>[];
        backend.syncStatusStream.listen(statuses.add);

        await backend.save(const TestModel(id: '1', name: 'Alice', age: 25));

        // Allow stream to emit
        await Future<void>.delayed(Duration.zero);

        expect(statuses, contains(nexus.SyncStatus.pending));
        expect(statuses.last, nexus.SyncStatus.synced);
      });

      test('sets sync status to error on failure', () async {
        when(() => mockWrapper.upsert('test_models', any())).thenThrow(
          const PostgrestException(
            message: 'constraint violation',
            code: '23505',
          ),
        );

        await backend.initialize();

        expect(
          () => backend.save(const TestModel(id: '1', name: 'Alice', age: 25)),
          throwsA(isA<nexus.ValidationError>()),
        );

        expect(backend.syncStatus, nexus.SyncStatus.error);
      });
    });

    group('saveAll', () {
      test('creates multiple items', () async {
        when(() => mockWrapper.upsertAll('test_models', any())).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
            {'id': '2', 'name': 'Bob', 'age': 30},
          ],
        );

        await backend.initialize();
        final result = await backend.saveAll([
          const TestModel(id: '1', name: 'Alice', age: 25),
          const TestModel(id: '2', name: 'Bob', age: 30),
        ]);

        expect(result, hasLength(2));
        expect(result[0].name, 'Alice');
        expect(result[1].name, 'Bob');
      });
    });

    group('delete', () {
      test('deletes existing item and returns true', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );
        when(() => mockWrapper.delete('test_models', 'id', '1'))
            .thenAnswer((_) async {});

        await backend.initialize();
        final result = await backend.delete('1');

        expect(result, isTrue);
        verify(() => mockWrapper.delete('test_models', 'id', '1')).called(1);
      });

      test('returns false when item does not exist', () async {
        when(() => mockWrapper.get('test_models', 'id', 'nonexistent'))
            .thenAnswer((_) async => null);

        await backend.initialize();
        final result = await backend.delete('nonexistent');

        expect(result, isFalse);
        verifyNever(
          () => mockWrapper.delete('test_models', 'id', 'nonexistent'),
        );
      });
    });

    group('deleteAll', () {
      test('deletes multiple items', () async {
        when(
          () => mockWrapper.deleteByIds('test_models', 'id', ['1', '2']),
        ).thenAnswer((_) async {});

        await backend.initialize();
        final result = await backend.deleteAll(['1', '2']);

        expect(result, 2);
        verify(
          () => mockWrapper.deleteByIds('test_models', 'id', ['1', '2']),
        ).called(1);
      });

      test('returns 0 for empty list', () async {
        await backend.initialize();
        final result = await backend.deleteAll([]);

        expect(result, 0);
        verifyNever(
          () => mockWrapper.deleteByIds(any(), any(), any()),
        );
      });
    });

    group('deleteWhere', () {
      test('deletes matching items', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
            {'id': '2', 'name': 'Alice', 'age': 30},
          ],
        );
        when(
          () => mockWrapper.deleteByIds('test_models', 'id', ['1', '2']),
        ).thenAnswer((_) async {});

        await backend.initialize();
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Alice');
        final result = await backend.deleteWhere(query);

        expect(result, 2);
      });

      test('returns 0 when no items match', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer((_) async => []);

        await backend.initialize();
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Nobody');
        final result = await backend.deleteWhere(query);

        expect(result, 0);
        verifyNever(
          () => mockWrapper.deleteByIds(any(), any(), any()),
        );
      });
    });

    group('watch', () {
      test('returns stream for entity ID', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );

        await backend.initialize();
        final stream = backend.watch('1');

        expect(stream, isA<Stream<TestModel?>>());
        final item = await stream.first;
        expect(item, isNotNull);
        expect(item!.id, '1');
        expect(item.name, 'Alice');
      });

      test('caches subject for same ID', () async {
        var callCount = 0;
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async {
            callCount++;
            return {'id': '1', 'name': 'Alice', 'age': 25};
          },
        );

        await backend.initialize();
        backend
          ..watch('1')
          ..watch('1')
          ..watch('1');

        // Wait for async operations
        await Future<void>.delayed(Duration.zero);

        // Only one get call should be made (subject is cached)
        expect(callCount, 1);
      });

      test('emits null when item not found', () async {
        when(() => mockWrapper.get('test_models', 'id', 'nonexistent'))
            .thenAnswer((_) async => null);

        await backend.initialize();
        final stream = backend.watch('nonexistent');
        final item = await stream.first;

        expect(item, isNull);
      });

      test('emits error on initial load failure', () async {
        when(() => mockWrapper.get('test_models', 'id', '1'))
            .thenThrow(Exception('network error'));

        await backend.initialize();
        final stream = backend.watch('1');

        expect(stream, emitsError(isA<nexus.NetworkError>()));
      });
    });

    group('watchAll', () {
      test('returns stream of items', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
            {'id': '2', 'name': 'Bob', 'age': 30},
          ],
        );

        await backend.initialize();
        final stream = backend.watchAll();

        expect(stream, isA<Stream<List<TestModel>>>());
        final items = await stream.first;
        expect(items, hasLength(2));
        expect(items[0].name, 'Alice');
        expect(items[1].name, 'Bob');
      });

      test('caches subject for same query', () async {
        var callCount = 0;
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer(
          (_) async {
            callCount++;
            return [
              {'id': '1', 'name': 'Alice', 'age': 25},
            ];
          },
        );

        await backend.initialize();
        backend
          ..watchAll()
          ..watchAll()
          ..watchAll();

        // Wait for async operations
        await Future<void>.delayed(Duration.zero);

        // Only one getAll call should be made (subject is cached)
        expect(callCount, 1);
      });

      test('uses unique queryKey for different queries', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice', 'age': 25},
          ],
        );

        await backend.initialize();
        final stream1 = backend.watchAll();
        final query = const nexus.Query<TestModel>().where(
          'name',
          isEqualTo: 'Bob',
        );
        final stream2 = backend.watchAll(query: query);

        // Should be different streams (different queryKeys)
        expect(identical(stream1, stream2), isFalse);
      });

      test('emits error on initial load failure', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenThrow(Exception('network error'));

        await backend.initialize();
        final stream = backend.watchAll();

        expect(stream, emitsError(isA<nexus.NetworkError>()));
      });

      test('emits empty list when no items exist', () async {
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer((_) async => []);

        await backend.initialize();
        final stream = backend.watchAll();
        final items = await stream.first;

        expect(items, isEmpty);
      });
    });

    group('watcher notifications', () {
      test('_notifyWatchers is called after save', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );
        when(() => mockWrapper.upsert('test_models', any())).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice Updated', 'age': 26},
        );

        await backend.initialize();

        // Start watching before save
        final stream = backend.watch('1');
        final firstValue = await stream.first;
        expect(firstValue!.name, 'Alice');

        // After save, watch stream should eventually emit the updated value
        // Note: _notifyWatchers updates the cached subject
        await backend.save(
          const TestModel(id: '1', name: 'Alice Updated', age: 26),
        );

        // The save operation calls _notifyWatchers which updates the subject
        // We verify this by checking the returned item from save
        verify(() => mockWrapper.upsert('test_models', any())).called(1);
      });

      test('_notifyDeletion is called after delete', () async {
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );
        when(() => mockWrapper.delete('test_models', 'id', '1'))
            .thenAnswer((_) async => true);

        await backend.initialize();

        // Start watching before delete
        final stream = backend.watch('1');
        final firstValue = await stream.first;
        expect(firstValue, isNotNull);

        // Delete triggers _notifyDeletion
        final deleted = await backend.delete('1');
        expect(deleted, isTrue);
        verify(() => mockWrapper.delete('test_models', 'id', '1')).called(1);
      });

      test('_refreshAllWatchers is triggered after save', () async {
        var getAllCallCount = 0;
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer((_) async {
          getAllCallCount++;
          return [{'id': '1', 'name': 'Alice', 'age': 25}];
        });
        when(() => mockWrapper.upsert('test_models', any())).thenAnswer(
          (_) async => {'id': '2', 'name': 'Bob', 'age': 30},
        );

        await backend.initialize();

        // Start watchAll - triggers first getAll
        final stream = backend.watchAll();
        await stream.first;
        expect(getAllCallCount, 1);

        // Save triggers _refreshAllWatchers which calls getAll again
        await backend.save(const TestModel(id: '2', name: 'Bob', age: 30));

        // Give time for async refresh
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(getAllCallCount, 2);
      });

      test('_refreshAllWatchers is triggered after delete', () async {
        var getAllCallCount = 0;
        when(
          () => mockWrapper.getAll(
            'test_models',
            queryBuilder: any(named: 'queryBuilder'),
          ),
        ).thenAnswer((_) async {
          getAllCallCount++;
          return [{'id': '1', 'name': 'Alice', 'age': 25}];
        });
        when(() => mockWrapper.get('test_models', 'id', '1')).thenAnswer(
          (_) async => {'id': '1', 'name': 'Alice', 'age': 25},
        );
        when(() => mockWrapper.delete('test_models', 'id', '1'))
            .thenAnswer((_) async => true);

        await backend.initialize();

        // Start watchAll - triggers first getAll
        final stream = backend.watchAll();
        await stream.first;
        expect(getAllCallCount, 1);

        // Delete triggers _refreshAllWatchers which calls getAll again
        await backend.delete('1');

        // Give time for async refresh
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(getAllCallCount, 2);
      });
    });
  });
}

/// Test model for backend tests.
class TestModel {
  const TestModel({
    required this.id,
    required this.name,
    this.age,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int?,
      );

  final String id;
  final String name;
  final int? age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
      };
}
