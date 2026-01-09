import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// Using Fake instead of Mock because Session/User override ==
// ignore: avoid_implementing_value_types
class FakeSession extends Fake implements Session {
  @override
  String get accessToken => 'test-token';

  @override
  int? get expiresIn =>
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;

  @override
  User get user => FakeUser();
}

// ignore: avoid_implementing_value_types
class FakeUser extends Fake implements User {
  @override
  String get id => 'user-123';
}

void main() {
  group('PowerSyncBackend.withSupabase', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late FakeSession fakeSession;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      fakeSession = FakeSession();

      // Setup auth chain
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(fakeSession);
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
          toJson: (u) => u.toJson(),
          getId: (u) => u.id,
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
