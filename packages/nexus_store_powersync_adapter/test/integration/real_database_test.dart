/// Integration tests using real PowerSync database.
///
/// These tests cover the DefaultPowerSyncDatabaseWrapper and actual
/// database CRUD operations that cannot be tested with mocks due to
/// PowerSync's final ResultSet class.
///
/// Note: These tests require the PowerSync native SQLite extension to be
/// available. They are skipped in environments where the native library
/// is not present (e.g., standard Dart test environments without native setup).
///
/// To run these tests:
/// 1. Ensure PowerSync native dependencies are installed
/// 2. Run with: dart test test/integration/real_database_test.dart --tags=real_db
@Tags(['integration', 'real_db'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:io';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

import '../test_config.dart';

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

// PowerSync schema for tests
const testSchema = ps.Schema([
  ps.Table(
    'users',
    [
      ps.Column.text('name'),
      ps.Column.integer('age'),
    ],
  ),
]);

void main() {
  group('Real Database Integration Tests', () {
    late ps.PowerSyncDatabase db;
    late PowerSyncBackend<TestUser, String> backend;
    late String dbPath;

    setUpAll(() async {
      // Create a unique database path for this test run
      final tempDir = Directory.systemTemp;
      dbPath = '${tempDir.path}/${TestConfig.testDatabasePath}';

      // Clean up any existing database
      final dbFile = File(dbPath);
      // ignore: avoid_slow_async_io
      if (await dbFile.exists()) {
        // ignore: avoid_slow_async_io
        await dbFile.delete();
      }
    });

    setUp(() async {
      // Create database for each test
      final tempDir = Directory.systemTemp;
      final uniqueId = DateTime.now().microsecondsSinceEpoch;
      dbPath = '${tempDir.path}/test_powersync_$uniqueId.db';

      db = ps.PowerSyncDatabase(
        schema: testSchema,
        path: dbPath,
      );

      await db.initialize();

      backend = PowerSyncBackend<TestUser, String>(
        db: db,
        tableName: 'users',
        getId: (user) => user.id,
        fromJson: TestUser.fromJson,
        toJson: (user) => user.toJson(),
      );

      await backend.initialize();
    });

    tearDown(() async {
      await backend.close();
      await db.close();

      // Clean up database file
      final dbFile = File(dbPath);
      // ignore: avoid_slow_async_io
      if (await dbFile.exists()) {
        // ignore: avoid_slow_async_io
        await dbFile.delete();
      }
    });

    group('DefaultPowerSyncDatabaseWrapper CRUD', () {
      test('save creates a new record', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);

        final result = await backend.save(user);

        expect(result.id, equals('1'));
        expect(result.name, equals('Alice'));
        expect(result.age, equals(30));
      });

      test('save updates existing record (upsert)', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);
        await backend.save(user);

        final updated = TestUser(id: '1', name: 'Alice Updated', age: 31);
        final result = await backend.save(updated);

        expect(result.id, equals('1'));
        expect(result.name, equals('Alice Updated'));
        expect(result.age, equals(31));
      });

      test('get retrieves existing record', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);
        await backend.save(user);

        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
        expect(result.name, equals('Alice'));
      });

      test('get returns null for non-existent id', () async {
        final result = await backend.get('non-existent');

        expect(result, isNull);
      });

      test('getAll returns all records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));

        final results = await backend.getAll();

        expect(results, hasLength(2));
        expect(results.map((u) => u.name), containsAll(['Alice', 'Bob']));
      });

      test('getAll with query filters results', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));

        final query = const nexus.Query<TestUser>().where(
          'age',
          isGreaterThanOrEqualTo: 30,
        );

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
        expect(
          results.map((u) => u.name),
          containsAll(['Alice', 'Charlie']),
        );
      });

      test('delete removes existing record', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final deleted = await backend.delete('1');

        expect(deleted, isTrue);

        final result = await backend.get('1');
        expect(result, isNull);
      });

      test('delete returns false for non-existent record', () async {
        final deleted = await backend.delete('non-existent');

        expect(deleted, isFalse);
      });

      test('deleteAll removes multiple records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));

        final count = await backend.deleteAll(['1', '2']);

        expect(count, equals(2));

        final remaining = await backend.getAll();
        expect(remaining, hasLength(1));
        expect(remaining.first.name, equals('Charlie'));
      });

      test('deleteWhere removes records matching query', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));

        final query = const nexus.Query<TestUser>().where(
          'age',
          isLessThan: 30,
        );

        await backend.deleteWhere(query);

        final remaining = await backend.getAll();
        expect(remaining, hasLength(2));
        expect(remaining.map((u) => u.name), isNot(contains('Bob')));
      });

      test('saveAll inserts multiple records in transaction', () async {
        final users = [
          TestUser(id: '1', name: 'Alice', age: 30),
          TestUser(id: '2', name: 'Bob', age: 25),
          TestUser(id: '3', name: 'Charlie', age: 35),
        ];

        final results = await backend.saveAll(users);

        expect(results, hasLength(3));

        final all = await backend.getAll();
        expect(all, hasLength(3));
      });
    });

    group('DefaultPowerSyncDatabaseWrapper watch', () {
      test('watch returns stream for record', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');
        final firstValue = await stream.first;

        expect(firstValue, isNotNull);
        expect(firstValue!.name, equals('Alice'));
      });

      test('watch emits updates when record changes', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');
        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Update the record
        await backend.save(TestUser(id: '1', name: 'Alice Updated', age: 31));

        // Wait for update
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(values.length, greaterThanOrEqualTo(1));
        expect(values.any((u) => u?.name == 'Alice'), isTrue);
      });

      test('watch emits null when record is deleted', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');
        final values = <TestUser?>[];
        final subscription = stream.listen(values.add);

        // Wait for initial value
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Delete the record
        await backend.delete('1');

        // Wait for update
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        // Last value should be null after deletion
        expect(values.last, isNull);
      });

      test('watchAll returns stream for all records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));

        final stream = backend.watchAll();
        final firstValue = await stream.first;

        expect(firstValue, hasLength(2));
      });

      test('watchAll with query filters stream', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));

        final query = const nexus.Query<TestUser>().where(
          'age',
          isGreaterThanOrEqualTo: 30,
        );

        final stream = backend.watchAll(query: query);
        final firstValue = await stream.first;

        expect(firstValue, hasLength(1));
        expect(firstValue.first.name, equals('Alice'));
      });
    });

    group('DefaultPowerSyncDatabaseWrapper transactions', () {
      test('writeTransaction commits multiple operations atomically', () async {
        final users = [
          TestUser(id: '1', name: 'Alice', age: 30),
          TestUser(id: '2', name: 'Bob', age: 25),
        ];

        await backend.saveAll(users);

        final all = await backend.getAll();
        expect(all, hasLength(2));
      });

      test('saveAll with empty list returns empty', () async {
        final results = await backend.saveAll([]);

        expect(results, isEmpty);
      });
    });

    group('DefaultPowerSyncDatabaseWrapper sync status', () {
      test('statusStream emits sync status', () async {
        // The wrapper should provide access to status stream
        expect(backend.syncStatusStream, isA<Stream<nexus.SyncStatus>>());
      });

      test('currentStatus is accessible', () async {
        expect(backend.syncStatus, isA<nexus.SyncStatus>());
      });
    });

    group('Pagination with real database', () {
      setUp(() async {
        // Add test data for pagination
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestUser(
            id: '$i',
            name: 'User $i',
            age: 20 + i,
          ),);
        }
      });

      test('getAllPaged returns first page', () async {
        final query = const nexus.Query<TestUser>().first(3);

        final result = await backend.getAllPaged(query: query);

        expect(result.items, hasLength(3));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(10));
      });

      test('getAllPaged with cursor returns next page', () async {
        // Get first page
        final firstQuery = const nexus.Query<TestUser>().first(3);
        final firstPage = await backend.getAllPaged(query: firstQuery);

        // Get second page using end cursor
        final secondQuery = const nexus.Query<TestUser>()
            .first(3)
            .after(firstPage.pageInfo.endCursor!);

        final secondPage = await backend.getAllPaged(query: secondQuery);

        expect(secondPage.items, hasLength(3));
        expect(secondPage.pageInfo.hasPreviousPage, isTrue);
        expect(secondPage.pageInfo.hasNextPage, isTrue);
      });

      test('watchAllPaged returns paginated stream', () async {
        final query = const nexus.Query<TestUser>().first(3);

        final stream = backend.watchAllPaged(query: query);
        final firstValue = await stream.first;

        expect(firstValue.items, hasLength(3));
        expect(firstValue.pageInfo.hasNextPage, isTrue);
      });
    });

    group('Query operations with real database', () {
      setUp(() async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));
        await backend.save(TestUser(id: '4', name: 'Alice Jr', age: 22));
      });

      test('query with orderBy sorts results', () async {
        final query =
            const nexus.Query<TestUser>().orderByField('age', descending: true);

        final results = await backend.getAll(query: query);

        expect(results.first.name, equals('Charlie'));
        expect(results.last.name, equals('Alice Jr'));
      });

      test('query with limit returns limited results', () async {
        final query = const nexus.Query<TestUser>().limitTo(2);

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
      });

      test('query with offset skips results', () async {
        final query = const nexus.Query<TestUser>().offsetBy(2);

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
      });

      test('query with whereIn filters to specific values', () async {
        final query = const nexus.Query<TestUser>().where(
          'id',
          whereIn: ['1', '3'],
        );

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
        expect(results.map((u) => u.name), containsAll(['Alice', 'Charlie']));
      });

      test('query with isNull filters null values', () async {
        await backend.save(TestUser(id: '5', name: 'NoAge'));

        final query = const nexus.Query<TestUser>().where('age', isNull: true);

        final results = await backend.getAll(query: query);

        expect(results.any((u) => u.name == 'NoAge'), isTrue);
      });
    });
  });
}
