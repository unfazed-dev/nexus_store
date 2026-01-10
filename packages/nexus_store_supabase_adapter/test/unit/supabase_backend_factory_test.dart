import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_backend.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_column.dart';
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

void main() {
  group('SupabaseBackend.withConfig', () {
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    test('creates backend from table config with default options', () {
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

      final backend = SupabaseBackend<User, String>.withConfig(
        client: mockClient,
        config: config,
      );

      expect(backend, isNotNull);
      expect(backend.name, 'supabase');
      expect(backend.supportsRealtime, isTrue);
      expect(backend.supportsOffline, isFalse);
    });

    test('creates backend from config with custom schema', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('id', nullable: false),
          SupabaseColumn.text('name', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        schema: 'auth',
      );

      final backend = SupabaseBackend<User, String>.withConfig(
        client: mockClient,
        config: config,
      );

      expect(backend, isNotNull);
    });

    test('creates backend from config with custom primary key', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('user_id', nullable: false),
          SupabaseColumn.text('name', nullable: false),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        primaryKeyColumn: 'user_id',
      );

      final backend = SupabaseBackend<User, String>.withConfig(
        client: mockClient,
        config: config,
      );

      expect(backend, isNotNull);
    });

    test('creates backend from config with field mapping', () {
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

      final backend = SupabaseBackend<User, String>.withConfig(
        client: mockClient,
        config: config,
      );

      expect(backend, isNotNull);
    });

    test('creates backend from config with all options', () {
      final config = SupabaseTableConfig<User, String>(
        tableName: 'users',
        columns: [
          SupabaseColumn.uuid('user_id', nullable: false),
          SupabaseColumn.text('full_name', nullable: false),
          SupabaseColumn.text('email_address'),
        ],
        fromJson: User.fromJson,
        toJson: (u) => u.toJson(),
        getId: (u) => u.id,
        primaryKeyColumn: 'user_id',
        schema: 'auth',
        enableRealtime: true,
        fieldMapping: {'name': 'full_name', 'email': 'email_address'},
      );

      final backend = SupabaseBackend<User, String>.withConfig(
        client: mockClient,
        config: config,
      );

      expect(backend, isNotNull);
      expect(backend.name, 'supabase');
    });
  });
}
