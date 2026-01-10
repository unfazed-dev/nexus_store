import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:test/test.dart';

class TestUser {
  TestUser({required this.id, required this.name});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

void main() {
  group('PSTableConfig', () {
    group('constructor', () {
      test('stores table name', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.tableName, equals('users'));
      });

      test('stores columns', () {
        final columns = [
          PSColumn.text('name'),
          PSColumn.text('email'),
        ];
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.columns, equals(columns));
      });

      test('stores fromJson function', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final user = config.fromJson({'id': '1', 'name': 'Test'});
        expect(user.id, equals('1'));
        expect(user.name, equals('Test'));
      });

      test('stores toJson function', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final json = config.toJson(TestUser(id: '1', name: 'Test'));
        expect(json['id'], equals('1'));
        expect(json['name'], equals('Test'));
      });

      test('stores getId function', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final id = config.getId(TestUser(id: '123', name: 'Test'));
        expect(id, equals('123'));
      });

      test('uses default primary key column', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.primaryKeyColumn, equals('id'));
      });

      test('accepts custom primary key column', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          primaryKeyColumn: 'user_id',
        );

        expect(config.primaryKeyColumn, equals('user_id'));
      });

      test('accepts optional field mapping', () {
        final fieldMapping = {'firstName': 'first_name'};
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          fieldMapping: fieldMapping,
        );

        expect(config.fieldMapping, equals(fieldMapping));
      });

      test('field mapping defaults to null', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.fieldMapping, isNull);
      });

      test('localOnly defaults to false', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.localOnly, isFalse);
      });

      test('accepts localOnly parameter', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'local_settings',
          columns: [PSColumn.text('value')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          localOnly: true,
        );

        expect(config.localOnly, isTrue);
      });
    });

    group('toTableDefinition', () {
      test('creates PSTableDefinition with correct table name', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final tableDef = config.toTableDefinition();

        expect(tableDef.tableName, equals('users'));
      });

      test('creates PSTableDefinition with correct columns', () {
        final columns = [
          PSColumn.text('name'),
          PSColumn.integer('age'),
        ];
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final tableDef = config.toTableDefinition();

        expect(tableDef.columns.length, equals(2));
      });

      test('passes through localOnly false by default', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final tableDef = config.toTableDefinition();

        expect(tableDef.localOnly, isFalse);
      });

      test('passes through localOnly true when set', () {
        final config = PSTableConfig<TestUser, String>(
          tableName: 'local_settings',
          columns: [PSColumn.text('value')],
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          localOnly: true,
        );

        final tableDef = config.toTableDefinition();

        expect(tableDef.localOnly, isTrue);
      });
    });
  });

  group('PSTableDefinition', () {
    group('toTable', () {
      test('creates regular table when localOnly is false', () {
        final tableDef = PSTableDefinition(
          tableName: 'users',
          columns: [PSColumn.text('name')],
        );

        final table = tableDef.toTable();

        expect(table.name, equals('users'));
        expect(table.localOnly, isFalse);
      });

      test('creates local-only table when localOnly is true', () {
        final tableDef = PSTableDefinition(
          tableName: 'local_settings',
          columns: [PSColumn.text('value')],
          localOnly: true,
        );

        final table = tableDef.toTable();

        expect(table.name, equals('local_settings'));
        expect(table.localOnly, isTrue);
      });
    });
  });
}
