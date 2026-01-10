import 'package:nexus_store_supabase_adapter/src/supabase_column.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_table_config.dart';
import 'package:test/test.dart';

class User {
  User({required this.id, required this.name, this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
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
        if (email != null) 'email': email,
      };
}

void main() {
  group('SupabaseTableConfig', () {
    test('creates config with required fields', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('name', nullable: false),
          SupabaseColumn.text('email'),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
      );

      expect(config.tableName, 'users');
      expect(config.columns, hasLength(3));
      expect(config.primaryKeyColumn, 'id');
      expect(config.schema, 'public');
      expect(config.enableRealtime, false);
      expect(config.fieldMapping, isNull);
    });

    test('creates config with custom schema', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        schema: 'auth',
      );

      expect(config.schema, 'auth');
    });

    test('creates config with realtime enabled', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        enableRealtime: true,
      );

      expect(config.enableRealtime, true);
    });

    test('creates config with custom primary key column', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('user_id', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        primaryKeyColumn: 'user_id',
      );

      expect(config.primaryKeyColumn, 'user_id');
    });

    test('creates config with field mapping', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('full_name', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        fieldMapping: {'name': 'full_name'},
      );

      expect(config.fieldMapping, {'name': 'full_name'});
    });

    test('creates config with indexes', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('email'),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        indexes: [
          const SupabaseIndex(
            name: 'idx_users_email',
            columns: ['email'],
            unique: true,
          ),
        ],
      );

      expect(config.indexes, hasLength(1));
      expect(config.indexes!.first.name, 'idx_users_email');
    });

    group('toTableDefinition', () {
      test('converts to table definition', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
            SupabaseColumn.text('name', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final definition = config.toTableDefinition();
        expect(definition.tableName, 'users');
        expect(definition.columns, hasLength(2));
        expect(definition.primaryKeyColumn, 'id');
        expect(definition.schema, 'public');
      });

      test('preserves schema in table definition', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          schema: 'custom_schema',
        );

        final definition = config.toTableDefinition();
        expect(definition.schema, 'custom_schema');
      });

      test('preserves indexes in table definition', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
          indexes: [
            const SupabaseIndex(name: 'idx_test', columns: ['id']),
          ],
        );

        final definition = config.toTableDefinition();
        expect(definition.indexes, hasLength(1));
      });
    });

    group('dynamic wrappers', () {
      test('dynamicGetId extracts ID correctly', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final user = User(id: 'user-123', name: 'Test User');
        expect(config.dynamicGetId(user), 'user-123');
      });

      test('dynamicFromJson deserializes correctly', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final json = {'id': 'user-456', 'name': 'Another User'};
        final result = config.dynamicFromJson(json);
        expect(result, isA<User>());
        final user = result! as User;
        expect(user.id, 'user-456');
        expect(user.name, 'Another User');
      });

      test('dynamicToJson serializes correctly', () {
        final config = SupabaseTableConfig<User, String>(
          tableName: 'users',
          columns: [
            SupabaseColumn.uuid('id', nullable: false),
          ],
          fromJson: User.fromJson,
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
        );

        final user = User(id: 'user-789', name: 'Third User', email: 'a@b.com');
        final json = config.dynamicToJson(user);
        expect(json, {'id': 'user-789', 'name': 'Third User', 'email': 'a@b.com'});
      });
    });
  });
}
