import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('DriftColumn', () {
    group('factory constructors', () {
      test('text creates a TEXT column', () {
        final column = DriftColumn.text('name');

        expect(column.name, equals('name'));
        expect(column.type, equals(DriftColumnType.text));
        expect(column.nullable, isTrue);
      });

      test('text with nullable false creates NOT NULL column', () {
        final column = DriftColumn.text('name', nullable: false);

        expect(column.name, equals('name'));
        expect(column.nullable, isFalse);
      });

      test('text with defaultValue sets default', () {
        final column = DriftColumn.text('status', defaultValue: 'active');

        expect(column.defaultValue, equals('active'));
      });

      test('integer creates an INTEGER column', () {
        final column = DriftColumn.integer('age');

        expect(column.name, equals('age'));
        expect(column.type, equals(DriftColumnType.integer));
        expect(column.nullable, isTrue);
      });

      test('integer with defaultValue sets default', () {
        final column = DriftColumn.integer('count', defaultValue: 0);

        expect(column.defaultValue, equals(0));
      });

      test('real creates a REAL column', () {
        final column = DriftColumn.real('price');

        expect(column.name, equals('price'));
        expect(column.type, equals(DriftColumnType.real));
      });

      test('real with defaultValue sets default', () {
        final column = DriftColumn.real('amount', defaultValue: 0);

        expect(column.defaultValue, equals(0.0));
      });

      test('boolean creates a BOOLEAN column', () {
        final column = DriftColumn.boolean('active');

        expect(column.name, equals('active'));
        expect(column.type, equals(DriftColumnType.boolean));
      });

      test('boolean with defaultValue sets default', () {
        final column = DriftColumn.boolean('enabled', defaultValue: true);

        expect(column.defaultValue, equals(true));
      });

      test('dateTime creates a DATETIME column', () {
        final column = DriftColumn.dateTime('createdAt');

        expect(column.name, equals('createdAt'));
        expect(column.type, equals(DriftColumnType.dateTime));
      });

      test('blob creates a BLOB column', () {
        final column = DriftColumn.blob('data');

        expect(column.name, equals('data'));
        expect(column.type, equals(DriftColumnType.blob));
      });
    });

    group('validation', () {
      test('throws ArgumentError for empty column name', () {
        expect(
          () => DriftColumn.text(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for column name with spaces', () {
        expect(
          () => DriftColumn.text('column name'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for reserved SQL keyword', () {
        expect(
          () => DriftColumn.text('SELECT'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for reserved keyword case-insensitive', () {
        expect(
          () => DriftColumn.text('select'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toSqlDefinition', () {
      test('generates TEXT NOT NULL for non-nullable text', () {
        final column = DriftColumn.text('name', nullable: false);

        expect(column.toSqlDefinition(), equals('"name" TEXT NOT NULL'));
      });

      test('generates TEXT for nullable text', () {
        final column = DriftColumn.text('name');

        expect(column.toSqlDefinition(), equals('"name" TEXT'));
      });

      test('generates TEXT NOT NULL with default value', () {
        final column = DriftColumn.text(
          'status',
          nullable: false,
          defaultValue: 'active',
        );

        expect(
          column.toSqlDefinition(),
          equals("\"status\" TEXT NOT NULL DEFAULT 'active'"),
        );
      });

      test('generates INTEGER NOT NULL for non-nullable integer', () {
        final column = DriftColumn.integer('age', nullable: false);

        expect(column.toSqlDefinition(), equals('"age" INTEGER NOT NULL'));
      });

      test('generates INTEGER with default value', () {
        final column = DriftColumn.integer('count', defaultValue: 0);

        expect(column.toSqlDefinition(), equals('"count" INTEGER DEFAULT 0'));
      });

      test('generates REAL for real column', () {
        final column = DriftColumn.real('price');

        expect(column.toSqlDefinition(), equals('"price" REAL'));
      });

      test('generates REAL with default value', () {
        final column = DriftColumn.real('amount', defaultValue: 0);

        expect(column.toSqlDefinition(), equals('"amount" REAL DEFAULT 0.0'));
      });

      test('generates INTEGER for boolean column (SQLite stores as 0/1)', () {
        final column = DriftColumn.boolean('active');

        expect(column.toSqlDefinition(), equals('"active" INTEGER'));
      });

      test('generates INTEGER with default 1 for boolean true', () {
        final column = DriftColumn.boolean('enabled', defaultValue: true);

        expect(column.toSqlDefinition(), equals('"enabled" INTEGER DEFAULT 1'));
      });

      test('generates INTEGER with default 0 for boolean false', () {
        final column = DriftColumn.boolean('disabled', defaultValue: false);

        expect(
          column.toSqlDefinition(),
          equals('"disabled" INTEGER DEFAULT 0'),
        );
      });

      test('generates INTEGER for dateTime column (epoch ms)', () {
        final column = DriftColumn.dateTime('createdAt');

        expect(column.toSqlDefinition(), equals('"createdAt" INTEGER'));
      });

      test('generates BLOB for blob column', () {
        final column = DriftColumn.blob('data');

        expect(column.toSqlDefinition(), equals('"data" BLOB'));
      });
    });
  });
}
