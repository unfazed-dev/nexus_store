/// Integration tests for DefaultPowerSyncDatabaseAdapter.
///
/// These tests verify the full lifecycle of the adapter with real PowerSync:
/// - Database creation and initialization
/// - Connection to PowerSync service
/// - Wrapper access after initialization
/// - Clean disposal of resources
///
/// ## Requirements
/// 1. **PowerSync native library** (libpowersync.dylib / .so / .dll)
/// 2. **SQLite with extension loading support** (Homebrew SQLite on macOS)
/// 3. **Active Supabase project** with valid credentials
///
/// ## Running Tests
/// ```bash
/// dart test test/integration/powersync_database_adapter_integration_test.dart
/// # or
/// dart test --tags=integration
/// ```
@Tags(['integration'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../test_config.dart';
import '../test_utils/powersync_test_utils.dart';

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

void main() {
  group('DefaultPowerSyncDatabaseAdapter Integration Tests', () {
    late ps.Schema testSchema;
    late SupabaseClient supabase;

    setUpAll(() async {
      // Check if PowerSync library and Homebrew SQLite are available
      if (!isHomebrewSqliteAvailable()) {
        _skipReason =
            'Homebrew SQLite not installed. Run: brew install sqlite';
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

      // Create Supabase client for connector
      supabase = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
    });

    setUp(() {
      testSchema = const ps.Schema([
        ps.Table('test_items', [
          ps.Column.text('name'),
          ps.Column.integer('value'),
        ]),
      ]);
    });

    tearDownAll(() {
      if (_nativeLibraryAvailable) {
        supabase.dispose();
      }
    });

    group('Lifecycle', () {
      testWithNativeLib('initialize creates wrapper and sets initialized',
          () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_init_${DateTime.now().microsecondsSinceEpoch}.db';

        // Use TestPowerSyncOpenFactory for macOS compatibility
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        expect(adapter.isInitialized, isFalse);

        // Covers lines 111-113 (with factory path)
        await adapter.initialize();

        expect(adapter.isInitialized, isTrue);

        // Clean up
        await adapter.close();

        // Clean up database file
        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib('wrapper getter returns wrapper after initialize',
          () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_wrapper_${DateTime.now().microsecondsSinceEpoch}.db';

        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await adapter.initialize();

        // Covers line 137: return _wrapper!;
        final wrapper = adapter.wrapper;
        expect(wrapper, isA<PowerSyncDatabaseWrapper>());

        // Clean up
        await adapter.close();

        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib('connect calls database.connect', () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_connect_${DateTime.now().microsecondsSinceEpoch}.db';

        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await adapter.initialize();

        final connector = SupabasePowerSyncConnector.withClient(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
        );

        // Covers line 119: await _database!.connect(connector: connector);
        await adapter.connect(connector);

        // If we get here without error, connect succeeded
        expect(adapter.isInitialized, isTrue);

        // Clean up
        await adapter.disconnect();
        await adapter.close();

        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib('close resets state after initialize', () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_close_${DateTime.now().microsecondsSinceEpoch}.db';

        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await adapter.initialize();
        expect(adapter.isInitialized, isTrue);

        // Covers lines 128-130: _database = null;
        //                       _wrapper = null;
        //                       _initialized = false;
        await adapter.close();

        expect(adapter.isInitialized, isFalse);

        // Accessing wrapper after close should throw
        expect(
          () => adapter.wrapper,
          throwsA(isA<StateError>()),
        );

        // Clean up database file
        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib('initialize is idempotent', () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_idempotent_${DateTime.now().microsecondsSinceEpoch}.db';

        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        await adapter.initialize();
        await adapter.initialize(); // Second call should be no-op
        await adapter.initialize(); // Third call should be no-op

        expect(adapter.isInitialized, isTrue);

        // Clean up
        await adapter.close();

        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib('full lifecycle: initialize -> connect -> close',
          () async {
        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_full_${DateTime.now().microsecondsSinceEpoch}.db';

        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          openFactory: TestPowerSyncOpenFactory(path: dbPath),
        );

        // Initialize
        await adapter.initialize();
        expect(adapter.isInitialized, isTrue);

        // Get wrapper
        expect(adapter.wrapper, isA<PowerSyncDatabaseWrapper>());

        // Connect
        final connector = SupabasePowerSyncConnector.withClient(
          supabase: supabase,
          powerSyncUrl: TestConfig.powersyncUrl,
        );
        await adapter.connect(connector);

        // Disconnect
        await adapter.disconnect();

        // Close
        await adapter.close();
        expect(adapter.isInitialized, isFalse);

        // Clean up database file
        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });

      testWithNativeLib(
          'initialize without openFactory (production path)', () async {
        // This test covers line 109: the production code path where
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

        final tempDir = Directory.systemTemp;
        final dbPath =
            '${tempDir.path}/adapter_prod_${DateTime.now().microsecondsSinceEpoch}.db';

        // Create adapter WITHOUT openFactory - tests production code path
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: dbPath,
          // Note: NOT passing openFactory - tests line 109!
        );

        // Initialize triggers the else branch (line 109)
        await adapter.initialize();

        expect(adapter.isInitialized, isTrue);
        expect(adapter.wrapper, isA<PowerSyncDatabaseWrapper>());

        // Clean up
        await adapter.close();

        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      });
    });
  });
}
