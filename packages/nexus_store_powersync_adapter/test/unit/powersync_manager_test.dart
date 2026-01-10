import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
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

class MockPowerSyncDatabaseAdapter extends Mock
    implements PowerSyncDatabaseAdapter {}

class MockPowerSyncDatabaseWrapper extends Mock
    implements PowerSyncDatabaseWrapper {}

class MockSupabasePowerSyncConnector extends Mock
    implements SupabasePowerSyncConnector {}

class MockPowerSyncBackend extends Mock
    implements PowerSyncBackend<dynamic, dynamic> {}

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

class FakeSupabasePowerSyncConnector extends Fake
    implements SupabasePowerSyncConnector {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSupabasePowerSyncConnector());
  });
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late FakeSession fakeSession;
  late MockPowerSyncDatabaseAdapter mockAdapter;
  late MockPowerSyncDatabaseWrapper mockWrapper;
  late MockSupabasePowerSyncConnector mockConnector;
  late MockPowerSyncBackend mockBackend;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    fakeSession = FakeSession();
    mockAdapter = MockPowerSyncDatabaseAdapter();
    mockWrapper = MockPowerSyncDatabaseWrapper();
    mockConnector = MockSupabasePowerSyncConnector();
    mockBackend = MockPowerSyncBackend();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(fakeSession);

    // Default adapter mock setup
    when(() => mockAdapter.initialize()).thenAnswer((_) async {});
    when(() => mockAdapter.connect(any())).thenAnswer((_) async {});
    when(() => mockAdapter.disconnect()).thenAnswer((_) async {});
    when(() => mockAdapter.close()).thenAnswer((_) async {});
    when(() => mockAdapter.wrapper).thenReturn(mockWrapper);
    when(() => mockAdapter.isInitialized).thenReturn(true);

    // Default wrapper mock setup for statusStream and currentStatus
    // ignore: invalid_use_of_internal_member
    const syncStatus = ps.SyncStatus(connected: true, hasSynced: true);
    when(() => mockWrapper.statusStream)
        .thenAnswer((_) => Stream.value(syncStatus));
    when(() => mockWrapper.currentStatus).thenReturn(syncStatus);

    // Default backend mock setup
    when(() => mockBackend.initialize()).thenAnswer((_) async {});
    when(() => mockBackend.close()).thenAnswer((_) async {});
  });

  // Helper to create a manager with mocks
  // Note: We use PSTableConfig<dynamic, dynamic> to avoid type issues
  // when the functions are passed through the factory
  PowerSyncManager createMockedManager({
    List<PSTableConfig<dynamic, dynamic>>? tables,
    String? dbPath,
  }) =>
      PowerSyncManager.withSupabase(
        supabase: mockSupabase,
        powerSyncUrl: 'https://test.powersync.co',
        tables: tables ??
            [
              PSTableConfig<dynamic, dynamic>(
                tableName: 'users',
                columns: [PSColumn.text('name')],
                fromJson: TestUser.fromJson,
                toJson: (u) => (u as TestUser).toJson(),
                getId: (u) => (u as TestUser).id,
              ),
            ],
        dbPath: dbPath,
        databaseAdapterFactory: (schema, path) => mockAdapter,
        connectorFactory: (supabase, url) => mockConnector,
        backendFactory: ({
          required adapter,
          required tableName,
          required fromJson,
          required toJson,
          required getId,
          required primaryKeyColumn,
          required fieldMapping,
        }) =>
            mockBackend,
      );

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

        expect(
          manager.powerSyncUrl,
          equals('https://my-instance.powersync.co'),
        );
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

      test('accepts custom factories for testing', () {
        final manager = createMockedManager();

        expect(manager, isA<PowerSyncManager>());
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
        final manager = createMockedManager();

        expect(manager.isInitialized, isFalse);
      });

      test('returns true after initialize', () async {
        final manager = createMockedManager();

        await manager.initialize();

        expect(manager.isInitialized, isTrue);
      });
    });

    group('initialize', () {
      test('creates adapter, connects, and sets up backends', () async {
        final manager = createMockedManager();

        await manager.initialize();

        verify(() => mockAdapter.initialize()).called(1);
        verify(() => mockAdapter.connect(mockConnector)).called(1);
        verify(() => mockBackend.initialize()).called(1);
        expect(manager.isInitialized, isTrue);
      });

      test('is idempotent - second call does nothing', () async {
        final manager = createMockedManager();

        await manager.initialize();
        await manager.initialize();

        verify(() => mockAdapter.initialize()).called(1);
      });

      test('creates backends for all tables', () async {
        final manager = createMockedManager(
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
            PSTableConfig<dynamic, dynamic>(
              tableName: 'posts',
              columns: [PSColumn.text('title')],
              fromJson: TestPost.fromJson,
              toJson: (p) => (p as TestPost).toJson(),
              getId: (p) => (p as TestPost).id,
            ),
          ],
        );

        await manager.initialize();

        // Backend initialize called once per table
        verify(() => mockBackend.initialize()).called(2);
      });

      test('uses provided dbPath', () async {
        var capturedPath = '';
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          dbPath: '/custom/database.db',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) {
            capturedPath = path;
            return mockAdapter;
          },
          connectorFactory: (supabase, url) => mockConnector,
          backendFactory: ({
            required adapter,
            required tableName,
            required fromJson,
            required toJson,
            required getId,
            required primaryKeyColumn,
            required fieldMapping,
          }) =>
              mockBackend,
        );

        await manager.initialize();

        expect(capturedPath, equals('/custom/database.db'));
      });

      test('generates default dbPath when not provided', () async {
        var capturedPath = '';
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) {
            capturedPath = path;
            return mockAdapter;
          },
          connectorFactory: (supabase, url) => mockConnector,
          backendFactory: ({
            required adapter,
            required tableName,
            required fromJson,
            required toJson,
            required getId,
            required primaryKeyColumn,
            required fieldMapping,
          }) =>
              mockBackend,
        );

        await manager.initialize();

        expect(capturedPath, startsWith('powersync_'));
        expect(capturedPath, endsWith('.db'));
      });

      test('throws StateError when already disposed', () async {
        final manager = createMockedManager();

        await manager.dispose();

        expect(
          manager.initialize,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('disposed'),
            ),
          ),
        );
      });

      test('passes connector to adapter.connect', () async {
        final manager = createMockedManager();

        await manager.initialize();

        verify(() => mockAdapter.connect(mockConnector)).called(1);
      });
    });

    group('getBackend', () {
      test('throws StateError before initialize', () {
        final manager = createMockedManager();

        expect(
          () => manager.getBackend<TestUser, String>('users'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns backend after initialize', () async {
        final manager = createMockedManager();

        await manager.initialize();

        // Use dynamic types since the mock returns
        // PowerSyncBackend<dynamic, dynamic>
        final backend = manager.getBackend<dynamic, dynamic>('users');

        expect(backend, isA<PowerSyncBackend<dynamic, dynamic>>());
      });

      test('throws ArgumentError for unregistered table', () async {
        final manager = createMockedManager();

        await manager.initialize();

        expect(
          () => manager.getBackend<TestPost, String>('posts'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('posts'),
            ),
          ),
        );
      });

      test('returns different backends for different tables', () async {
        var backendCount = 0;
        final backends = <String, MockPowerSyncBackend>{};

        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
            PSTableConfig<dynamic, dynamic>(
              tableName: 'posts',
              columns: [PSColumn.text('title')],
              fromJson: TestPost.fromJson,
              toJson: (p) => (p as TestPost).toJson(),
              getId: (p) => (p as TestPost).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) => mockAdapter,
          connectorFactory: (supabase, url) => mockConnector,
          backendFactory: ({
            required adapter,
            required tableName,
            required fromJson,
            required toJson,
            required getId,
            required primaryKeyColumn,
            required fieldMapping,
          }) {
            backendCount++;
            final backend = MockPowerSyncBackend();
            when(backend.initialize).thenAnswer((_) async {});
            when(backend.close).thenAnswer((_) async {});
            backends[tableName] = backend;
            return backend;
          },
        );

        await manager.initialize();

        final userBackend = manager.getBackend<dynamic, dynamic>('users');
        final postBackend = manager.getBackend<dynamic, dynamic>('posts');

        expect(backendCount, equals(2));
        expect(userBackend, equals(backends['users']));
        expect(postBackend, equals(backends['posts']));
      });
    });

    group('dispose', () {
      test('can be called before initialize', () async {
        final manager = createMockedManager();

        await manager.dispose();

        // Should not throw and not call adapter methods
        verifyNever(() => mockAdapter.disconnect());
        verifyNever(() => mockAdapter.close());
      });

      test('is idempotent', () async {
        final manager = createMockedManager();

        await manager.dispose();
        await manager.dispose();

        // No exceptions should be thrown
      });

      test('closes all backends', () async {
        final manager = createMockedManager(
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
            PSTableConfig<dynamic, dynamic>(
              tableName: 'posts',
              columns: [PSColumn.text('title')],
              fromJson: TestPost.fromJson,
              toJson: (p) => (p as TestPost).toJson(),
              getId: (p) => (p as TestPost).id,
            ),
          ],
        );

        await manager.initialize();
        await manager.dispose();

        // Backend close called once per table
        verify(() => mockBackend.close()).called(2);
      });

      test('disconnects and closes adapter', () async {
        final manager = createMockedManager();

        await manager.initialize();
        await manager.dispose();

        verify(() => mockAdapter.disconnect()).called(1);
        verify(() => mockAdapter.close()).called(1);
      });

      test('sets isInitialized to false', () async {
        final manager = createMockedManager();

        await manager.initialize();
        expect(manager.isInitialized, isTrue);

        await manager.dispose();
        expect(manager.isInitialized, isFalse);
      });

      test('prevents subsequent initialize calls', () async {
        final manager = createMockedManager();

        await manager.initialize();
        await manager.dispose();

        expect(
          manager.initialize,
          throwsA(isA<StateError>()),
        );
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

    group('default factories', () {
      test('uses default adapter factory when none provided', () async {
        // Create manager without custom factories - uses defaults
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
        );

        // Initialize will fail due to missing PowerSync extension,
        // but this exercises the default factory code paths
        expect(
          manager.initialize,
          throwsA(anything), // SqliteException or similar
        );
      });

      test('uses default connector factory when adapter provided', () async {
        // Provide adapter but not connector - uses default connector factory
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) => mockAdapter,
          // No connectorFactory - uses default
        );

        await manager.initialize();

        // Verify adapter was initialized and connected
        verify(() => mockAdapter.initialize()).called(1);
        verify(() => mockAdapter.connect(any())).called(1);
      });

      test('uses default backend factory when adapter and connector provided',
          () async {
        // Provide adapter and connector but not backend factory
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) => mockAdapter,
          connectorFactory: (supabase, url) => mockConnector,
          // No backendFactory - uses default
        );

        // This will call the default backend factory
        // It creates PowerSyncBackend.withWrapper using adapter.wrapper
        await manager.initialize();

        verify(() => mockAdapter.wrapper).called(greaterThan(0));
      });

      test('default backend factory closures execute correctly', () async {
        // Mock wrapper.execute for database operations
        when(() => mockWrapper.execute(any(), any()))
            .thenAnswer((_) async => []);

        // Provide adapter and connector but not backend factory
        final manager = PowerSyncManager.withSupabase(
          supabase: mockSupabase,
          powerSyncUrl: 'https://test.powersync.co',
          tables: [
            PSTableConfig<dynamic, dynamic>(
              tableName: 'users',
              columns: [PSColumn.text('name')],
              fromJson: TestUser.fromJson,
              toJson: (u) => (u as TestUser).toJson(),
              getId: (u) => (u as TestUser).id,
            ),
          ],
          databaseAdapterFactory: (schema, path) => mockAdapter,
          connectorFactory: (supabase, url) => mockConnector,
          // No backendFactory - uses default factory with closures
        );

        await manager.initialize();

        // Get the real backend created by default factory
        final backend = manager.getBackend<dynamic, dynamic>('users');

        // Test that fromJson, toJson, getId closures work
        // by exercising the backend operations

        // Test get (uses fromJson)
        when(() => mockWrapper.execute(any(), any())).thenAnswer(
          (_) async => [
            {'id': 'user-1', 'name': 'Test User'},
          ],
        );
        final user = await backend.get('user-1');
        expect(user, isA<TestUser>());
        expect((user as TestUser).id, equals('user-1'));

        // Test save (uses toJson and getId)
        when(() => mockWrapper.execute(any(), any()))
            .thenAnswer((_) async => []);
        final testUser = TestUser(id: 'user-2', name: 'New User');
        final savedUser = await backend.save(testUser);
        expect(savedUser, isA<TestUser>());
      });
    });
  });
}
