// ignore_for_file: unreachable_from_main

@Tags(['integration'])
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

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

  TestModel copyWith({String? id, String? name, int? age}) => TestModel(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
      );

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

// Minimal Drift database for testing
@DriftDatabase()
class _TestDatabase extends GeneratedDatabase {
  _TestDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, DataClass>> get allTables => [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Create test table
          await customStatement('''
            CREATE TABLE IF NOT EXISTS test_models (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              age INTEGER
            )
          ''');
        },
      );
}

void main() {
  group('Drift Integration Tests', () {
    late _TestDatabase testDb;
    late DriftBackend<TestModel, String> backend;

    setUpAll(() async {
      // Create in-memory database
      testDb = _TestDatabase(NativeDatabase.memory());

      // Run migrations to create table
      await testDb.customStatement('''
        CREATE TABLE IF NOT EXISTS test_models (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          age INTEGER
        )
      ''');

      // Create and initialize backend
      backend = DriftBackend<TestModel, String>(
        tableName: 'test_models',
        getId: (model) => model.id,
        fromJson: TestModel.fromJson,
        toJson: (model) => model.toJson(),
        primaryKeyField: 'id',
      );

      await backend.initializeWithExecutor(testDb);
    });

    tearDownAll(() async {
      await backend.close();
      await testDb.close();
    });

    setUp(() async {
      // Clear table before each test
      await testDb.customStatement('DELETE FROM test_models');
    });

    group('Database Operations (CRUD)', () {
      test('save() creates a new record', () async {
        final model = TestModel(id: '1', name: 'Alice', age: 30);

        final result = await backend.save(model);

        expect(result, equals(model));

        final retrieved = await backend.get('1');
        expect(retrieved, equals(model));
      });

      test('save() updates existing record (upsert)', () async {
        final original = TestModel(id: '1', name: 'Alice', age: 30);
        await backend.save(original);

        final updated = TestModel(id: '1', name: 'Alice Updated', age: 31);
        await backend.save(updated);

        final retrieved = await backend.get('1');
        expect(retrieved, equals(updated));
        expect(retrieved?.name, equals('Alice Updated'));
        expect(retrieved?.age, equals(31));
      });

      test('saveAll() batch inserts multiple records', () async {
        final models = [
          TestModel(id: '1', name: 'Alice', age: 30),
          TestModel(id: '2', name: 'Bob', age: 25),
          TestModel(id: '3', name: 'Charlie', age: 35),
        ];

        final results = await backend.saveAll(models);

        expect(results.length, equals(3));

        final all = await backend.getAll();
        expect(all.length, equals(3));
      });

      test('get() returns null for non-existent ID', () async {
        final result = await backend.get('non-existent');

        expect(result, isNull);
      });

      test('getAll() returns all records', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));

        final all = await backend.getAll();

        expect(all.length, equals(2));
      });

      test('getAll() with equals filter', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Alice', age: 35));

        final query =
            const nexus.Query<TestModel>().where('name', isEqualTo: 'Alice');
        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results.every((m) => m.name == 'Alice'), isTrue);
      });

      test('getAll() with comparison filters', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final query =
            const nexus.Query<TestModel>().where('age', isGreaterThan: 28);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results.every((m) => m.age! > 28), isTrue);
      });

      test('getAll() with ordering', () async {
        await backend.save(TestModel(id: '1', name: 'Charlie', age: 30));
        await backend.save(TestModel(id: '2', name: 'Alice', age: 25));
        await backend.save(TestModel(id: '3', name: 'Bob', age: 35));

        final query = const nexus.Query<TestModel>().orderByField('name');
        final results = await backend.getAll(query: query);

        expect(results.length, equals(3));
        expect(results[0].name, equals('Alice'));
        expect(results[1].name, equals('Bob'));
        expect(results[2].name, equals('Charlie'));
      });

      test('getAll() with descending ordering', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final query = const nexus.Query<TestModel>()
            .orderByField('age', descending: true);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(3));
        expect(results[0].age, equals(35));
        expect(results[1].age, equals(30));
        expect(results[2].age, equals(25));
      });

      test('getAll() with pagination (limit)', () async {
        for (var i = 1; i <= 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().limitTo(3);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(3));
      });

      test('getAll() with pagination (limit and offset)', () async {
        for (var i = 1; i <= 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>()
            .orderByField('id')
            .limitTo(2)
            .offsetBy(2);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results[0].id, equals('3'));
        expect(results[1].id, equals('4'));
      });

      test('delete() removes record and returns true', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final deleted = await backend.delete('1');

        expect(deleted, isTrue);

        final retrieved = await backend.get('1');
        expect(retrieved, isNull);
      });

      test('delete() returns false for non-existent ID', () async {
        final deleted = await backend.delete('non-existent');

        expect(deleted, isFalse);
      });

      test('deleteAll() removes multiple records', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final deleted = await backend.deleteAll(['1', '2']);

        expect(deleted, equals(2));

        final remaining = await backend.getAll();
        expect(remaining.length, equals(1));
        expect(remaining[0].id, equals('3'));
      });

      test('deleteWhere() removes matching records', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final query =
            const nexus.Query<TestModel>().where('age', isLessThan: 32);
        final deleted = await backend.deleteWhere(query);

        expect(deleted, equals(2));

        final remaining = await backend.getAll();
        expect(remaining.length, equals(1));
        expect(remaining[0].name, equals('Charlie'));
      });

      test('getAll() with whereIn filter', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));
        await backend.save(TestModel(id: '3', name: 'Charlie', age: 35));

        final query = const nexus.Query<TestModel>()
            .where('name', whereIn: ['Alice', 'Charlie']);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results.map((m) => m.name), containsAll(['Alice', 'Charlie']));
      });

      test('getAll() with isNull filter', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob'));
        await backend.save(TestModel(id: '3', name: 'Charlie'));

        final query = const nexus.Query<TestModel>().where('age', isNull: true);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(2));
        expect(results.every((m) => m.age == null), isTrue);
      });
    });

    group('Watch Operations', () {
      test('watch() emits initial value', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');

        await expectLater(
          stream.first,
          completion(equals(TestModel(id: '1', name: 'Alice', age: 30))),
        );
      });

      test('watch() emits null for non-existent ID', () async {
        final stream = backend.watch('non-existent');

        await expectLater(stream.first, completion(isNull));
      });

      test('watchAll() emits initial list', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Bob', age: 25));

        final stream = backend.watchAll();
        final first = await stream.first;

        expect(first.length, equals(2));
      });

      test('watch() with unique query returns fresh stream', () async {
        await backend.save(TestModel(id: 'unique-1', name: 'Test', age: 99));

        // Using a unique query ensures no caching interference
        final query =
            const nexus.Query<TestModel>().where('age', isEqualTo: 99);
        final stream = backend.watchAll(query: query);
        final results = await stream.first;

        expect(results.length, equals(1));
        expect(results[0].name, equals('Test'));
      });
    });

    group('Transaction Behavior', () {
      test('saveAll() inserts all items in transaction', () async {
        final models = List.generate(
          10,
          (i) => TestModel(id: '${i + 1}', name: 'User${i + 1}', age: 20 + i),
        );

        await backend.saveAll(models);

        final all = await backend.getAll();
        expect(all.length, equals(10));
      });

      test('deleteAll() deletes all items in transaction', () async {
        final models = List.generate(
          10,
          (i) => TestModel(id: '${i + 1}', name: 'User${i + 1}', age: 20 + i),
        );
        await backend.saveAll(models);

        final ids = models.map((m) => m.id).toList();
        final deleted = await backend.deleteAll(ids);

        expect(deleted, equals(10));

        final remaining = await backend.getAll();
        expect(remaining, isEmpty);
      });

      test('deleteAll() with empty list returns 0', () async {
        final deleted = await backend.deleteAll([]);

        expect(deleted, equals(0));
      });
    });

    group('Sync Status (Local-Only)', () {
      test('syncStatus is always synced', () {
        expect(backend.syncStatus, equals(nexus.SyncStatus.synced));
      });

      test('syncStatusStream emits synced', () async {
        final status = await backend.syncStatusStream.first;
        expect(status, equals(nexus.SyncStatus.synced));
      });

      test('sync() completes immediately', () async {
        await expectLater(backend.sync(), completes);
      });

      test('pendingChangesCount is always 0', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));

        final count = await backend.pendingChangesCount;
        expect(count, equals(0));
      });
    });

    group('Cursor-Based Pagination', () {
      test('getAllPaged returns first page with cursor info', () async {
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(5);
        final result = await backend.getAllPaged(query: query);

        expect(result.items.length, equals(5));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(10));
        expect(result.pageInfo.startCursor, isNotNull);
        expect(result.pageInfo.endCursor, isNotNull);
      });

      test('getAllPaged navigates with afterCursor', () async {
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Get first page
        final firstQuery = const nexus.Query<TestModel>().first(5);
        final firstPage = await backend.getAllPaged(query: firstQuery);

        // Get second page using endCursor
        final secondQuery = const nexus.Query<TestModel>()
            .first(5)
            .after(firstPage.pageInfo.endCursor!);
        final secondPage = await backend.getAllPaged(query: secondQuery);

        expect(secondPage.items.length, equals(5));
        expect(secondPage.pageInfo.hasNextPage, isFalse);
        expect(secondPage.pageInfo.hasPreviousPage, isTrue);
      });

      test('getAllPaged returns empty page for out-of-bounds cursor', () async {
        for (var i = 1; i <= 3; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        // Create cursor beyond data bounds
        final cursor = nexus.Cursor.fromValues(const {'_index': 100});
        final query = const nexus.Query<TestModel>().first(5).after(cursor);
        final result = await backend.getAllPaged(query: query);

        expect(result.items, isEmpty);
        expect(result.pageInfo.hasNextPage, isFalse);
      });

      test('getAllPaged without firstCount returns all items', () async {
        for (var i = 1; i <= 5; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final result = await backend.getAllPaged();

        expect(result.items.length, equals(5));
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.totalCount, equals(5));
      });

      test('getAllPaged with query filters', () async {
        for (var i = 1; i <= 10; i++) {
          final name = i <= 5 ? 'GroupA' : 'GroupB';
          await backend.save(TestModel(id: '$i', name: name, age: 20 + i));
        }

        final query = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'GroupA')
            .first(3);
        final result = await backend.getAllPaged(query: query);

        expect(result.items.length, equals(3));
        expect(result.items.every((m) => m.name == 'GroupA'), isTrue);
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.totalCount, equals(5));
      });

      test('watchAllPaged emits paged results', () async {
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final query = const nexus.Query<TestModel>().first(5);
        final stream = backend.watchAllPaged(query: query);
        final result = await stream.first;

        expect(result.items.length, equals(5));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.totalCount, equals(10));
      });

      test('watchAllPaged with afterCursor', () async {
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final cursor = nexus.Cursor.fromValues(const {'_index': 5});
        final query = const nexus.Query<TestModel>().first(3).after(cursor);
        final stream = backend.watchAllPaged(query: query);
        final result = await stream.first;

        expect(result.items.length, equals(3));
        expect(result.pageInfo.hasPreviousPage, isTrue);
        expect(result.pageInfo.hasNextPage, isTrue);
      });

      test('watchAllPaged with out-of-bounds cursor returns empty', () async {
        for (var i = 1; i <= 3; i++) {
          await backend.save(TestModel(id: '$i', name: 'User$i', age: 20 + i));
        }

        final cursor = nexus.Cursor.fromValues(const {'_index': 100});
        final query = const nexus.Query<TestModel>().first(5).after(cursor);
        final stream = backend.watchAllPaged(query: query);
        final result = await stream.first;

        expect(result.items, isEmpty);
        expect(result.pageInfo.hasNextPage, isFalse);
      });

      test('getAllPaged empty result has no cursors', () async {
        final result = await backend.getAllPaged();

        expect(result.items, isEmpty);
        expect(result.pageInfo.startCursor, isNull);
        expect(result.pageInfo.endCursor, isNull);
        expect(result.pageInfo.hasNextPage, isFalse);
        expect(result.pageInfo.hasPreviousPage, isFalse);
      });
    });

    group('Pending Changes Operations', () {
      test('pendingChangesStream emits empty list initially', () async {
        final changes = await backend.pendingChangesStream.first;
        expect(changes, isEmpty);
      });

      test('conflictsStream is accessible', () {
        // Just verify we can access the stream without errors
        expect(backend.conflictsStream, isNotNull);
      });

      test('retryChange with non-existent ID does nothing', () async {
        // Should complete without error
        await expectLater(
          backend.retryChange('non-existent-change-id'),
          completes,
        );
      });

      test('cancelChange with non-existent ID returns null', () async {
        final result = await backend.cancelChange('non-existent-change-id');
        expect(result, isNull);
      });
    });

    group('Complex Queries', () {
      test('multiple filters combined with AND', () async {
        await backend.save(TestModel(id: '1', name: 'Alice', age: 30));
        await backend.save(TestModel(id: '2', name: 'Alice', age: 25));
        await backend.save(TestModel(id: '3', name: 'Bob', age: 30));

        final query = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'Alice')
            .where('age', isGreaterThanOrEqualTo: 30);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(1));
        expect(results[0].id, equals('1'));
      });

      test('filter + orderBy + pagination combined', () async {
        for (var i = 1; i <= 10; i++) {
          await backend.save(
            TestModel(id: '$i', name: i <= 5 ? 'GroupA' : 'GroupB', age: i * 5),
          );
        }

        final query = const nexus.Query<TestModel>()
            .where('name', isEqualTo: 'GroupA')
            .orderByField('age', descending: true)
            .limitTo(3);
        final results = await backend.getAll(query: query);

        expect(results.length, equals(3));
        expect(results[0].age, equals(25)); // Highest age in GroupA
        expect(results[1].age, equals(20));
        expect(results[2].age, equals(15));
      });
    });
  });
}
