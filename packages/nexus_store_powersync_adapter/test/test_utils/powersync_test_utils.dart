/// Test utilities for running PowerSync integration tests on desktop platforms.
///
/// This provides the necessary configuration to load the PowerSync SQLite
/// extension on macOS/Linux/Windows where the system SQLite may not support
/// extension loading.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:nexus_store_powersync_adapter/src/powersync_database_adapter.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3.dart' as ps_sqlite;
import 'package:powersync/sqlite3_common.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

/// Custom open factory for integration tests that properly configures SQLite
/// to use Homebrew's version (which supports extension loading) and loads
/// the PowerSync extension from the correct path.
///
/// This is necessary because:
/// 1. macOS system SQLite doesn't support extension loading
/// 2. PowerSync uses sqlite_async which runs in a separate isolate
/// 3. Each isolate needs its own SQLite configuration
class TestPowerSyncOpenFactory extends PowerSyncOpenFactory {
  /// Creates a test factory with the given database path.
  TestPowerSyncOpenFactory({required super.path});

  /// Applies SQLite loading override to use Homebrew's SQLite on macOS.
  void _applySqliteOverride() {
    if (Platform.isMacOS) {
      sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.macOS, () {
        const homebrewArm = '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib';
        const homebrewIntel = '/usr/local/opt/sqlite/lib/libsqlite3.dylib';

        if (File(homebrewArm).existsSync()) {
          return DynamicLibrary.open(homebrewArm);
        }
        if (File(homebrewIntel).existsSync()) {
          return DynamicLibrary.open(homebrewIntel);
        }
        return DynamicLibrary.open('libsqlite3.dylib');
      });
    } else if (Platform.isLinux) {
      sqlite_open.open.overrideFor(
        sqlite_open.OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  }

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    _applySqliteOverride();
    return super.open(options);
  }

  @override
  void enableExtension() {
    final libPath = _getPowerSyncLibraryPath();
    final lib = DynamicLibrary.open(libPath);
    ps_sqlite.sqlite3.ensureExtensionLoaded(
      ps_sqlite.SqliteExtension.inLibrary(lib, 'sqlite3_powersync_init'),
    );
  }

  String _getPowerSyncLibraryPath() {
    final packageRoot = Directory.current.path;

    return switch (Abi.current()) {
      Abi.macosArm64 || Abi.macosX64 => '$packageRoot/libpowersync.dylib',
      Abi.linuxX64 || Abi.linuxArm64 => '$packageRoot/libpowersync.so',
      Abi.windowsX64 => '$packageRoot/powersync.dll',
      _ => throw UnsupportedError('Unsupported platform: ${Abi.current()}'),
    };
  }
}

/// Creates a PowerSyncDatabase configured for integration testing.
///
/// This uses [TestPowerSyncOpenFactory] which properly configures SQLite
/// for extension loading on desktop platforms.
///
/// Example:
/// ```dart
/// final db = createTestPowerSyncDatabase(
///   schema: mySchema,
///   path: '/tmp/test.db',
/// );
/// await db.initialize();
/// ```
PowerSyncDatabase createTestPowerSyncDatabase({
  required Schema schema,
  required String path,
}) =>
    PowerSyncDatabase.withFactory(
      TestPowerSyncOpenFactory(path: path),
      schema: schema,
    );

/// Checks if the PowerSync native library is available for testing.
///
/// Returns a tuple of (available, error message if not available).
(bool available, String? error) checkPowerSyncLibraryAvailable() {
  final packageRoot = Directory.current.path;

  final String libName;
  switch (Abi.current()) {
    case Abi.macosArm64:
    case Abi.macosX64:
      libName = 'libpowersync.dylib';
    case Abi.linuxX64:
    case Abi.linuxArm64:
      libName = 'libpowersync.so';
    case Abi.windowsX64:
      libName = 'powersync.dll';
    default:
      return (
        false,
        'Unsupported platform: ${Abi.current()}. '
            'PowerSync tests only supported on macOS, Linux, Windows.',
      );
  }

  final libPath = '$packageRoot/$libName';

  if (!File(libPath).existsSync()) {
    return (
      false,
      'PowerSync library not found at: $libPath\n'
          'Run ./scripts/download_powersync_binary.sh to download it.',
    );
  }

  // Verify the library can be loaded
  try {
    DynamicLibrary.open(libPath).lookup('sqlite3_powersync_init');
    return (true, null);
    // ignore: avoid_catching_errors
  } on ArgumentError catch (e) {
    return (false, 'PowerSync library missing required symbol: $e');
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    return (false, 'Failed to load PowerSync library: $e');
  }
}

/// Checks if Homebrew SQLite is available (macOS only).
bool isHomebrewSqliteAvailable() {
  if (!Platform.isMacOS) return true; // Not required on other platforms

  const homebrewArm = '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib';
  const homebrewIntel = '/usr/local/opt/sqlite/lib/libsqlite3.dylib';

  return File(homebrewArm).existsSync() || File(homebrewIntel).existsSync();
}

/// Applies global SQLite overrides to use Homebrew SQLite on macOS.
///
/// This must be called before creating any PowerSyncDatabase without
/// an openFactory. Once applied, the override affects all subsequent
/// SQLite operations in the process.
///
/// This is useful for testing the production code path that creates
/// PowerSyncDatabase without a factory.
void applyGlobalSqliteOverride() {
  if (Platform.isMacOS) {
    sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.macOS, () {
      const homebrewArm = '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib';
      const homebrewIntel = '/usr/local/opt/sqlite/lib/libsqlite3.dylib';

      if (File(homebrewArm).existsSync()) {
        return DynamicLibrary.open(homebrewArm);
      }
      if (File(homebrewIntel).existsSync()) {
        return DynamicLibrary.open(homebrewIntel);
      }
      return DynamicLibrary.open('libsqlite3.dylib');
    });
  } else if (Platform.isLinux) {
    sqlite_open.open.overrideFor(
      sqlite_open.OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }
}

/// Loads the PowerSync extension globally.
///
/// This must be called after [applyGlobalSqliteOverride] and before
/// creating any PowerSyncDatabase without an openFactory.
void loadPowerSyncExtensionGlobally() {
  final packageRoot = Directory.current.path;

  final libPath = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 => '$packageRoot/libpowersync.dylib',
    Abi.linuxX64 || Abi.linuxArm64 => '$packageRoot/libpowersync.so',
    Abi.windowsX64 => '$packageRoot/powersync.dll',
    _ => throw UnsupportedError('Unsupported platform: ${Abi.current()}'),
  };

  final lib = DynamicLibrary.open(libPath);
  ps_sqlite.sqlite3.ensureExtensionLoaded(
    ps_sqlite.SqliteExtension.inLibrary(lib, 'sqlite3_powersync_init'),
  );
}

/// Creates a [PowerSyncDatabaseAdapterFactory] for integration tests.
///
/// This factory creates [DefaultPowerSyncDatabaseAdapter] instances configured
/// with [TestPowerSyncOpenFactory], which handles SQLite overrides and
/// PowerSync extension loading required for desktop platforms.
///
/// Example:
/// ```dart
/// final manager = PowerSyncManager.withSupabase(
///   supabase: supabase,
///   powerSyncUrl: url,
///   tables: tables,
///   databaseAdapterFactory: createTestDatabaseAdapterFactory(),
/// );
/// ```
PowerSyncDatabaseAdapterFactory createTestDatabaseAdapterFactory() =>
    (schema, path) => DefaultPowerSyncDatabaseAdapter(
          schema: schema,
          path: path,
          openFactory: TestPowerSyncOpenFactory(path: path),
        );
