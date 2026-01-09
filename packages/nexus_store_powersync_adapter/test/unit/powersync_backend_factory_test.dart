import 'package:nexus_store_powersync_adapter/src/column_definition.dart';
import 'package:nexus_store_powersync_adapter/src/powersync_backend_factory.dart';
import 'package:test/test.dart';

void main() {
  group('PowerSyncBackendConfig', () {
    test('stores all configuration values', () {
      final columns = [
        PSColumn.text('name'),
        PSColumn.integer('age'),
      ];

      final config = PowerSyncBackendConfig<TestUser, String>(
        tableName: 'users',
        columns: columns,
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        powerSyncUrl: 'https://test.powersync.co',
      );

      expect(config.tableName, equals('users'));
      expect(config.columns, equals(columns));
      expect(config.powerSyncUrl, equals('https://test.powersync.co'));
    });

    test('generates PSTableDefinition from config', () {
      final config = PowerSyncBackendConfig<TestUser, String>(
        tableName: 'users',
        columns: [
          PSColumn.text('name'),
          PSColumn.integer('age'),
        ],
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        powerSyncUrl: 'https://test.powersync.co',
      );

      final tableDef = config.toTableDefinition();

      expect(tableDef.tableName, equals('users'));
      expect(tableDef.columns, hasLength(2));
    });

    test('supports optional dbPath', () {
      final config = PowerSyncBackendConfig<TestUser, String>(
        tableName: 'users',
        columns: [PSColumn.text('name')],
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        powerSyncUrl: 'https://test.powersync.co',
        dbPath: '/custom/path/db.sqlite',
      );

      expect(config.dbPath, equals('/custom/path/db.sqlite'));
    });

    test('dbPath is null by default', () {
      final config = PowerSyncBackendConfig<TestUser, String>(
        tableName: 'users',
        columns: [PSColumn.text('name')],
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        powerSyncUrl: 'https://test.powersync.co',
      );

      expect(config.dbPath, isNull);
    });

    test('generates schema from table definition', () {
      final config = PowerSyncBackendConfig<TestUser, String>(
        tableName: 'products',
        columns: [
          PSColumn.text('name'),
          PSColumn.text('description'),
          PSColumn.real('price'),
          PSColumn.integer('quantity'),
        ],
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        powerSyncUrl: 'https://test.powersync.co',
      );

      final schema = config.toSchema();

      expect(schema.tables, hasLength(1));
      expect(schema.tables.first.name, equals('products'));
      expect(schema.tables.first.columns, hasLength(4));
    });
  });

  // Note: Integration tests for actual database creation and lifecycle
  // require native FFI setup and should be run separately.
  // See test/integration/ for those tests.
}

/// Test model for testing the backend factory.
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
}
