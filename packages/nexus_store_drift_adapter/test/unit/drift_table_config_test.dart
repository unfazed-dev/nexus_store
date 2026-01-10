import 'package:nexus_store_drift_adapter/nexus_store_drift_adapter.dart';
import 'package:test/test.dart';

// Test model
class TestUser {
  const TestUser({
    required this.id,
    required this.name,
    this.email,
    this.age,
  });

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        age: json['age'] as int?,
      );

  final String id;
  final String name;
  final String? email;
  final int? age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
      };
}

void main() {
  group('DriftTableConfig', () {
    late List<DriftColumn> columns;

    setUp(() {
      columns = [
        DriftColumn.text('id', nullable: false),
        DriftColumn.text('name', nullable: false),
        DriftColumn.text('email'),
        DriftColumn.integer('age'),
      ];
    });

    group('construction', () {
      test('creates config with required parameters', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        expect(config.tableName, equals('users'));
        expect(config.columns, equals(columns));
        expect(config.primaryKeyColumn, equals('id'));
      });

      test('allows custom primary key column', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          primaryKeyColumn: 'user_id',
        );

        expect(config.primaryKeyColumn, equals('user_id'));
      });

      test('allows field mapping', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          fieldMapping: {'email': 'email_address'},
        );

        expect(config.fieldMapping, equals({'email': 'email_address'}));
      });

      test('allows indexes', () {
        final indexes = [
          const DriftIndex(name: 'idx_users_email', columns: ['email']),
          const DriftIndex(name: 'idx_users_name', columns: ['name']),
        ];

        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          indexes: indexes,
        );

        expect(config.indexes, equals(indexes));
      });
    });

    group('serialization', () {
      test('fromJson deserializes correctly', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final user = config.fromJson({
          'id': '123',
          'name': 'John',
          'email': 'john@example.com',
          'age': 30,
        });

        expect(user.id, equals('123'));
        expect(user.name, equals('John'));
        expect(user.email, equals('john@example.com'));
        expect(user.age, equals(30));
      });

      test('toJson serializes correctly', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        const user = TestUser(
          id: '123',
          name: 'John',
          email: 'john@example.com',
          age: 30,
        );

        final json = config.toJson(user);

        expect(json['id'], equals('123'));
        expect(json['name'], equals('John'));
        expect(json['email'], equals('john@example.com'));
        expect(json['age'], equals(30));
      });

      test('getId extracts ID correctly', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        const user = TestUser(id: '123', name: 'John');
        expect(config.getId(user), equals('123'));
      });
    });

    group('toTableDefinition', () {
      test('generates table definition with all columns', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final definition = config.toTableDefinition();

        expect(definition.tableName, equals('users'));
        expect(definition.columns, equals(columns));
        expect(definition.primaryKeyColumn, equals('id'));
      });

      test('table definition generates CREATE TABLE SQL', () {
        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final definition = config.toTableDefinition();
        final sql = definition.toCreateTableSql();

        expect(sql, contains('CREATE TABLE IF NOT EXISTS "users"'));
        expect(sql, contains('"id" TEXT NOT NULL'));
        expect(sql, contains('"name" TEXT NOT NULL'));
        expect(sql, contains('"email" TEXT'));
        expect(sql, contains('"age" INTEGER'));
        expect(sql, contains('PRIMARY KEY ("id")'));
      });

      test('table definition includes indexes', () {
        final indexes = [
          const DriftIndex(name: 'idx_users_email', columns: ['email']),
        ];

        final config = DriftTableConfig<TestUser, String>(
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          indexes: indexes,
        );

        final definition = config.toTableDefinition();
        expect(definition.indexes, equals(indexes));
      });
    });
  });

  group('DriftTableDefinition', () {
    test('generates CREATE TABLE SQL with primary key', () {
      final columns = [
        DriftColumn.text('id', nullable: false),
        DriftColumn.text('name', nullable: false),
      ];

      final definition = DriftTableDefinition(
        tableName: 'items',
        columns: columns,
        primaryKeyColumn: 'id',
      );

      final sql = definition.toCreateTableSql();

      expect(sql, contains('CREATE TABLE IF NOT EXISTS "items"'));
      expect(sql, contains('"id" TEXT NOT NULL'));
      expect(sql, contains('"name" TEXT NOT NULL'));
      expect(sql, contains('PRIMARY KEY ("id")'));
    });

    test('generates CREATE TABLE SQL with multiple columns', () {
      final columns = [
        DriftColumn.text('id', nullable: false),
        DriftColumn.text('title', nullable: false),
        DriftColumn.text('description'),
        DriftColumn.integer('priority', defaultValue: 0),
        DriftColumn.boolean('completed', defaultValue: false),
        DriftColumn.dateTime('createdAt'),
      ];

      final definition = DriftTableDefinition(
        tableName: 'tasks',
        columns: columns,
        primaryKeyColumn: 'id',
      );

      final sql = definition.toCreateTableSql();

      expect(sql, contains('"id" TEXT NOT NULL'));
      expect(sql, contains('"title" TEXT NOT NULL'));
      expect(sql, contains('"description" TEXT'));
      expect(sql, contains('"priority" INTEGER DEFAULT 0'));
      expect(sql, contains('"completed" INTEGER DEFAULT 0'));
      expect(sql, contains('"createdAt" INTEGER'));
    });
  });

  group('DriftIndex', () {
    test('generates CREATE INDEX SQL', () {
      const index = DriftIndex(
        name: 'idx_users_email',
        columns: ['email'],
      );

      final sql = index.toSql('users');

      expect(sql, equals('CREATE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email")'));
    });

    test('generates CREATE INDEX SQL with multiple columns', () {
      const index = DriftIndex(
        name: 'idx_users_name_email',
        columns: ['name', 'email'],
      );

      final sql = index.toSql('users');

      expect(sql, equals('CREATE INDEX IF NOT EXISTS "idx_users_name_email" ON "users" ("name", "email")'));
    });

    test('generates CREATE UNIQUE INDEX SQL', () {
      const index = DriftIndex(
        name: 'idx_users_email_unique',
        columns: ['email'],
        unique: true,
      );

      final sql = index.toSql('users');

      expect(sql, equals('CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email_unique" ON "users" ("email")'));
    });

    group('equality', () {
      test('equal indexes are equal', () {
        const index1 = DriftIndex(
          name: 'idx_test',
          columns: ['col1', 'col2'],
          unique: true,
        );
        const index2 = DriftIndex(
          name: 'idx_test',
          columns: ['col1', 'col2'],
          unique: true,
        );

        expect(index1, equals(index2));
        expect(index1.hashCode, equals(index2.hashCode));
      });

      test('indexes with different names are not equal', () {
        const index1 = DriftIndex(name: 'idx_a', columns: ['col']);
        const index2 = DriftIndex(name: 'idx_b', columns: ['col']);

        expect(index1, isNot(equals(index2)));
      });

      test('indexes with different columns are not equal', () {
        const index1 = DriftIndex(name: 'idx', columns: ['col1']);
        const index2 = DriftIndex(name: 'idx', columns: ['col2']);

        expect(index1, isNot(equals(index2)));
      });

      test('indexes with different column order are not equal', () {
        const index1 = DriftIndex(name: 'idx', columns: ['a', 'b']);
        const index2 = DriftIndex(name: 'idx', columns: ['b', 'a']);

        expect(index1, isNot(equals(index2)));
      });

      test('indexes with different unique flag are not equal', () {
        const index1 = DriftIndex(name: 'idx', columns: ['col'], unique: true);
        const index2 = DriftIndex(name: 'idx', columns: ['col']);

        expect(index1, isNot(equals(index2)));
      });

      test('indexes with different column count are not equal', () {
        const index1 = DriftIndex(name: 'idx', columns: ['a']);
        const index2 = DriftIndex(name: 'idx', columns: ['a', 'b']);

        expect(index1, isNot(equals(index2)));
      });

      test('index is not equal to non-index object', () {
        const index = DriftIndex(name: 'idx', columns: ['col']);

        // ignore: unrelated_type_equality_checks
        expect(index == 'not an index', isFalse);
      });

      test('identical indexes are equal', () {
        const index = DriftIndex(name: 'idx', columns: ['col']);

        expect(identical(index, index), isTrue);
        expect(index, equals(index));
      });
    });
  });
}
