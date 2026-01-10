import 'package:nexus_store_crdt_adapter/src/crdt_column.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtColumnType', () {
    test('has all expected values', () {
      expect(CrdtColumnType.values, hasLength(4));
      expect(CrdtColumnType.values, contains(CrdtColumnType.text));
      expect(CrdtColumnType.values, contains(CrdtColumnType.integer));
      expect(CrdtColumnType.values, contains(CrdtColumnType.real));
      expect(CrdtColumnType.values, contains(CrdtColumnType.blob));
    });
  });

  group('CrdtColumn', () {
    group('text factory', () {
      test('creates text column with defaults', () {
        final column = CrdtColumn.text('name');

        expect(column.name, 'name');
        expect(column.type, CrdtColumnType.text);
        expect(column.nullable, true);
        expect(column.defaultValue, isNull);
      });

      test('creates non-nullable text column', () {
        final column = CrdtColumn.text('name', nullable: false);

        expect(column.nullable, false);
      });

      test('creates text column with default value', () {
        final column = CrdtColumn.text('status', defaultValue: 'active');

        expect(column.defaultValue, 'active');
      });
    });

    group('integer factory', () {
      test('creates integer column with defaults', () {
        final column = CrdtColumn.integer('age');

        expect(column.name, 'age');
        expect(column.type, CrdtColumnType.integer);
        expect(column.nullable, true);
        expect(column.defaultValue, isNull);
      });

      test('creates non-nullable integer column', () {
        final column = CrdtColumn.integer('count', nullable: false);

        expect(column.nullable, false);
      });

      test('creates integer column with default value', () {
        final column = CrdtColumn.integer('count', defaultValue: 0);

        expect(column.defaultValue, 0);
      });
    });

    group('real factory', () {
      test('creates real column with defaults', () {
        final column = CrdtColumn.real('price');

        expect(column.name, 'price');
        expect(column.type, CrdtColumnType.real);
        expect(column.nullable, true);
        expect(column.defaultValue, isNull);
      });

      test('creates non-nullable real column', () {
        final column = CrdtColumn.real('amount', nullable: false);

        expect(column.nullable, false);
      });

      test('creates real column with default value', () {
        final column = CrdtColumn.real('price', defaultValue: 0);

        expect(column.defaultValue, 0.0);
      });
    });

    group('blob factory', () {
      test('creates blob column with defaults', () {
        final column = CrdtColumn.blob('data');

        expect(column.name, 'data');
        expect(column.type, CrdtColumnType.blob);
        expect(column.nullable, true);
      });

      test('creates non-nullable blob column', () {
        final column = CrdtColumn.blob('image', nullable: false);

        expect(column.nullable, false);
      });
    });

    group('validation', () {
      test('throws on empty column name', () {
        expect(
          () => CrdtColumn.text(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on column name with spaces', () {
        expect(
          () => CrdtColumn.text('first name'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on reserved SQL keyword', () {
        expect(
          () => CrdtColumn.text('select'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => CrdtColumn.text('FROM'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('accepts valid column names', () {
        expect(() => CrdtColumn.text('firstName'), returnsNormally);
        expect(() => CrdtColumn.text('user_name'), returnsNormally);
        expect(() => CrdtColumn.text('_id'), returnsNormally);
      });
    });

    group('toSqlDefinition', () {
      test('generates TEXT column definition', () {
        final column = CrdtColumn.text('name');

        expect(column.toSqlDefinition(), '"name" TEXT');
      });

      test('generates INTEGER column definition', () {
        final column = CrdtColumn.integer('age');

        expect(column.toSqlDefinition(), '"age" INTEGER');
      });

      test('generates REAL column definition', () {
        final column = CrdtColumn.real('price');

        expect(column.toSqlDefinition(), '"price" REAL');
      });

      test('generates BLOB column definition', () {
        final column = CrdtColumn.blob('data');

        expect(column.toSqlDefinition(), '"data" BLOB');
      });

      test('adds NOT NULL for non-nullable columns', () {
        final column = CrdtColumn.text('name', nullable: false);

        expect(column.toSqlDefinition(), '"name" TEXT NOT NULL');
      });

      test('adds DEFAULT for text columns', () {
        final column = CrdtColumn.text('status', defaultValue: 'active');

        expect(column.toSqlDefinition(), '"status" TEXT DEFAULT \'active\'');
      });

      test('adds DEFAULT for integer columns', () {
        final column = CrdtColumn.integer('count', defaultValue: 0);

        expect(column.toSqlDefinition(), '"count" INTEGER DEFAULT 0');
      });

      test('adds DEFAULT for real columns', () {
        final column = CrdtColumn.real('price', defaultValue: 9.99);

        expect(column.toSqlDefinition(), '"price" REAL DEFAULT 9.99');
      });

      test('generates non-nullable with default', () {
        final column = CrdtColumn.text(
          'status',
          nullable: false,
          defaultValue: 'pending',
        );

        expect(
          column.toSqlDefinition(),
          '"status" TEXT NOT NULL DEFAULT \'pending\'',
        );
      });
    });
  });

  group('CrdtTableDefinition', () {
    test('generates CREATE TABLE SQL', () {
      final definition = CrdtTableDefinition(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('name', nullable: false),
          CrdtColumn.text('email'),
          CrdtColumn.integer('age'),
        ],
        primaryKeyColumn: 'id',
      );

      final sql = definition.toCreateTableSql();

      expect(sql, contains('CREATE TABLE IF NOT EXISTS "users"'));
      expect(sql, contains('"id" TEXT NOT NULL'));
      expect(sql, contains('"name" TEXT NOT NULL'));
      expect(sql, contains('"email" TEXT'));
      expect(sql, contains('"age" INTEGER'));
      expect(sql, contains('PRIMARY KEY ("id")'));
    });

    test('includes index creation SQL', () {
      final definition = CrdtTableDefinition(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('email'),
        ],
        primaryKeyColumn: 'id',
        indexes: [
          const CrdtIndex(name: 'idx_users_email', columns: ['email']),
        ],
      );

      final indexSql = definition.toCreateIndexSql();

      expect(indexSql, hasLength(1));
      expect(
        indexSql.first,
        'CREATE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email")',
      );
    });

    test('generates unique index SQL', () {
      final definition = CrdtTableDefinition(
        tableName: 'users',
        columns: [
          CrdtColumn.text('id', nullable: false),
          CrdtColumn.text('email'),
        ],
        primaryKeyColumn: 'id',
        indexes: [
          const CrdtIndex(
            name: 'idx_users_email',
            columns: ['email'],
            unique: true,
          ),
        ],
      );

      final indexSql = definition.toCreateIndexSql();

      expect(
        indexSql.first,
        contains('CREATE UNIQUE INDEX'),
      );
    });

    test('generates composite index SQL', () {
      const index = CrdtIndex(
        name: 'idx_users_name_email',
        columns: ['name', 'email'],
      );

      final sql = index.toSql('users');

      expect(sql, contains('"name", "email"'));
    });
  });

  group('CrdtIndex', () {
    test('equality works correctly', () {
      const index1 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);
      const index2 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);
      const index3 = CrdtIndex(name: 'idx2', columns: ['a', 'b']);

      expect(index1, equals(index2));
      expect(index1, isNot(equals(index3)));
    });

    test('hashCode is consistent', () {
      const index1 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);
      const index2 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);

      expect(index1.hashCode, equals(index2.hashCode));
    });

    test('equality returns false for different column counts', () {
      const index1 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);
      const index2 = CrdtIndex(name: 'idx1', columns: ['a']);

      expect(index1, isNot(equals(index2)));
    });

    test('equality returns false for different column values', () {
      const index1 = CrdtIndex(name: 'idx1', columns: ['a', 'b']);
      const index2 = CrdtIndex(name: 'idx1', columns: ['a', 'c']);

      expect(index1, isNot(equals(index2)));
    });

    test('equality returns false for different unique flag', () {
      const index1 = CrdtIndex(name: 'idx1', columns: ['a']);
      const index2 = CrdtIndex(name: 'idx1', columns: ['a'], unique: true);

      expect(index1, isNot(equals(index2)));
    });

    test('equality returns true for identical lists', () {
      final columns = ['a', 'b'];
      final index1 = CrdtIndex(name: 'idx1', columns: columns);
      final index2 = CrdtIndex(name: 'idx1', columns: columns);

      expect(index1, equals(index2));
    });
  });
}
