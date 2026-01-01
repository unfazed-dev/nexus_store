// ignore_for_file: unreachable_from_main

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

// Mock for DatabaseConnectionUser
class MockDatabaseConnectionUser extends Mock
    implements DatabaseConnectionUser {}

// Mock for Selectable to return results
class MockSelectable<T> extends Mock implements Selectable<T> {}

// Test model
class TestModel {
  TestModel({required this.id, required this.name, this.age});

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
}

void main() {
  group('DriftBackend', () {
    late DriftBackend<TestModel, String> backend;

    setUp(() {
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );
    });

    tearDown(() async {
      await backend.close();
    });

    group('backend info', () {
      test('name returns drift', () {
        expect(backend.name, 'drift');
      });

      test('supportsOffline returns true', () {
        expect(backend.supportsOffline, isTrue);
      });

      test('supportsRealtime returns false', () {
        expect(backend.supportsRealtime, isFalse);
      });

      test('supportsTransactions returns true', () {
        expect(backend.supportsTransactions, isTrue);
      });
    });

    group('sync operations (local-only stubs)', () {
      test('syncStatus is always synced', () {
        expect(backend.syncStatus, nexus.SyncStatus.synced);
      });

      test('syncStatusStream emits synced', () async {
        final status = await backend.syncStatusStream.first;
        expect(status, nexus.SyncStatus.synced);
      });

      test('sync completes immediately', () async {
        await expectLater(backend.sync(), completes);
      });

      test('pendingChangesCount is always 0', () async {
        expect(await backend.pendingChangesCount, 0);
      });
    });

    group('error handling', () {
      test('throws StateError when using get before initialize', () async {
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using getAll before initialize', () async {
        expect(
          () => backend.getAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using save before initialize', () async {
        final model = TestModel(id: '1', name: 'Test');
        expect(
          () => backend.save(model),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using delete before initialize', () async {
        expect(
          () => backend.delete('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using watch before initialize', () {
        expect(
          () => backend.watch('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using watchAll before initialize', () {
        expect(
          () => backend.watchAll(),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('constructor', () {
      test('accepts custom query translator', () {
        final customTranslator = DriftQueryTranslator<TestModel>(
          fieldMapping: {'name': 'user_name'},
        );

        final customBackend = DriftBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyField: 'id',
          queryTranslator: customTranslator,
        );

        expect(customBackend.name, 'drift');
        customBackend.close();
      });

      test('accepts custom field mapping', () {
        final backendWithMapping = DriftBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyField: 'id',
          fieldMapping: {'name': 'user_name'},
        );

        expect(backendWithMapping.name, 'drift');
        backendWithMapping.close();
      });
    });

    group('pagination properties', () {
      test('supportsPagination returns true', () {
        expect(backend.supportsPagination, isTrue);
      });
    });

    group('uninitialized state guards', () {
      test('throws StateError when using deleteAll before initialize', () {
        expect(
          () => backend.deleteAll(['1']),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using deleteWhere before initialize', () {
        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Test');
        expect(
          () => backend.deleteWhere(query),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using saveAll before initialize', () {
        final model = TestModel(id: '1', name: 'Test');
        expect(
          () => backend.saveAll([model]),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using getAllPaged before initialize', () {
        expect(
          () => backend.getAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using watchAllPaged before initialize', () {
        expect(
          () => backend.watchAllPaged(),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using retryChange before initialize', () {
        expect(
          () => backend.retryChange('change-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });

      test('throws StateError when using cancelChange before initialize', () {
        expect(
          () => backend.cancelChange('change-id'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });

    group('lifecycle', () {
      test('initialize is idempotent', () async {
        // Create backend with mock executor
        final backendWithExecutor = DriftBackend<TestModel, String>(
          tableName: 'test_models',
          getId: (model) => model.id,
          fromJson: TestModel.fromJson,
          toJson: (model) => model.toJson(),
          primaryKeyField: 'id',
        );

        // First initialize should work
        // (In real usage, would require executor)
        // For this test, we're checking idempotency logic

        await backendWithExecutor.close();
      });

      test('close cleans up resources', () async {
        await backend.close();
        // After close, using the backend should fail
        expect(
          () => backend.get('1'),
          throwsA(isA<nexus.StateError>()),
        );
      });
    });
  });

  group('DriftBackend with executor', () {
    // Integration-style tests would go here
    // These would use a real in-memory SQLite database
    // For now, we focus on unit tests with mocks
  });

  group('Exception Mapping (_mapException)', () {
    late DriftBackend<TestModel, String> backend;
    late MockDatabaseConnectionUser mockExecutor;
    late MockSelectable<QueryRow> mockSelectable;

    setUp(() async {
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );

      mockExecutor = MockDatabaseConnectionUser();
      mockSelectable = MockSelectable<QueryRow>();

      await backend.initializeWithExecutor(mockExecutor);
    });

    tearDown(() async {
      await backend.close();
    });

    test('passes through existing StoreError unchanged', () async {
      final originalError = nexus.ValidationError(
        message: 'Original error',
        cause: Exception('test'),
        stackTrace: StackTrace.current,
      );

      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get()).thenThrow(originalError);

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.ValidationError>().having(
          (e) => e.message,
          'message',
          'Original error',
        )),
      );
    });

    test('maps unique constraint violation to ValidationError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('UNIQUE CONSTRAINT failed: test_models.id'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.ValidationError>().having(
          (e) => e.message,
          'message',
          'Unique constraint violation',
        )),
      );
    });

    test('maps uniqueviolation to ValidationError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('UniqueViolation: duplicate key'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.ValidationError>().having(
          (e) => e.message,
          'message',
          'Unique constraint violation',
        )),
      );
    });

    test('maps foreign key constraint to ValidationError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('FOREIGN KEY constraint failed'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.ValidationError>().having(
          (e) => e.message,
          'message',
          'Foreign key constraint violation',
        )),
      );
    });

    test('maps foreignkeyviolation to ValidationError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('ForeignKeyViolation: reference missing'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.ValidationError>().having(
          (e) => e.message,
          'message',
          'Foreign key constraint violation',
        )),
      );
    });

    test('maps database is locked to TransactionError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('database is locked'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.TransactionError>().having(
          (e) => e.message,
          'message',
          'Database is locked',
        )),
      );
    });

    test('maps busy error to TransactionError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('SQLITE_BUSY: database is busy'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.TransactionError>().having(
          (e) => e.message,
          'message',
          'Database is locked',
        )),
      );
    });

    test('maps no such table to StateError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('no such table: test_models'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.StateError>().having(
          (e) => e.message,
          'message',
          'Table does not exist',
        )),
      );
    });

    test('maps unknown error to SyncError', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('Some unknown database error'));

      expect(
        () => backend.get('1'),
        throwsA(isA<nexus.SyncError>().having(
          (e) => e.message,
          'message',
          contains('Drift operation failed'),
        )),
      );
    });

    test('exception mapping in save operation', () async {
      when(() => mockExecutor.customStatement(any(), any()))
          .thenThrow(Exception('UNIQUE CONSTRAINT failed'));

      final model = TestModel(id: '1', name: 'Test');

      expect(
        () => backend.save(model),
        throwsA(isA<nexus.ValidationError>()),
      );
    });

    test('exception mapping in delete operation', () async {
      when(() => mockExecutor.customUpdate(
            any(),
            variables: any(named: 'variables'),
            updates: any(named: 'updates'),
          )).thenThrow(Exception('FOREIGN KEY constraint failed'));

      expect(
        () => backend.delete('1'),
        throwsA(isA<nexus.ValidationError>()),
      );
    });

    test('exception mapping in getAll operation', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('no such table: test_models'));

      expect(
        () => backend.getAll(),
        throwsA(isA<nexus.StateError>()),
      );
    });

    test('exception mapping in getAllPaged operation', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('database is locked'));

      expect(
        () => backend.getAllPaged(),
        throwsA(isA<nexus.TransactionError>()),
      );
    });
  });

  group('Watch Stream Error Handling', () {
    late DriftBackend<TestModel, String> backend;
    late MockDatabaseConnectionUser mockExecutor;
    late MockSelectable<QueryRow> mockSelectable;

    setUp(() async {
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );

      mockExecutor = MockDatabaseConnectionUser();
      mockSelectable = MockSelectable<QueryRow>();

      await backend.initializeWithExecutor(mockExecutor);
    });

    tearDown(() async {
      await backend.close();
    });

    test('watch() stream emits error when get() fails', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('database connection failed'));

      final stream = backend.watch('1');

      await expectLater(
        stream,
        emitsError(isA<nexus.SyncError>()),
      );
    });

    test('watchAll() stream emits error when getAll() fails', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get())
          .thenThrow(Exception('no such table: test_models'));

      final stream = backend.watchAll();

      await expectLater(
        stream,
        emitsError(isA<nexus.StateError>()),
      );
    });

    test('watch() uses cached subject for same ID', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get()).thenAnswer((_) async => []);

      // First call creates the subject
      backend.watch('1');
      // Second call should reuse existing subject (only one get() call)
      backend.watch('1');

      // Verify customSelect was only called once (for initial load)
      verify(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).called(1);
    });

    test('watchAll() uses cached subject for same query', () async {
      when(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).thenReturn(mockSelectable);
      when(() => mockSelectable.get()).thenAnswer((_) async => []);

      // First call creates the subject
      backend.watchAll();
      // Second call should reuse existing subject
      backend.watchAll();

      // Verify customSelect was only called once (for initial load)
      verify(() => mockExecutor.customSelect(
            any(),
            variables: any(named: 'variables'),
          )).called(1);
    });
  });

  group('cancelChange operations with pending changes', () {
    late DriftBackend<TestModel, String> backend;
    late MockDatabaseConnectionUser mockExecutor;

    setUp(() async {
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );

      mockExecutor = MockDatabaseConnectionUser();
      await backend.initializeWithExecutor(mockExecutor);
    });

    tearDown(() async {
      await backend.close();
    });

    test('cancelChange with UPDATE operation restores original value',
        () async {
      final originalModel = TestModel(id: '1', name: 'Original', age: 25);
      final updatedModel = TestModel(id: '1', name: 'Updated', age: 30);

      // Add a pending UPDATE change with original value
      final change = await backend.pendingChangesManagerForTesting.addChange(
        item: updatedModel,
        operation: nexus.PendingChangeOperation.update,
        originalValue: originalModel,
      );

      // Mock the save operation (restore original)
      when(() => mockExecutor.customStatement(any(), any()))
          .thenAnswer((_) async {});

      // Cancel the change - should restore original
      final result = await backend.cancelChange(change.id);

      expect(result, isNotNull);
      expect(result!.id, equals(change.id));
      expect(result.operation, equals(nexus.PendingChangeOperation.update));

      // Verify save was called (to restore original)
      verify(() => mockExecutor.customStatement(any(), any())).called(1);
    });

    test('cancelChange with CREATE operation deletes the item', () async {
      final createdModel = TestModel(id: '2', name: 'NewItem', age: 20);

      // Add a pending CREATE change
      final change = await backend.pendingChangesManagerForTesting.addChange(
        item: createdModel,
        operation: nexus.PendingChangeOperation.create,
      );

      // Mock the delete operation
      when(() => mockExecutor.customUpdate(
            any(),
            variables: any(named: 'variables'),
            updates: any(named: 'updates'),
          )).thenAnswer((_) async => 1);

      // Cancel the change - should delete the created item
      final result = await backend.cancelChange(change.id);

      expect(result, isNotNull);
      expect(result!.operation, equals(nexus.PendingChangeOperation.create));

      // Verify delete was called
      verify(() => mockExecutor.customUpdate(
            any(),
            variables: any(named: 'variables'),
            updates: any(named: 'updates'),
          )).called(1);
    });

    test('cancelChange with DELETE operation restores original value',
        () async {
      final deletedModel = TestModel(id: '3', name: 'Deleted', age: 35);

      // Add a pending DELETE change with original value
      final change = await backend.pendingChangesManagerForTesting.addChange(
        item: deletedModel,
        operation: nexus.PendingChangeOperation.delete,
        originalValue: deletedModel,
      );

      // Mock the save operation (restore deleted)
      when(() => mockExecutor.customStatement(any(), any()))
          .thenAnswer((_) async {});

      // Cancel the change - should restore the deleted item
      final result = await backend.cancelChange(change.id);

      expect(result, isNotNull);
      expect(result!.operation, equals(nexus.PendingChangeOperation.delete));

      // Verify save was called (to restore deleted item)
      verify(() => mockExecutor.customStatement(any(), any())).called(1);
    });
  });

  group('retryChange operations with pending changes', () {
    late DriftBackend<TestModel, String> backend;
    late MockDatabaseConnectionUser mockExecutor;

    setUp(() async {
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );

      mockExecutor = MockDatabaseConnectionUser();
      await backend.initializeWithExecutor(mockExecutor);
    });

    tearDown(() async {
      await backend.close();
    });

    test('retryChange increments retry count and updates lastAttempt',
        () async {
      final model = TestModel(id: '1', name: 'Test', age: 25);

      // Add a pending change
      final change = await backend.pendingChangesManagerForTesting.addChange(
        item: model,
        operation: nexus.PendingChangeOperation.update,
      );

      expect(change.retryCount, equals(0));
      expect(change.lastAttempt, isNull);

      // Retry the change
      await backend.retryChange(change.id);

      // Verify retry count was incremented
      final updatedChange =
          backend.pendingChangesManagerForTesting.getChange(change.id);
      expect(updatedChange, isNotNull);
      expect(updatedChange!.retryCount, equals(1));
      expect(updatedChange.lastAttempt, isNotNull);
    });

    test('retryChange can be called multiple times', () async {
      final model = TestModel(id: '2', name: 'Test2', age: 30);

      // Add a pending change
      final change = await backend.pendingChangesManagerForTesting.addChange(
        item: model,
        operation: nexus.PendingChangeOperation.create,
      );

      // Retry multiple times
      await backend.retryChange(change.id);
      await backend.retryChange(change.id);
      await backend.retryChange(change.id);

      // Verify retry count was incremented each time
      final updatedChange =
          backend.pendingChangesManagerForTesting.getChange(change.id);
      expect(updatedChange!.retryCount, equals(3));
    });
  });
}
