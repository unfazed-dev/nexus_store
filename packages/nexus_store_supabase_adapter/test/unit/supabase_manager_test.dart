import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_column.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_manager.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_table_config.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

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

class Post {
  Post({required this.id, required this.title, required this.userId});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        title: json['title'] as String,
        userId: json['user_id'] as String,
      );

  final String id;
  final String title;
  final String userId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'user_id': userId,
      };
}

void main() {
  group('SupabaseManager', () {
    late MockSupabaseClient mockClient;
    late SupabaseTableConfig<User, String> userConfig;
    late SupabaseTableConfig<Post, String> postConfig;

    setUp(() {
      mockClient = MockSupabaseClient();

      userConfig = SupabaseTableConfig<User, String>(
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

      postConfig = SupabaseTableConfig<Post, String>(
        tableName: 'posts',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('title', nullable: false),
          SupabaseColumn.uuid('user_id', nullable: false),
        ],
        fromJson: Post.fromJson,
        toJson: (p) => p.toJson(),
        getId: (p) => p.id,
      );
    });

    group('withClient factory', () {
      test('creates manager with client and tables', () {
        final manager = SupabaseManager.withClient(
          client: mockClient,
          tables: [userConfig, postConfig],
        );

        expect(manager, isNotNull);
        expect(manager.tableNames, hasLength(2));
        expect(manager.isInitialized, isFalse);
      });
    });

    group('withTables factory', () {
      test('creates manager without client', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig],
        );

        expect(manager, isNotNull);
        expect(manager.tableNames, ['users']);
      });

      test('tableNames returns all configured table names', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig, postConfig],
        );

        expect(manager.tableNames, containsAll(['users', 'posts']));
        expect(manager.tableNames, hasLength(2));
      });
    });

    group('setClient', () {
      test('sets client before initialization', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig],
        );

        // Should not throw
        expect(() => manager.setClient(mockClient), returnsNormally);
      });
    });

    group('initialize', () {
      test('throws when no client provided', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig],
        );

        expect(
          manager.initialize,
          throwsStateError,
        );
      });
    });

    group('getBackend', () {
      test('throws when not initialized', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig],
        );

        expect(
          () => manager.getBackend('users'),
          throwsStateError,
        );
      });
    });

    group('properties', () {
      test('isInitialized is false before initialization', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig],
        );

        expect(manager.isInitialized, false);
      });

      test('hasRealtimeTables reflects config', () {
        final managerWithRealtime = SupabaseManager.withTables(
          tables: [
            SupabaseTableConfig<User, String>(
              tableName: 'users',
              columns: [SupabaseColumn.uuid('id', nullable: false)],
              fromJson: User.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
              enableRealtime: true,
            ),
          ],
        );

        expect(managerWithRealtime.hasRealtimeTables, true);

        final managerWithoutRealtime = SupabaseManager.withTables(
          tables: [userConfig],
        );

        expect(managerWithoutRealtime.hasRealtimeTables, false);
      });

      test('tables getter returns all configs', () {
        final manager = SupabaseManager.withTables(
          tables: [userConfig, postConfig],
        );

        expect(manager.tables, hasLength(2));
        expect(manager.tables.first.tableName, 'users');
        expect(manager.tables.last.tableName, 'posts');
      });
    });

    // Note: Tests that require manager.initialize() are covered by
    // integration tests since they need a real Supabase client
    // with realtime channel support. See test/supabase_backend_test.dart.
  });
}
