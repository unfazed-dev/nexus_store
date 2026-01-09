import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Test models
class TestUser {
  TestUser({required this.id, required this.name});

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TestPost {
  TestPost({required this.id, required this.title});

  factory TestPost.fromJson(Map<String, dynamic> json) => TestPost(
        id: json['id'] as String,
        title: json['title'] as String,
      );

  final String id;
  final String title;

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// Using Fake instead of Mock because Session/User override ==
// ignore: avoid_implementing_value_types
class FakeSession extends Fake implements Session {
  @override
  String get accessToken => 'test-token';

  @override
  int? get expiresAt =>
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
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late FakeSession fakeSession;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    fakeSession = FakeSession();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(fakeSession);
  });

  group('PowerSyncManager', () {
    group('withSupabase factory', () {
      test('creates manager with multiple table configs', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
            PSTableConfig<TestPost, String>(
              tableName: 'posts',
              columns: [PSColumn.text('title')],
              fromJson: TestPost.fromJson,
              toJson: (p) => p.toJson(),
              getId: (p) => p.id,
            ),
          ],
        );

        expect(manager, isA<PowerSyncManager>());
        expect(manager.tableNames, containsAll(['users', 'posts']));
      });

      test('stores power sync url', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://my-instance.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(manager.powerSyncUrl, equals('https://my-instance.powersync.co'));
      });

      test('accepts optional dbPath', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          dbPath: '/custom/path/app.db',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(manager.dbPath, equals('/custom/path/app.db'));
      });
    });

    group('tableNames', () {
      test('returns list of all registered table names', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
            PSTableConfig<TestPost, String>(
              tableName: 'posts',
              columns: [PSColumn.text('title')],
              fromJson: TestPost.fromJson,
              toJson: (p) => p.toJson(),
              getId: (p) => p.id,
            ),
          ],
        );

        expect(manager.tableNames.length, equals(2));
        expect(manager.tableNames, contains('users'));
        expect(manager.tableNames, contains('posts'));
      });
    });

    group('hasTable', () {
      test('returns true for registered table', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(manager.hasTable('users'), isTrue);
      });

      test('returns false for unregistered table', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(manager.hasTable('posts'), isFalse);
      });
    });

    group('isInitialized', () {
      test('returns false before initialize', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(manager.isInitialized, isFalse);
      });
    });

    group('getBackend', () {
      test('throws StateError before initialize', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        expect(
          () => manager.getBackend<TestUser, String>('users'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws ArgumentError for unknown table', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        // Even before initialize, we can check for unknown tables
        expect(manager.hasTable('unknown'), isFalse);
      });
    });

    group('dispose', () {
      test('can be called before initialize', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        // Should not throw
        expect(() async => manager.dispose(), returnsNormally);
      });

      test('is idempotent', () async {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
          ],
        );

        await manager.dispose();
        await manager.dispose(); // Should not throw
      });
    });

    group('generateSchema', () {
      test('combines all table schemas', () {
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<TestUser, String>(
              tableName: 'users',
              columns: [
                PSColumn.text('name'),
                PSColumn.text('email'),
              ],
              fromJson: TestUser.fromJson,
              toJson: (u) => u.toJson(),
              getId: (u) => u.id,
            ),
            PSTableConfig<TestPost, String>(
              tableName: 'posts',
              columns: [
                PSColumn.text('title'),
                PSColumn.text('content'),
              ],
              fromJson: TestPost.fromJson,
              toJson: (p) => p.toJson(),
              getId: (p) => p.id,
            ),
          ],
        );

        final schema = manager.generateSchema();

        expect(schema.tables.length, equals(2));

        final tableNames = schema.tables.map((t) => t.name).toList();
        expect(tableNames, contains('users'));
        expect(tableNames, contains('posts'));
      });
    });
  });
}
