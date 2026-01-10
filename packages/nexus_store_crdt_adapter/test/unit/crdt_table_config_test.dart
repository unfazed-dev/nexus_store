import 'package:nexus_store_crdt_adapter/src/crdt_column.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_merge_strategy.dart';
import 'package:nexus_store_crdt_adapter/src/crdt_table_config.dart';
import 'package:test/test.dart';

class _TestUser {
  _TestUser({required this.id, required this.name, this.email});

  factory _TestUser.fromJson(Map<String, dynamic> json) => _TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );

  final String id;
  final String name;
  final String? email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}

void main() {
  group('CrdtTableConfig', () {
    late CrdtTableConfig<_TestUser, String> config;

    setUp(() {
      config = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
        ],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );
    });

    test('stores tableName', () {
      expect(config.tableName, 'users');
    });

    test('stores columns', () {
      expect(config.columns, hasLength(3));
      expect(config.columns[0].name, 'id');
      expect(config.columns[1].name, 'name');
      expect(config.columns[2].name, 'email');
    });

    test('uses default primaryKeyColumn', () {
      expect(config.primaryKeyColumn, 'id');
    });

    test('allows custom primaryKeyColumn', () {
      final customConfig = CrdtTableConfig<_TestUser, String>(
        tableName: 'users',
        columns: [CrdtColumn.text('user_id', nullable: false)],
        fromJson: _TestUser.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        primaryKeyColumn: 'user_id',
      );

      expect(customConfig.primaryKeyColumn, 'user_id');
    });

    test('stores fieldMapping', () {
      final configWithMapping = config.copyWith(
        fieldMapping: {'firstName': 'first_name'},
      );

      expect(configWithMapping.fieldMapping, {'firstName': 'first_name'});
    });

    test('stores indexes', () {
      final configWithIndexes = config.copyWith(
        indexes: [
          const CrdtIndex(name: 'idx_email', columns: ['email']),
        ],
      );

      expect(configWithIndexes.indexes, hasLength(1));
      expect(configWithIndexes.indexes![0].name, 'idx_email');
    });

    group('serialization', () {
      test('fromJson deserializes correctly', () {
        final user = config.fromJson({
          'id': '123',
          'name': 'Alice',
          'email': 'alice@example.com',
        });

        expect(user.id, '123');
        expect(user.name, 'Alice');
        expect(user.email, 'alice@example.com');
      });

      test('toJson serializes correctly', () {
        final user = _TestUser(id: '456', name: 'Bob', email: 'bob@test.com');
        final json = config.toJson(user);

        expect(json['id'], '456');
        expect(json['name'], 'Bob');
        expect(json['email'], 'bob@test.com');
      });

      test('getId extracts id correctly', () {
        final user = _TestUser(id: '789', name: 'Carol');
        final id = config.getId(user);

        expect(id, '789');
      });
    });

    group('dynamicGetId', () {
      test('works with dynamic types', () {
        final user = _TestUser(id: 'dynamic-id', name: 'Test');
        final dynamicFn = config.dynamicGetId;

        expect(dynamicFn(user), 'dynamic-id');
      });
    });

    group('dynamicFromJson', () {
      test('works with dynamic types', () {
        final dynamicFn = config.dynamicFromJson;
        final result = dynamicFn({'id': 'dyn', 'name': 'Dynamic'});

        expect(result, isA<_TestUser>());
        expect((result! as _TestUser).id, 'dyn');
      });
    });

    group('dynamicToJson', () {
      test('works with dynamic types', () {
        final user = _TestUser(id: 'json-id', name: 'JSON');
        final dynamicFn = config.dynamicToJson;
        final result = dynamicFn(user);

        expect(result['id'], 'json-id');
        expect(result['name'], 'JSON');
      });
    });

    group('merge configuration', () {
      test('effectiveMergeConfig returns default when not configured', () {
        final effective = config.effectiveMergeConfig;

        expect(effective.defaultStrategy, CrdtMergeStrategy.lww);
        expect(effective.fieldStrategies, isEmpty);
      });

      test('effectiveMergeConfig returns configured value', () {
        const mergeConfig = CrdtMergeConfig<_TestUser>(
          defaultStrategy: CrdtMergeStrategy.fww,
          fieldStrategies: {'name': CrdtMergeStrategy.lww},
        );
        final configWithMerge = config.copyWith(mergeConfig: mergeConfig);

        expect(
          configWithMerge.effectiveMergeConfig.defaultStrategy,
          CrdtMergeStrategy.fww,
        );
        expect(
          configWithMerge.effectiveMergeConfig.fieldStrategies['name'],
          CrdtMergeStrategy.lww,
        );
      });
    });

    group('toTableDefinition', () {
      test('creates CrdtTableDefinition', () {
        final definition = config.toTableDefinition();

        expect(definition.tableName, 'users');
        expect(definition.columns, hasLength(3));
        expect(definition.primaryKeyColumn, 'id');
      });

      test('includes indexes in definition', () {
        final configWithIndexes = config.copyWith(
          indexes: [
            const CrdtIndex(name: 'idx_name', columns: ['name'])
          ],
        );
        final definition = configWithIndexes.toTableDefinition();

        expect(definition.indexes, hasLength(1));
        expect(definition.indexes![0].name, 'idx_name');
      });
    });

    group('copyWith', () {
      test('copies all fields', () {
        final newColumns = [CrdtColumn.text('new_col')];
        final copied = config.copyWith(
          tableName: 'new_table',
          columns: newColumns,
          primaryKeyColumn: 'new_pk',
        );

        expect(copied.tableName, 'new_table');
        expect(copied.columns, newColumns);
        expect(copied.primaryKeyColumn, 'new_pk');
        // Original functions should be preserved
        expect(
          copied.getId(_TestUser(id: 'test', name: 'Test')),
          'test',
        );
      });

      test('preserves original when not overridden', () {
        final copied = config.copyWith(tableName: 'updated');

        expect(copied.tableName, 'updated');
        expect(copied.columns, config.columns);
        expect(copied.primaryKeyColumn, config.primaryKeyColumn);
      });
    });
  });
}
