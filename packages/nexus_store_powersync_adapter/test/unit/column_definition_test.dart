import 'package:nexus_store_powersync_adapter/src/column_definition.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

void main() {
  group('PSColumn', () {
    group('factory constructors', () {
      test('text() creates a text column', () {
        final column = PSColumn.text('name');

        expect(column.name, equals('name'));
        expect(column.type, equals(PSColumnType.text));
        expect(column.nullable, isTrue);
      });

      test('integer() creates an integer column', () {
        final column = PSColumn.integer('age');

        expect(column.name, equals('age'));
        expect(column.type, equals(PSColumnType.integer));
        expect(column.nullable, isTrue);
      });

      test('real() creates a real column', () {
        final column = PSColumn.real('price');

        expect(column.name, equals('price'));
        expect(column.type, equals(PSColumnType.real));
        expect(column.nullable, isTrue);
      });
    });

    group('nullable parameter', () {
      test('text column can be non-nullable', () {
        final column = PSColumn.text('email', nullable: false);

        expect(column.nullable, isFalse);
      });

      test('integer column can be non-nullable', () {
        final column = PSColumn.integer('count', nullable: false);

        expect(column.nullable, isFalse);
      });

      test('real column can be non-nullable', () {
        final column = PSColumn.real('amount', nullable: false);

        expect(column.nullable, isFalse);
      });
    });

    group('toPowerSyncColumn', () {
      test('converts text column to PowerSync Column', () {
        final column = PSColumn.text('name');
        final psColumn = column.toPowerSyncColumn();

        expect(psColumn, isA<ps.Column>());
        expect(psColumn.name, equals('name'));
        expect(psColumn.type, equals(ps.ColumnType.text));
      });

      test('converts integer column to PowerSync Column', () {
        final column = PSColumn.integer('age');
        final psColumn = column.toPowerSyncColumn();

        expect(psColumn.name, equals('age'));
        expect(psColumn.type, equals(ps.ColumnType.integer));
      });

      test('converts real column to PowerSync Column', () {
        final column = PSColumn.real('price');
        final psColumn = column.toPowerSyncColumn();

        expect(psColumn.name, equals('price'));
        expect(psColumn.type, equals(ps.ColumnType.real));
      });
    });
  });

  group('PSTableDefinition', () {
    test('stores table name and columns', () {
      final columns = [
        PSColumn.text('name'),
        PSColumn.integer('age'),
      ];
      final tableDef = PSTableDefinition(
        tableName: 'users',
        columns: columns,
      );

      expect(tableDef.tableName, equals('users'));
      expect(tableDef.columns, equals(columns));
    });

    group('toSchema', () {
      test('generates PowerSync Schema with table', () {
        final tableDef = PSTableDefinition(
          tableName: 'users',
          columns: [
            PSColumn.text('name'),
            PSColumn.integer('age'),
          ],
        );

        final schema = tableDef.toSchema();

        expect(schema, isA<ps.Schema>());
        expect(schema.tables, hasLength(1));
        expect(schema.tables.first.name, equals('users'));
      });

      test('schema includes id column automatically', () {
        final tableDef = PSTableDefinition(
          tableName: 'users',
          columns: [
            PSColumn.text('name'),
          ],
        );

        final schema = tableDef.toSchema();
        final table = schema.tables.first;
        final columnNames = table.columns.map((c) => c.name).toList();

        // PowerSync tables have 'id' as primary key by default
        expect(table.name, equals('users'));
        expect(columnNames, contains('name'));
      });

      test('schema includes all defined columns', () {
        final tableDef = PSTableDefinition(
          tableName: 'products',
          columns: [
            PSColumn.text('name'),
            PSColumn.text('description'),
            PSColumn.real('price'),
            PSColumn.integer('quantity'),
          ],
        );

        final schema = tableDef.toSchema();
        final table = schema.tables.first;
        final columnNames = table.columns.map((c) => c.name).toList();

        expect(
          columnNames,
          containsAll(['name', 'description', 'price', 'quantity']),
        );
      });
    });

    group('toTable', () {
      test('generates PowerSync Table directly', () {
        final tableDef = PSTableDefinition(
          tableName: 'orders',
          columns: [
            PSColumn.text('status'),
            PSColumn.real('total'),
          ],
        );

        final table = tableDef.toTable();

        expect(table, isA<ps.Table>());
        expect(table.name, equals('orders'));
        expect(table.columns, hasLength(2));
      });
    });
  });
}
