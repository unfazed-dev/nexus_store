import 'package:nexus_store_supabase_adapter/src/supabase_column.dart';
import 'package:test/test.dart';

void main() {
  group('SupabaseColumnType', () {
    test('has all PostgreSQL column types', () {
      expect(SupabaseColumnType.values, containsAll([
        SupabaseColumnType.text,
        SupabaseColumnType.integer,
        SupabaseColumnType.bigint,
        SupabaseColumnType.float8,
        SupabaseColumnType.boolean,
        SupabaseColumnType.timestamptz,
        SupabaseColumnType.uuid,
        SupabaseColumnType.jsonb,
      ]),);
    });
  });

  group('SupabaseColumn', () {
    group('factory methods', () {
      test('text() creates TEXT column', () {
        final column = SupabaseColumn.text('name');
        expect(column.name, 'name');
        expect(column.type, SupabaseColumnType.text);
        expect(column.nullable, true);
        expect(column.defaultValue, isNull);
      });

      test('text() with options', () {
        final column = SupabaseColumn.text(
          'status',
          nullable: false,
          defaultValue: 'active',
        );
        expect(column.name, 'status');
        expect(column.nullable, false);
        expect(column.defaultValue, 'active');
      });

      test('integer() creates INTEGER column', () {
        final column = SupabaseColumn.integer('count');
        expect(column.name, 'count');
        expect(column.type, SupabaseColumnType.integer);
        expect(column.nullable, true);
      });

      test('integer() with default value', () {
        final column = SupabaseColumn.integer('count', defaultValue: 0);
        expect(column.defaultValue, 0);
      });

      test('bigint() creates BIGINT column', () {
        final column = SupabaseColumn.bigint('big_id');
        expect(column.name, 'big_id');
        expect(column.type, SupabaseColumnType.bigint);
      });

      test('float8() creates FLOAT8 column', () {
        final column = SupabaseColumn.float8('price');
        expect(column.name, 'price');
        expect(column.type, SupabaseColumnType.float8);
      });

      test('float8() with default value', () {
        final column = SupabaseColumn.float8('price', defaultValue: 0);
        expect(column.defaultValue, 0.0);
      });

      test('boolean() creates BOOLEAN column', () {
        final column = SupabaseColumn.boolean('active');
        expect(column.name, 'active');
        expect(column.type, SupabaseColumnType.boolean);
      });

      test('boolean() with default value', () {
        final column = SupabaseColumn.boolean('active', defaultValue: true);
        expect(column.defaultValue, true);
      });

      test('timestamptz() creates TIMESTAMPTZ column', () {
        final column = SupabaseColumn.timestamptz('created_at');
        expect(column.name, 'created_at');
        expect(column.type, SupabaseColumnType.timestamptz);
      });

      test('timestamptz() with defaultNow option', () {
        final column = SupabaseColumn.timestamptz(
          'created_at',
          defaultNow: true,
        );
        expect(column.defaultNow, true);
      });

      test('uuid() creates UUID column', () {
        final column = SupabaseColumn.uuid('id');
        expect(column.name, 'id');
        expect(column.type, SupabaseColumnType.uuid);
      });

      test('uuid() with defaultGenerate option', () {
        final column = SupabaseColumn.uuid('id', defaultGenerate: true);
        expect(column.defaultGenerate, true);
      });

      test('jsonb() creates JSONB column', () {
        final column = SupabaseColumn.jsonb('metadata');
        expect(column.name, 'metadata');
        expect(column.type, SupabaseColumnType.jsonb);
      });

      test('jsonb() with default value', () {
        final column = SupabaseColumn.jsonb('metadata', defaultValue: '{}');
        expect(column.defaultValue, '{}');
      });
    });

    group('validation', () {
      test('throws on empty column name', () {
        expect(
          () => SupabaseColumn.text(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on column name with spaces', () {
        expect(
          () => SupabaseColumn.text('my column'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on reserved SQL keywords', () {
        expect(
          () => SupabaseColumn.text('select'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => SupabaseColumn.text('FROM'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => SupabaseColumn.text('Where'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows valid column names', () {
        expect(() => SupabaseColumn.text('user_name'), returnsNormally);
        expect(() => SupabaseColumn.text('firstName'), returnsNormally);
        expect(() => SupabaseColumn.text('col123'), returnsNormally);
      });
    });

    group('toSqlDefinition', () {
      test('generates TEXT column SQL', () {
        final column = SupabaseColumn.text('name', nullable: false);
        expect(column.toSqlDefinition(), '"name" TEXT NOT NULL');
      });

      test('generates nullable column SQL', () {
        final column = SupabaseColumn.text('name');
        expect(column.toSqlDefinition(), '"name" TEXT');
      });

      test('generates INTEGER column SQL with default', () {
        final column = SupabaseColumn.integer('count', defaultValue: 0);
        expect(column.toSqlDefinition(), '"count" INTEGER DEFAULT 0');
      });

      test('generates BIGINT column SQL', () {
        final column = SupabaseColumn.bigint('big_id', nullable: false);
        expect(column.toSqlDefinition(), '"big_id" BIGINT NOT NULL');
      });

      test('generates FLOAT8 column SQL', () {
        final column = SupabaseColumn.float8('price');
        expect(column.toSqlDefinition(), '"price" FLOAT8');
      });

      test('generates BOOLEAN column SQL with default', () {
        final column = SupabaseColumn.boolean('active', defaultValue: true);
        expect(column.toSqlDefinition(), '"active" BOOLEAN DEFAULT true');
      });

      test('generates TIMESTAMPTZ column SQL', () {
        final column = SupabaseColumn.timestamptz('created_at');
        expect(column.toSqlDefinition(), '"created_at" TIMESTAMPTZ');
      });

      test('generates TIMESTAMPTZ with now() default', () {
        final column = SupabaseColumn.timestamptz(
          'created_at',
          defaultNow: true,
        );
        expect(
          column.toSqlDefinition(),
          '"created_at" TIMESTAMPTZ DEFAULT now()',
        );
      });

      test('generates UUID column SQL', () {
        final column = SupabaseColumn.uuid('id', nullable: false);
        expect(column.toSqlDefinition(), '"id" UUID NOT NULL');
      });

      test('generates UUID with gen_random_uuid() default', () {
        final column = SupabaseColumn.uuid('id', defaultGenerate: true);
        expect(
          column.toSqlDefinition(),
          '"id" UUID DEFAULT gen_random_uuid()',
        );
      });

      test('generates JSONB column SQL', () {
        final column = SupabaseColumn.jsonb('metadata');
        expect(column.toSqlDefinition(), '"metadata" JSONB');
      });

      test('generates JSONB with default', () {
        final column = SupabaseColumn.jsonb(
          'metadata',
          nullable: false,
          defaultValue: "'{}'::jsonb",
        );
        expect(
          column.toSqlDefinition(),
          '''"metadata" JSONB NOT NULL DEFAULT '{}'::jsonb''',
        );
      });

      test('generates TEXT with quoted default value', () {
        final column = SupabaseColumn.text('status', defaultValue: 'pending');
        expect(
          column.toSqlDefinition(),
          '"status" TEXT DEFAULT \'pending\'',
        );
      });
    });
  });

  group('SupabaseTableDefinition', () {
    test('generates CREATE TABLE SQL', () {
      final definition = SupabaseTableDefinition(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('name', nullable: false),
          SupabaseColumn.text('email'),
        ],
        primaryKeyColumn: 'id',
      );

      final sql = definition.toCreateTableSql();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS "users"'));
      expect(sql, contains('"id" UUID NOT NULL'));
      expect(sql, contains('"name" TEXT NOT NULL'));
      expect(sql, contains('"email" TEXT'));
      expect(sql, contains('PRIMARY KEY ("id")'));
    });

    test('generates CREATE TABLE SQL with schema', () {
      final definition = SupabaseTableDefinition(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
        ],
        primaryKeyColumn: 'id',
        schema: 'auth',
      );

      final sql = definition.toCreateTableSql();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS "auth"."users"'));
    });

    test('generates CREATE INDEX SQL', () {
      final definition = SupabaseTableDefinition(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('email'),
        ],
        primaryKeyColumn: 'id',
        indexes: [
          const SupabaseIndex(
            name: 'idx_users_email',
            columns: ['email'],
            unique: true,
          ),
        ],
      );

      final indexSql = definition.toCreateIndexSql();
      expect(indexSql, hasLength(1));
      expect(
        indexSql.first,
        'CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email")',
      );
    });

    test('generates RLS enable SQL', () {
      final definition = SupabaseTableDefinition(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
        ],
        primaryKeyColumn: 'id',
        enableRLS: true,
      );

      expect(
        definition.toEnableRLSSql(),
        'ALTER TABLE "users" ENABLE ROW LEVEL SECURITY',
      );
    });

    test('toEnableRLSSql returns null when RLS disabled', () {
      final definition = SupabaseTableDefinition(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
        ],
        primaryKeyColumn: 'id',
      );

      expect(definition.toEnableRLSSql(), isNull);
    });
  });

  group('SupabaseIndex', () {
    test('generates simple index SQL', () {
      const index = SupabaseIndex(
        name: 'idx_users_name',
        columns: ['name'],
      );

      expect(
        index.toSql('users'),
        'CREATE INDEX IF NOT EXISTS "idx_users_name" ON "users" ("name")',
      );
    });

    test('generates unique index SQL', () {
      const index = SupabaseIndex(
        name: 'idx_users_email',
        columns: ['email'],
        unique: true,
      );

      expect(
        index.toSql('users'),
        'CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" '
            'ON "users" ("email")',
      );
    });

    test('generates composite index SQL', () {
      const index = SupabaseIndex(
        name: 'idx_posts_user_created',
        columns: ['user_id', 'created_at'],
      );

      expect(
        index.toSql('posts'),
        'CREATE INDEX IF NOT EXISTS "idx_posts_user_created" '
            'ON "posts" ("user_id", "created_at")',
      );
    });

    test('equality', () {
      const index1 = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'b'],
        unique: true,
      );
      const index2 = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'b'],
        unique: true,
      );
      const index3 = SupabaseIndex(
        name: 'idx_test',
        columns: ['a'],
        unique: true,
      );

      expect(index1, equals(index2));
      expect(index1, isNot(equals(index3)));
      expect(index1.hashCode, index2.hashCode);
    });

    test('equality compares unique property', () {
      // Test line 445: unique == other.unique
      const uniqueIndex = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'b'],
        unique: true,
      );
      const nonUniqueIndex = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'b'],
      );

      // Same name, same columns, different unique flag
      expect(uniqueIndex, isNot(equals(nonUniqueIndex)));
    });

    test('equality compares column elements at same positions', () {
      // Test lines 453-454: for loop iterating over elements
      const index1 = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'b'],
        unique: true,
      );
      const index2 = SupabaseIndex(
        name: 'idx_test',
        columns: ['a', 'c'], // Same length, different second element
        unique: true,
      );

      // Same name, same length, different column at position 1
      expect(index1, isNot(equals(index2)));
    });

    test('equality returns true for identical indexes', () {
      // Test full equality path including line 445 returning true
      const index1 = SupabaseIndex(
        name: 'idx_test',
        columns: ['x', 'y', 'z'],
      );
      const index2 = SupabaseIndex(
        name: 'idx_test',
        columns: ['x', 'y', 'z'],
      );

      expect(index1, equals(index2));
    });
  });
}
