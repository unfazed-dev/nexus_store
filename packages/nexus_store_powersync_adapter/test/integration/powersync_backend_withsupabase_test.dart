/// Integration tests for PowerSyncBackend.withSupabase factory.
///
/// These tests verify the full lifecycle of a backend that owns its database:
/// - Factory creation with real Supabase/PowerSync
/// - Database creation and connection during initialize
/// - CRUD operations with owned database
/// - Clean disposal of owned resources
///
/// ## Requirements
/// 1. **PowerSync native library** (libpowersync.dylib / .so / .dll)
/// 2. **SQLite with extension loading support** (Homebrew SQLite on macOS)
/// 3. **Active Supabase project** with `test_items` table
/// 4. **Valid credentials** in test_config.dart
///
/// ## Running Tests
/// ```bash
/// dart test test/integration/powersync_backend_withsupabase_test.dart
/// # or
/// dart test --tags=integration,withsupabase
/// ```
@Tags(['integration', 'withsupabase'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:nexus_store/nexus_store.dart' as nexus;
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../test_config.dart';
import '../test_utils/powersync_test_utils.dart';
import 'test_item_model.dart';

/// Tracks whether PowerSync native library is available.
bool _nativeLibraryAvailable = false;
String? _skipReason;

/// Runs a test only if PowerSync native library is available.
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

/// Creates a unique database path for testing.
String _createTestDbPath(String testName) {
  final tempDir = Directory.systemTemp;
  return '${tempDir.path}/${testName}_${DateTime.now().microsecondsSinceEpoch}.db';
}

/// Cleans up a database file.
void _cleanupDbFile(String dbPath) {
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
  }
}

void main() {
  group('PowerSyncBackend.withSupabase Integration Tests', () {
    late SupabaseClient supabase;
    final createdIds = <String>[];

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

      _nativeLibraryAvailable = true;

      // Create Supabase client for cleanup operations
      supabase = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
    });

    tearDown(() async {
      // Clean up any test records created during tests
      for (final id in createdIds) {
        try {
          await supabase.rest.from('test_items').delete().eq('id', id);
        } on PostgrestException catch (_) {
          // Ignore cleanup errors
        }
      }
      createdIds.clear();
    });

    tearDownAll(() {
      supabase.dispose();
    });

    group('Factory Creation', () {
      testWithNativeLib('creates backend with all required parameters',
          () async {
        final dbPath = _createTestDbPath('factory_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
            PSColumn.text('created_at'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        expect(backend, isNotNull);
        expect(backend.name, equals('powersync'));
        expect(backend.supportsOffline, isTrue);
        expect(backend.supportsRealtime, isTrue);

        // Clean up
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('creates backend with auto-generated dbPath', () async {
        // This test covers _generateDbPath() by NOT passing dbPath
        // We still use openFactory for macOS compatibility, but the path
        // will be auto-generated internally
        final generatedPath = Directory.systemTemp.path;
        final testPath =
            '$generatedPath/autogen_test_${DateTime.now().microsecondsSinceEpoch}.db';

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          // Note: NOT passing dbPath - triggers _generateDbPath()
          // Still using openFactory for macOS Homebrew SQLite compatibility
          openFactory: TestPowerSyncOpenFactory(path: testPath),
        );

        expect(backend, isNotNull);
        expect(backend.name, equals('powersync'));

        // Must call initialize() to trigger _createAndConnectDatabase()
        // which calls _generateDbPath() when dbPath is null
        await backend.initialize();

        // Verify it initialized successfully
        expect(backend.syncStatus, isA<nexus.SyncStatus>());

        // Clean up
        await backend.dispose();
        _cleanupDbFile(testPath);
      });

      testWithNativeLib('creates backend without openFactory (production path)',
          () async {
        // This test covers the production code path (line 273) where
        // PowerSyncDatabase is created without a custom factory.
        //
        // PLATFORM LIMITATION:
        // - On macOS: System SQLite has extension loading disabled, and global
        //   overrides don't transfer to PowerSync's spawned isolate.
        // - On Linux: System SQLite typically supports extension loading.
        // - On Flutter mobile: Bundled SQLite supports extension loading.
        //
        // This test is skipped on macOS and should run on Linux CI or Flutter
        // integration tests where the production path works.
        if (Platform.isMacOS) {
          markTestSkipped(
            'macOS system SQLite does not support extension loading. '
            'This test runs on Linux CI or Flutter integration tests.',
          );
          return;
        }

        final dbPath = _createTestDbPath('production_path_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          // Note: NOT passing openFactory - tests production code path!
        );

        expect(backend, isNotNull);

        // Initialize triggers _createAndConnectDatabase() which uses
        // the else branch (line 273) when openFactory is null
        await backend.initialize();

        // Verify it initialized successfully
        expect(backend.syncStatus, isA<nexus.SyncStatus>());

        // Clean up
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('creates backend with custom dbPath', () async {
        final customPath = _createTestDbPath('custom_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: customPath,
          openFactory: TestPowerSyncOpenFactory(path: customPath),
        );

        expect(backend, isNotNull);

        // Clean up
        await backend.dispose();
        _cleanupDbFile(customPath);
      });

      testWithNativeLib('creates backend with field mapping', () async {
        final dbPath = _createTestDbPath('fieldmapping_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          fieldMapping: {'itemName': 'name', 'itemValue': 'value'},
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        expect(backend, isNotNull);

        // Clean up
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });
    });

    group('Default Constructor', () {
      testWithNativeLib('creates backend with PowerSyncDatabase directly',
          () async {
        // This test covers the default constructor (lines 47, 56-57)
        // that takes a PowerSyncDatabase directly and wraps it.
        final dbPath = _createTestDbPath('default_constructor_test');

        // Create a PowerSyncDatabase using the test factory
        const schema = ps.Schema([
          ps.Table('test_items', [
            ps.Column.text('name'),
            ps.Column.integer('value'),
          ]),
        ]);

        final database = ps.PowerSyncDatabase.withFactory(
          TestPowerSyncOpenFactory(path: dbPath),
          schema: schema,
        );
        await database.initialize();

        // Use the default constructor (covers lines 47, 56-57)
        final backend = PowerSyncBackend<TestItem, String>(
          db: database,
          tableName: 'test_items',
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
        );

        expect(backend, isNotNull);
        expect(backend.name, equals('powersync'));

        // Initialize the backend (sets up sync listener, marks as ready)
        // Note: Since _ownsDatabase=false, this skips database creation
        await backend.initialize();

        // Verify we can perform operations
        final id = generateTestId('default_ctor');
        final item = TestItem(id: id, name: 'Default Ctor Test', value: 42);
        final saved = await backend.save(item);
        expect(saved.id, equals(id));

        // Clean up
        await backend.delete(id);
        await database.close();
        _cleanupDbFile(dbPath);
      });
    });

    group('Lifecycle', () {
      testWithNativeLib('initialize creates database and connects', () async {
        final dbPath = _createTestDbPath('init_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        // Before initialize - operations should throw
        expect(
          () => backend.get('test'),
          throwsA(isA<nexus.StateError>()),
        );

        // Initialize should succeed
        await backend.initialize();

        // After initialize - sync status should be available
        expect(backend.syncStatus, isA<nexus.SyncStatus>());

        // Clean up
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('initialize is idempotent', () async {
        final dbPath = _createTestDbPath('idempotent_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [PSColumn.text('name')],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await backend.initialize();
        await backend.initialize();
        await backend.initialize();

        // Should not throw
        expect(backend.syncStatus, isA<nexus.SyncStatus>());

        await backend.dispose();
        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('dispose disconnects and closes database', () async {
        final dbPath = _createTestDbPath('dispose_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [PSColumn.text('name')],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await backend.initialize();

        // Dispose should complete without error
        await backend.dispose();

        // After dispose, backend should no longer be initialized
        // Note: re-calling dispose should be safe
        await backend.dispose();

        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('close without dispose keeps database intact',
          () async {
        final dbPath = _createTestDbPath('close_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [PSColumn.text('name')],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await backend.initialize();

        // Close cleans up streams but doesn't disconnect database
        await backend.close();

        // Clean up - dispose actually closes the database
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });
    });

    group('CRUD with Owned Database', () {
      late PowerSyncBackend<TestItem, String> backend;
      late String dbPath;

      setUp(() async {
        if (!_nativeLibraryAvailable) return;

        dbPath = _createTestDbPath('crud_test');
        backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('value'),
          ],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await backend.initialize();
      });

      tearDown(() async {
        if (!_nativeLibraryAvailable) return;
        await backend.dispose();
        _cleanupDbFile(dbPath);
      });

      testWithNativeLib('save inserts to local database', () async {
        final id = generateTestId('withsupabase_save');
        createdIds.add(id);

        final item = TestItem(id: id, name: 'Test Save', value: 42);
        final saved = await backend.save(item);

        expect(saved.id, equals(id));
        expect(saved.name, equals('Test Save'));
        expect(saved.value, equals(42));
      });

      testWithNativeLib('get retrieves from local database', () async {
        final id = generateTestId('withsupabase_get');
        createdIds.add(id);

        await backend.save(TestItem(id: id, name: 'Test Get', value: 100));

        final retrieved = await backend.get(id);

        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Test Get'));
        expect(retrieved.value, equals(100));
      });

      testWithNativeLib('get returns null for non-existent ID', () async {
        final result = await backend.get('non_existent_id');
        expect(result, isNull);
      });

      testWithNativeLib('getAll returns all records', () async {
        final id1 = generateTestId('withsupabase_all1');
        final id2 = generateTestId('withsupabase_all2');
        createdIds.addAll([id1, id2]);

        await backend.save(TestItem(id: id1, name: 'Item 1', value: 1));
        await backend.save(TestItem(id: id2, name: 'Item 2', value: 2));

        final all = await backend.getAll();

        expect(all.length, greaterThanOrEqualTo(2));
        expect(all.any((item) => item.id == id1), isTrue);
        expect(all.any((item) => item.id == id2), isTrue);
      });

      testWithNativeLib('getAll with query filters results', () async {
        final id1 = generateTestId('withsupabase_q1');
        final id2 = generateTestId('withsupabase_q2');
        createdIds.addAll([id1, id2]);

        await backend.save(TestItem(id: id1, name: 'QueryItem', value: 50));
        await backend.save(TestItem(id: id2, name: 'QueryItem', value: 150));

        final query = const nexus.Query<TestItem>().where(
          'value',
          isGreaterThan: 100,
        );

        final results = await backend.getAll(query: query);

        expect(results.any((item) => item.id == id2), isTrue);
        expect(results.any((item) => item.id == id1), isFalse);
      });

      testWithNativeLib('delete removes from local database', () async {
        final id = generateTestId('withsupabase_delete');
        // Don't add to createdIds - we're deleting it

        await backend.save(TestItem(id: id, name: 'To Delete', value: 999));

        final deleted = await backend.delete(id);
        expect(deleted, isTrue);

        final result = await backend.get(id);
        expect(result, isNull);
      });

      testWithNativeLib('saveAll inserts multiple records', () async {
        final id1 = generateTestId('withsupabase_batch1');
        final id2 = generateTestId('withsupabase_batch2');
        final id3 = generateTestId('withsupabase_batch3');
        createdIds.addAll([id1, id2, id3]);

        final items = [
          TestItem(id: id1, name: 'Batch 1', value: 10),
          TestItem(id: id2, name: 'Batch 2', value: 20),
          TestItem(id: id3, name: 'Batch 3', value: 30),
        ];

        final saved = await backend.saveAll(items);

        expect(saved, hasLength(3));
        expect(saved.map((i) => i.id), containsAll([id1, id2, id3]));
      });

      testWithNativeLib('deleteAll removes multiple records', () async {
        final id1 = generateTestId('withsupabase_delall1');
        final id2 = generateTestId('withsupabase_delall2');
        // Don't add to createdIds - we're deleting them

        await backend.save(TestItem(id: id1, name: 'DelAll 1'));
        await backend.save(TestItem(id: id2, name: 'DelAll 2'));

        final count = await backend.deleteAll([id1, id2]);

        expect(count, equals(2));
        expect(await backend.get(id1), isNull);
        expect(await backend.get(id2), isNull);
      });
    });

    group('Sync Status', () {
      testWithNativeLib('sync status stream is available', () async {
        final dbPath = _createTestDbPath('syncstatus_test');

        final backend = PowerSyncBackend<TestItem, String>.withSupabase(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
          tableName: 'test_items',
          columns: [PSColumn.text('name')],
          fromJson: TestItem.fromJson,
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
          dbPath: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await backend.initialize();

        expect(backend.syncStatusStream, isA<Stream<nexus.SyncStatus>>());
        expect(backend.syncStatus, isA<nexus.SyncStatus>());

        await backend.dispose();
        _cleanupDbFile(dbPath);
      });
    });
  });
}
