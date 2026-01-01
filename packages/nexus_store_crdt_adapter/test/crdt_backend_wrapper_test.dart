import 'dart:async';

import 'package:crdt/crdt.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_crdt_adapter/nexus_store_crdt_adapter.dart';
import 'package:test/test.dart';

// Test model
class TestUser {
  TestUser({required this.id, required this.name, this.age});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
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
        if (age != null) 'age': age,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'TestUser(id: $id, name: $name, age: $age)';
}

// Mock classes
class MockCrdtDatabaseWrapper extends Mock implements CrdtDatabaseWrapper {
  CrdtTransactionContext? transactionContext;

  @override
  Future<void> transaction(
    Future<void> Function(CrdtTransactionContext txn) callback,
  ) async {
    if (transactionContext != null) {
      return callback(transactionContext!);
    }
    throw StateError('transactionContext not set');
  }
}

class MockCrdtTransactionContext extends Mock
    implements CrdtTransactionContext {}

void main() {
  group('CrdtBackend with wrapper', () {
    late MockCrdtDatabaseWrapper mockDb;
    late CrdtBackend<TestUser, String> backend;

    setUp(() {
      mockDb = MockCrdtDatabaseWrapper();

      when(() => mockDb.nodeId).thenReturn('test-node-id');

      backend = CrdtBackend<TestUser, String>.withWrapper(
        db: mockDb,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
        primaryKeyField: 'id',
      );
    });

    group('backend info', () {
      test('name returns "crdt"', () {
        expect(backend.name, equals('crdt'));
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

      test('supportsPagination returns true', () {
        expect(backend.supportsPagination, isTrue);
      });
    });

    group('lifecycle', () {
      test('initialize sets up backend with wrapper', () async {
        await backend.initialize();
        expect(backend.isInitialized, isTrue);
      });

      test('initialize is idempotent', () async {
        await backend.initialize();
        await backend.initialize();
        expect(backend.isInitialized, isTrue);
      });

      test('close delegates to wrapper', () async {
        when(() => mockDb.close()).thenAnswer((_) async {});

        await backend.initialize();
        await backend.close();

        expect(backend.isInitialized, isFalse);
        verify(() => mockDb.close()).called(1);
      });
    });

    group('read operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('get returns item when found', () async {
        when(() => mockDb.query(any(), any())).thenAnswer((_) async => [
              {'id': '1', 'name': 'John', 'age': 25},
            ],);

        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
        expect(result.name, equals('John'));
        expect(result.age, equals(25));
      });

      test('get returns null when not found', () async {
        when(() => mockDb.query(any(), any())).thenAnswer((_) async => []);

        final result = await backend.get('1');

        expect(result, isNull);
      });

      test('get strips CRDT metadata', () async {
        when(() => mockDb.query(any(), any())).thenAnswer((_) async => [
              {
                'id': '1',
                'name': 'John',
                'age': 25,
                'hlc': 'timestamp',
                'modified': 'timestamp',
                'is_deleted': 0,
                'node_id': 'node123',
              },
            ],);

        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
        expect(result.name, equals('John'));
      });

      test('getAll returns list of items', () async {
        when(() => mockDb.query(any(), any())).thenAnswer((_) async => [
              {'id': '1', 'name': 'John'},
              {'id': '2', 'name': 'Jane'},
            ],);

        final result = await backend.getAll();

        expect(result, hasLength(2));
        expect(result[0].name, equals('John'));
        expect(result[1].name, equals('Jane'));
      });

      test('getAll with query executes translated SQL', () async {
        when(() => mockDb.query(any(), any())).thenAnswer((_) async => []);

        await backend.getAll(
          query: const nexus.Query<TestUser>().where('name', isEqualTo: 'John'),
        );

        verify(() => mockDb.query(
              any(that: contains('name')),
              any(),
            ),).called(1);
      });
    });

    group('write operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('save executes insert statement', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async {});

        final user = TestUser(id: '1', name: 'John');
        final result = await backend.save(user);

        expect(result.id, equals('1'));
        verify(
          () => mockDb.execute(any(that: contains('INSERT OR REPLACE')), any()),
        ).called(1);
      });

      test('save returns the saved item', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async {});

        final user = TestUser(id: '1', name: 'John', age: 25);
        final result = await backend.save(user);

        expect(result, equals(user));
      });

      test('saveAll uses transaction', () async {
        final mockTxn = MockCrdtTransactionContext();
        when(() => mockTxn.execute(any(), any())).thenAnswer((_) async {});
        mockDb.transactionContext = mockTxn;

        final users = [
          TestUser(id: '1', name: 'John'),
          TestUser(id: '2', name: 'Jane'),
        ];
        final result = await backend.saveAll(users);

        expect(result, hasLength(2));
        verify(() => mockTxn.execute(any(), any())).called(2);
      });

      test('saveAll returns empty list for empty input', () async {
        final result = await backend.saveAll([]);

        expect(result, isEmpty);
      });

      test('delete executes delete statement', () async {
        when(() => mockDb.execute(any(), any())).thenAnswer((_) async {});

        final result = await backend.delete('1');

        expect(result, isTrue);
        verify(
          () => mockDb.execute(any(that: contains('DELETE')), any()),
        ).called(1);
      });

      test('deleteAll uses transaction', () async {
        final mockTxn = MockCrdtTransactionContext();
        when(() => mockTxn.execute(any(), any())).thenAnswer((_) async {});
        mockDb.transactionContext = mockTxn;

        final result = await backend.deleteAll(['1', '2', '3']);

        expect(result, equals(3));
        verify(() => mockTxn.execute(any(), any())).called(3);
      });

      test('deleteAll returns 0 for empty input', () async {
        final result = await backend.deleteAll([]);

        expect(result, equals(0));
      });
    });

    group('watch operations', () {
      late StreamController<List<Map<String, Object?>>> watchController;

      setUp(() async {
        watchController =
            StreamController<List<Map<String, Object?>>>.broadcast();
        when(() => mockDb.watch(any(), any()))
            .thenAnswer((_) => watchController.stream);
        await backend.initialize();
      });

      tearDown(() async {
        await watchController.close();
      });

      test('watch returns stream of items', () async {
        final stream = backend.watch('1');

        expect(stream, isA<Stream<TestUser?>>());

        watchController.add([
          {'id': '1', 'name': 'John', 'age': 25},
        ]);

        await expectLater(
          stream,
          emits(isA<TestUser>().having((u) => u.name, 'name', 'John')),
        );
      });

      test('watch emits null when item not found', () async {
        final stream = backend.watch('1');

        watchController.add([]);

        await expectLater(stream, emits(isNull));
      });

      test('watch handles stream errors', () async {
        final stream = backend.watch('1');

        watchController.addError(Exception('db error'));

        await expectLater(stream, emitsError(isA<nexus.StoreError>()));
      });

      test('watch caches subject for same ID', () async {
        // First call creates a new subscription
        backend.watch('1');

        // Second call should reuse cached subject, not create new subscription
        backend.watch('1');

        // mockDb.watch should only be called once due to caching
        verify(() => mockDb.watch(any(), any())).called(1);
      });

      test('watchAll returns stream of items', () async {
        final stream = backend.watchAll();

        watchController.add([
          {'id': '1', 'name': 'John'},
          {'id': '2', 'name': 'Jane'},
        ]);

        await expectLater(
          stream,
          emits(isA<List<TestUser>>().having((l) => l.length, 'length', 2)),
        );
      });

      test('watchAll handles stream errors', () async {
        final stream = backend.watchAll();

        watchController.addError(Exception('db error'));

        await expectLater(stream, emitsError(isA<nexus.StoreError>()));
      });

      test('watchAll caches subject for same query', () async {
        // First call creates a new subscription
        backend.watchAll();

        // Second call should reuse cached subject, not create new subscription
        backend.watchAll();

        // mockDb.watch should only be called once due to caching
        verify(() => mockDb.watch(any(), any())).called(1);
      });

      test('watchAll uses unique key for different queries', () async {
        final query =
            const nexus.Query<TestUser>().where('name', isEqualTo: 'John');
        final stream1 = backend.watchAll();
        final stream2 = backend.watchAll(query: query);

        expect(identical(stream1, stream2), isFalse);
      });
    });

    group('CRDT-specific operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('getChangeset delegates to wrapper', () async {
        final mockChangeset = <String, List<Map<String, Object?>>>{
          'users': [
            {'id': '1', 'name': 'John', 'hlc': 'timestamp'},
          ],
        };
        when(() => mockDb.getChangeset(modifiedAfter: any(named: 'modifiedAfter')))
            .thenAnswer((_) async => mockChangeset);

        final changeset = await backend.getChangeset();

        expect(changeset, equals(mockChangeset));
        verify(() => mockDb.getChangeset()).called(1);
      });

      test('getChangeset with since parameter', () async {
        final hlc = Hlc.zero('testnode');
        when(() => mockDb.getChangeset(modifiedAfter: any(named: 'modifiedAfter')))
            .thenAnswer((_) async => {});

        await backend.getChangeset(since: hlc);

        verify(() => mockDb.getChangeset(modifiedAfter: hlc)).called(1);
      });

      test('applyChangeset delegates to wrapper', () async {
        final changeset = <String, List<Map<String, Object?>>>{
          'users': [
            {'id': '1', 'name': 'John', 'hlc': 'timestamp'},
          ],
        };
        when(() => mockDb.merge(any())).thenAnswer((_) async {});

        await backend.applyChangeset(changeset);

        verify(() => mockDb.merge(changeset)).called(1);
      });

      test('nodeId returns wrapper nodeId', () async {
        expect(backend.nodeId, equals('test-node-id'));
      });
    });

    group('error handling', () {
      setUp(() async {
        await backend.initialize();
      });

      test('maps unique constraint errors to ValidationError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('UNIQUE constraint failed'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps foreign key errors to ValidationError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('foreign key constraint failed'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps database locked errors to TransactionError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('database is locked'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.TransactionError>()),
        );
      });

      test('maps busy errors to TransactionError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('SQLITE_BUSY'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.TransactionError>()),
        );
      });

      test('maps no such table errors to StateError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('no such table: users'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('maps unknown errors to SyncError', () async {
        when(() => mockDb.query(any(), any()))
            .thenThrow(Exception('unknown error'));

        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.SyncError>()),
        );
      });

      test('preserves existing StoreError', () async {
        const storeError = nexus.ValidationError(message: 'custom error');
        when(() => mockDb.query(any(), any())).thenThrow(storeError);

        await expectLater(
          () => backend.get('1'),
          throwsA(same(storeError)),
        );
      });

      test('maps error in save operation', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('UNIQUE constraint'));

        await expectLater(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.ValidationError>()),
        );
      });

      test('maps error in delete operation', () async {
        when(() => mockDb.execute(any(), any()))
            .thenThrow(Exception('database is locked'));

        await expectLater(
          () => backend.delete('1'),
          throwsA(isA<nexus.TransactionError>()),
        );
      });
    });

    group('uninitialized state', () {
      test('get throws StateError before initialize', () async {
        await expectLater(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getAll throws StateError before initialize', () async {
        await expectLater(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('save throws StateError before initialize', () async {
        await expectLater(
          () => backend.save(TestUser(id: '1', name: 'Test')),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('saveAll throws StateError before initialize', () async {
        await expectLater(
          () => backend.saveAll([TestUser(id: '1', name: 'Test')]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('delete throws StateError before initialize', () async {
        await expectLater(
          () => backend.delete('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('deleteAll throws StateError before initialize', () async {
        await expectLater(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watch throws StateError before initialize', () {
        expect(
          () => backend.watch('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('watchAll throws StateError before initialize', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('nodeId throws StateError before initialize', () {
        expect(
          () => backend.nodeId,
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('getChangeset throws StateError before initialize', () async {
        await expectLater(
          () => backend.getChangeset(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('applyChangeset throws StateError before initialize', () async {
        await expectLater(
          () => backend.applyChangeset({}),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('sync operations', () {
      setUp(() async {
        await backend.initialize();
      });

      test('syncStatus returns synced by default', () {
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream emits status changes', () async {
        expect(
          backend.syncStatusStream,
          emits(equals(nexus.SyncStatus.synced)),
        );
      });

      test('pendingChangesCount returns 0', () async {
        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });
    });
  });
}
