/// Integration tests using real PowerSync database.
///
/// These tests cover the DefaultPowerSyncDatabaseWrapper and actual
/// database CRUD operations that cannot be tested with mocks due to
/// PowerSync's final ResultSet class.
///
/// ## Requirements
///
/// These tests require:
/// 1. **PowerSync native library** (`libpowersync.dylib` / `.so` / `.dll`)
/// 2. **SQLite with extension loading support** (Homebrew SQLite on macOS)
///
/// Tests are **automatically skipped** when requirements are not met,
/// so running without setup will not cause failures.
///
/// ## Setup
///
/// ### Step 1: Install Homebrew SQLite (macOS)
/// ```bash
/// brew install sqlite
/// ```
///
/// ### Step 2: Download PowerSync binary
/// ```bash
/// ./scripts/download_powersync_binary.sh
/// ```
/// Or manually from: https://github.com/powersync-ja/powersync-sqlite-core/releases
///
/// ## Running Tests
///
/// ```bash
/// dart test test/integration/real_database_test.dart
/// # or
/// dart test --tags=real_db
/// ```
@Tags(['integration', 'real_db'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:io';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

// ignore: unused_import
import '../test_config.dart';
import '../test_utils/powersync_test_utils.dart';

/// Tracks whether PowerSync native library is available.
/// Set in setUpAll, checked in tests to skip if unavailable.
bool _nativeLibraryAvailable = false;
String? _skipReason;

/// Runs a test only if PowerSync native library is available.
/// Otherwise, marks the test as skipped.
void testWithNativeLib(
  String description,
  Future<void> Function() body, {
  Object? skip,
}) {
  test(
    description,
    () async {
      if (!_nativeLibraryAvailable) {
        markTestSkipped(
          _skipReason ?? 'PowerSync native library not available',
        );
        return;
      }
      await body();
    },
    skip: skip,
  );
}

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
      // Check if PowerSync library and Homebrew SQLite are available
      if (!isHomebrewSqliteAvailable()) {
        _skipReason = 'Homebrew SQLite not installed. Run: brew install sqlite';
        _nativeLibraryAvailable = false;
        return;
      }

      final (available, error) = checkPowerSyncLibraryAvailable();
      if (!available) {
        _skipReason = error;
        _nativeLibraryAvailable = false;
        return;
      }

      // Verify by creating a test database using our custom factory
      final tempDir = Directory.systemTemp;
      final testPath =
          '${tempDir.path}/powersync_check_${DateTime.now().microsecondsSinceEpoch}.db';

      try {
        final testDb = createTestPowerSyncDatabase(
          schema: testSchema,
          path: testPath,
        );
        await testDb.initialize();
        await testDb.close();

        // Clean up test database
        final testFile = File(testPath);
        if (testFile.existsSync()) {
          testFile.deleteSync();
        }

        _nativeLibraryAvailable = true;
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        // Catches any remaining errors during database initialization
        _skipReason = 'PowerSync database initialization failed: $e';
        _nativeLibraryAvailable = false;
      }
    });

    setUp(() async {
      // Skip setup if native library is not available
      if (!_nativeLibraryAvailable) return;

      // Create database for each test using our custom factory
      final tempDir = Directory.systemTemp;
      final uniqueId = DateTime.now().microsecondsSinceEpoch;
      dbPath = '${tempDir.path}/test_powersync_$uniqueId.db';

      db = createTestPowerSyncDatabase(
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
      // Skip teardown if native library was not available
      if (!_nativeLibraryAvailable) return;

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
      testWithNativeLib('save creates a new record', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);

        final result = await backend.save(user);

        expect(result.id, equals('1'));
        expect(result.name, equals('Alice'));
        expect(result.age, equals(30));
      });

      testWithNativeLib('save updates existing record (upsert)', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);
        await backend.save(user);

        final updated = TestUser(id: '1', name: 'Alice Updated', age: 31);
        final result = await backend.save(updated);

        expect(result.id, equals('1'));
        expect(result.name, equals('Alice Updated'));
        expect(result.age, equals(31));
      });

      testWithNativeLib('get retrieves existing record', () async {
        final user = TestUser(id: '1', name: 'Alice', age: 30);
        await backend.save(user);

        final result = await backend.get('1');

        expect(result, isNotNull);
        expect(result!.id, equals('1'));
        expect(result.name, equals('Alice'));
      });

      testWithNativeLib('get returns null for non-existent id', () async {
        final result = await backend.get('non-existent');

        expect(result, isNull);
      });

      testWithNativeLib('getAll returns all records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));

        final results = await backend.getAll();

        expect(results, hasLength(2));
        expect(results.map((u) => u.name), containsAll(['Alice', 'Bob']));
      });

      testWithNativeLib('getAll with query filters results', () async {
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

      testWithNativeLib('delete removes existing record', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final deleted = await backend.delete('1');

        expect(deleted, isTrue);

        final result = await backend.get('1');
        expect(result, isNull);
      });

      testWithNativeLib(
        'delete returns false for non-existent record',
        () async {
        final deleted = await backend.delete('non-existent');

        expect(deleted, isFalse);
      });

      testWithNativeLib('deleteAll removes multiple records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));

        final count = await backend.deleteAll(['1', '2']);

        expect(count, equals(2));

        final remaining = await backend.getAll();
        expect(remaining, hasLength(1));
        expect(remaining.first.name, equals('Charlie'));
      });

      testWithNativeLib('deleteWhere removes records matching query', () async {
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

      testWithNativeLib(
        'saveAll inserts multiple records in transaction',
        () async {
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
      testWithNativeLib('watch returns stream for record', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));

        final stream = backend.watch('1');
        final firstValue = await stream.first;

        expect(firstValue, isNotNull);
        expect(firstValue!.name, equals('Alice'));
      });

      testWithNativeLib('watch emits updates when record changes', () async {
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

      testWithNativeLib('watch emits null when record is deleted', () async {
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

      testWithNativeLib('watchAll returns stream for all records', () async {
        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));

        final stream = backend.watchAll();
        final firstValue = await stream.first;

        expect(firstValue, hasLength(2));
      });

      testWithNativeLib('watchAll with query filters stream', () async {
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
      testWithNativeLib(
        'writeTransaction commits multiple operations atomically',
        () async {
        final users = [
          TestUser(id: '1', name: 'Alice', age: 30),
          TestUser(id: '2', name: 'Bob', age: 25),
        ];

        await backend.saveAll(users);

        final all = await backend.getAll();
        expect(all, hasLength(2));
      });

      testWithNativeLib('saveAll with empty list returns empty', () async {
        final results = await backend.saveAll([]);

        expect(results, isEmpty);
      });
    });

    group('DefaultPowerSyncDatabaseWrapper sync status', () {
      testWithNativeLib('statusStream emits sync status', () async {
        // The wrapper should provide access to status stream
        expect(backend.syncStatusStream, isA<Stream<nexus.SyncStatus>>());
      });

      testWithNativeLib('currentStatus is accessible', () async {
        expect(backend.syncStatus, isA<nexus.SyncStatus>());
      });
    });

    group('Pagination with real database', () {
      setUp(() async {
        // Skip setup if native library is not available
        if (!_nativeLibraryAvailable) return;

        // Add test data for pagination
        for (var i = 1; i <= 10; i++) {
          await backend.save(TestUser(
            id: '$i',
            name: 'User $i',
            age: 20 + i,
          ),);
        }
      });

      testWithNativeLib('getAllPaged returns first page', () async {
        final query = const nexus.Query<TestUser>().first(3);

        final result = await backend.getAllPaged(query: query);

        expect(result.items, hasLength(3));
        expect(result.pageInfo.hasNextPage, isTrue);
        expect(result.pageInfo.hasPreviousPage, isFalse);
        expect(result.pageInfo.totalCount, equals(10));
      });

      testWithNativeLib('getAllPaged with cursor returns next page', () async {
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

      testWithNativeLib('watchAllPaged returns paginated stream', () async {
        final query = const nexus.Query<TestUser>().first(3);

        final stream = backend.watchAllPaged(query: query);
        final firstValue = await stream.first;

        expect(firstValue.items, hasLength(3));
        expect(firstValue.pageInfo.hasNextPage, isTrue);
      });
    });

    group('Query operations with real database', () {
      setUp(() async {
        // Skip setup if native library is not available
        if (!_nativeLibraryAvailable) return;

        await backend.save(TestUser(id: '1', name: 'Alice', age: 30));
        await backend.save(TestUser(id: '2', name: 'Bob', age: 25));
        await backend.save(TestUser(id: '3', name: 'Charlie', age: 35));
        await backend.save(TestUser(id: '4', name: 'Alice Jr', age: 22));
      });

      testWithNativeLib('query with orderBy sorts results', () async {
        final query =
            const nexus.Query<TestUser>().orderByField('age', descending: true);

        final results = await backend.getAll(query: query);

        expect(results.first.name, equals('Charlie'));
        expect(results.last.name, equals('Alice Jr'));
      });

      testWithNativeLib('query with limit returns limited results', () async {
        final query = const nexus.Query<TestUser>().limitTo(2);

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
      });

      testWithNativeLib('query with offset skips results', () async {
        final query = const nexus.Query<TestUser>().offsetBy(2);

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
      });

      testWithNativeLib(
        'query with whereIn filters to specific values',
        () async {
        final query = const nexus.Query<TestUser>().where(
          'id',
          whereIn: ['1', '3'],
        );

        final results = await backend.getAll(query: query);

        expect(results, hasLength(2));
        expect(results.map((u) => u.name), containsAll(['Alice', 'Charlie']));
      });

      testWithNativeLib('query with isNull filters null values', () async {
        await backend.save(TestUser(id: '5', name: 'NoAge'));

        final query = const nexus.Query<TestUser>().where('age', isNull: true);

        final results = await backend.getAll(query: query);

        expect(results.any((u) => u.name == 'NoAge'), isTrue);
      });
    });
  });
}
