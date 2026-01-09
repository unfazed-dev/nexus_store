import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  group('PowerSyncBackend.withSupabase', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late MockSession mockSession;
    late MockUser mockUser;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockSession = MockSession();
      mockUser = MockUser();

      // Setup auth chain
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.accessToken).thenReturn('test-token');
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockSession.expiresIn).thenReturn(3600);
    });

    group('factory construction', () {
      test('creates backend with required parameters', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [
            PSColumn.text('name'),
            PSColumn.text('email'),
          ],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        expect(backend, isA<PowerSyncBackend<TestUser, String>>());
        expect(backend.name, equals('powersync'));
      });

      test('accepts optional custom dbPath', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
          dbPath: '/custom/path/db.sqlite',
        );

        expect(backend, isNotNull);
      });

      test('uses default primary key column when not specified', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        expect(backend, isNotNull);
      });

      test('accepts custom primary key column', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
          primaryKeyColumn: 'user_id',
        );

        expect(backend, isNotNull);
      });

      test('accepts optional field mapping', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
          fieldMapping: {'userName': 'name'},
        );

        expect(backend, isNotNull);
      });
    });

    group('dispose()', () {
      test('dispose cleans up resources', () async {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        // dispose should not throw when called on uninitialized backend
        await expectLater(backend.dispose(), completes);
      });

      test('dispose is idempotent', () async {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        // Calling dispose multiple times should not throw
        await backend.dispose();
        await expectLater(backend.dispose(), completes);
      });
    });

    group('configuration storage', () {
      test('stores table name from factory', () {
        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'custom_users',
          columns: [PSColumn.text('name')],
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        expect(backend, isNotNull);
      });

      test('stores column definitions from factory', () {
        final columns = [
          PSColumn.text('name'),
          PSColumn.text('email'),
          PSColumn.integer('age'),
          PSColumn.real('balance'),
        ];

        final backend = PowerSyncBackend<TestUser, String>.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tableName: 'users',
          columns: columns,
          fromJson: TestUser.fromJson,
          toJson: (TestUser u) => u.toJson(),
          getId: (TestUser u) => u.id,
        );

        expect(backend, isNotNull);
      });
    });
  });
}

/// Test model for testing the backend.
class TestUser {
  TestUser({required this.id, required this.name, this.email, this.age});

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
        if (email != null) 'email': email,
        if (age != null) 'age': age,
      };
}
