import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

// Mock classes for the abstraction layer
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

class MockSupabaseDataProvider extends Mock implements SupabaseDataProvider {}

class MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}

// Mocks for Supabase client
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// Using Fake instead of Mock because Session/User override ==
// ignore: avoid_implementing_value_types
class FakeSession extends Fake implements Session {
  FakeSession({this.tokenValue = 'test-token', this.expiresInValue = 3600});

  final String tokenValue;
  final int? expiresInValue;

  @override
  String get accessToken => tokenValue;

  @override
  int? get expiresIn => expiresInValue;

  @override
  User get user => FakeUser();
}

// ignore: avoid_implementing_value_types
class FakeUser extends Fake implements User {
  @override
  String get id => 'user-123';
}

void main() {
  group('SupabasePowerSyncConnector', () {
    late MockSupabaseAuthProvider mockAuthProvider;
    late MockSupabaseDataProvider mockDataProvider;
    late SupabasePowerSyncConnector connector;

    const testPowerSyncUrl = 'https://test.powersync.co';

    setUp(() {
      mockAuthProvider = MockSupabaseAuthProvider();
      mockDataProvider = MockSupabaseDataProvider();

      connector = SupabasePowerSyncConnector(
        authProvider: mockAuthProvider,
        dataProvider: mockDataProvider,
        powerSyncUrl: testPowerSyncUrl,
      );
    });

    group('fetchCredentials', () {
      test('returns credentials when user is authenticated', () async {
        when(() => mockAuthProvider.getAccessToken())
            .thenAnswer((_) async => 'test-access-token');
        when(() => mockAuthProvider.getUserId())
            .thenAnswer((_) async => 'user-123');
        when(() => mockAuthProvider.getTokenExpiresAt()).thenAnswer(
          (_) async => DateTime.now().add(const Duration(hours: 1)),
        );

        final credentials = await connector.fetchCredentials();

        expect(credentials, isNotNull);
        expect(credentials!.endpoint, equals(testPowerSyncUrl));
        expect(credentials.token, equals('test-access-token'));
        expect(credentials.userId, equals('user-123'));
      });

      test('returns null when user is not authenticated', () async {
        when(() => mockAuthProvider.getAccessToken())
            .thenAnswer((_) async => null);

        final credentials = await connector.fetchCredentials();

        expect(credentials, isNull);
      });

      test('includes expiration time when available', () async {
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        when(() => mockAuthProvider.getAccessToken())
            .thenAnswer((_) async => 'test-token');
        when(() => mockAuthProvider.getUserId())
            .thenAnswer((_) async => 'user-456');
        when(() => mockAuthProvider.getTokenExpiresAt())
            .thenAnswer((_) async => expiresAt);

        final credentials = await connector.fetchCredentials();

        expect(credentials, isNotNull);
        expect(credentials!.expiresAt, isNotNull);
        expect(
          credentials.expiresAt!.difference(expiresAt).inSeconds.abs(),
          lessThan(2),
        );
      });
    });

    group('uploadData', () {
      late MockPowerSyncDatabase mockDatabase;
      late bool completeCalled;

      setUp(() {
        mockDatabase = MockPowerSyncDatabase();
        completeCalled = false;
      });

      CrudTransaction createTransaction(List<CrudEntry> entries) =>
          CrudTransaction(
            crud: entries,
            transactionId: 1,
            complete: ({writeCheckpoint}) async {
              completeCalled = true;
            },
          );

      test('returns early when no pending transactions', () async {
        when(() => mockDatabase.getNextCrudTransaction())
            .thenAnswer((_) async => null);

        await connector.uploadData(mockDatabase);

        verify(() => mockDatabase.getNextCrudTransaction()).called(1);
        verifyNever(() => mockDataProvider.upsert(any(), any()));
      });

      test('processes PUT operations as upserts', () async {
        final crudEntry = _createCrudEntry(
          op: UpdateType.put,
          table: 'items',
          id: 'item-1',
          opData: {'name': 'Test Item'},
        );

        when(() => mockDatabase.getNextCrudTransaction())
            .thenAnswer((_) async => createTransaction([crudEntry]));
        when(() => mockDataProvider.upsert('items', any()))
            .thenAnswer((_) async {});

        await connector.uploadData(mockDatabase);

        verify(
          () => mockDataProvider.upsert(
            'items',
            {'id': 'item-1', 'name': 'Test Item'},
          ),
        ).called(1);
        expect(completeCalled, isTrue);
      });

      test('processes PATCH operations as updates', () async {
        final crudEntry = _createCrudEntry(
          op: UpdateType.patch,
          table: 'items',
          id: 'item-2',
          opData: {'name': 'Updated Item'},
        );

        when(() => mockDatabase.getNextCrudTransaction())
            .thenAnswer((_) async => createTransaction([crudEntry]));
        when(() => mockDataProvider.update('items', 'item-2', any()))
            .thenAnswer((_) async {});

        await connector.uploadData(mockDatabase);

        verify(
          () => mockDataProvider.update(
            'items',
            'item-2',
            {'name': 'Updated Item'},
          ),
        ).called(1);
        expect(completeCalled, isTrue);
      });

      test('processes DELETE operations', () async {
        final crudEntry = _createCrudEntry(
          op: UpdateType.delete,
          table: 'items',
          id: 'item-3',
        );

        when(() => mockDatabase.getNextCrudTransaction())
            .thenAnswer((_) async => createTransaction([crudEntry]));
        when(() => mockDataProvider.delete('items', 'item-3'))
            .thenAnswer((_) async {});

        await connector.uploadData(mockDatabase);

        verify(() => mockDataProvider.delete('items', 'item-3')).called(1);
        expect(completeCalled, isTrue);
      });

      test('processes multiple operations in sequence', () async {
        final entries = [
          _createCrudEntry(
            op: UpdateType.put,
            table: 'items',
            id: 'item-1',
            opData: {'name': 'Item 1'},
          ),
          _createCrudEntry(
            op: UpdateType.patch,
            table: 'items',
            id: 'item-2',
            opData: {'name': 'Item 2'},
          ),
          _createCrudEntry(
            op: UpdateType.delete,
            table: 'items',
            id: 'item-3',
          ),
        ];

        when(() => mockDatabase.getNextCrudTransaction())
            .thenAnswer((_) async => createTransaction(entries));
        when(() => mockDataProvider.upsert(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockDataProvider.update(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => mockDataProvider.delete(any(), any()))
            .thenAnswer((_) async {});

        await connector.uploadData(mockDatabase);

        verify(() => mockDataProvider.upsert('items', any())).called(1);
        verify(() => mockDataProvider.update('items', 'item-2', any()))
            .called(1);
        verify(() => mockDataProvider.delete('items', 'item-3')).called(1);
        expect(completeCalled, isTrue);
      });
    });
  });

  group('DefaultSupabaseAuthProvider', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late DefaultSupabaseAuthProvider provider;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
      provider = DefaultSupabaseAuthProvider(mockClient);
    });

    test('getAccessToken returns token when session exists', () async {
      final session = FakeSession(tokenValue: 'my-access-token');
      when(() => mockAuth.currentSession).thenReturn(session);

      final token = await provider.getAccessToken();

      expect(token, equals('my-access-token'));
    });

    test('getAccessToken returns null when no session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final token = await provider.getAccessToken();

      expect(token, isNull);
    });

    test('getUserId returns user id when session exists', () async {
      final session = FakeSession();
      when(() => mockAuth.currentSession).thenReturn(session);

      final userId = await provider.getUserId();

      expect(userId, equals('user-123'));
    });

    test('getUserId returns null when no session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final userId = await provider.getUserId();

      expect(userId, isNull);
    });

    test('getTokenExpiresAt returns expiration when session has expiresIn',
        () async {
      final session = FakeSession();
      when(() => mockAuth.currentSession).thenReturn(session);

      final expiresAt = await provider.getTokenExpiresAt();

      expect(expiresAt, isNotNull);
      // Should be roughly 1 hour from now
      expect(
        expiresAt!.difference(DateTime.now()).inMinutes,
        closeTo(60, 1),
      );
    });

    test('getTokenExpiresAt returns null when no expiresIn', () async {
      final session = FakeSession(expiresInValue: null);
      when(() => mockAuth.currentSession).thenReturn(session);

      final expiresAt = await provider.getTokenExpiresAt();

      expect(expiresAt, isNull);
    });

    test('getTokenExpiresAt returns null when no session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final expiresAt = await provider.getTokenExpiresAt();

      expect(expiresAt, isNull);
    });
  });

  group('DefaultSupabaseDataProvider', () {
    // The DefaultSupabaseDataProvider methods (upsert, update, delete) delegate
    // directly to SupabaseClient's REST API. Testing these requires either:
    // 1. Complex mock setup for the chained Supabase API
    // 2. Integration tests with a real Supabase backend
    //
    // The class is a thin wrapper that's tested via integration tests.
    // Coverage for these methods will be captured by integration tests
    // that use real Supabase credentials.

    test('can be instantiated with SupabaseClient', () {
      final mockClient = MockSupabaseClient();

      final provider = DefaultSupabaseDataProvider(mockClient);

      expect(provider, isA<DefaultSupabaseDataProvider>());
      expect(provider, isA<SupabaseDataProvider>());
    });
  });

  group('SupabasePowerSyncConnector.withClient', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
    });

    test('creates connector with default providers', () {
      final connector = SupabasePowerSyncConnector.withClient(
        supabase: mockClient,
        powerSyncUrl: 'https://test.powersync.co',
      );

      expect(connector, isA<SupabasePowerSyncConnector>());
    });

    test('fetchCredentials works with withClient factory', () async {
      final session = FakeSession(tokenValue: 'factory-token');
      when(() => mockAuth.currentSession).thenReturn(session);

      final connector = SupabasePowerSyncConnector.withClient(
        supabase: mockClient,
        powerSyncUrl: 'https://test.powersync.co',
      );

      final credentials = await connector.fetchCredentials();

      expect(credentials, isNotNull);
      expect(credentials!.token, equals('factory-token'));
    });
  });

  group('SupabasePowerSyncConnector error handling', () {
    late MockSupabaseAuthProvider mockAuthProvider;
    late MockSupabaseDataProvider mockDataProvider;
    late MockPowerSyncDatabase mockDatabase;
    late SupabasePowerSyncConnector connector;
    late bool completeCalled;

    setUp(() {
      mockAuthProvider = MockSupabaseAuthProvider();
      mockDataProvider = MockSupabaseDataProvider();
      mockDatabase = MockPowerSyncDatabase();
      completeCalled = false;

      connector = SupabasePowerSyncConnector(
        authProvider: mockAuthProvider,
        dataProvider: mockDataProvider,
        powerSyncUrl: 'https://test.powersync.co',
      );
    });

    CrudTransaction createTransaction(List<CrudEntry> entries) =>
        CrudTransaction(
          crud: entries,
          transactionId: 1,
          complete: ({writeCheckpoint}) async {
            completeCalled = true;
          },
        );

    test('fatal PostgrestException (4xx) completes transaction and rethrows',
        () async {
      final crudEntry = _createCrudEntry(
        op: UpdateType.put,
        table: 'items',
        id: 'item-1',
        opData: {'name': 'Test'},
      );

      when(() => mockDatabase.getNextCrudTransaction())
          .thenAnswer((_) async => createTransaction([crudEntry]));
      when(() => mockDataProvider.upsert('items', any())).thenThrow(
        const PostgrestException(code: '400', message: 'Bad Request'),
      );

      await expectLater(
        () => connector.uploadData(mockDatabase),
        throwsA(isA<PostgrestException>()),
      );

      expect(completeCalled, isTrue);
    });

    test('non-fatal PostgrestException (429) does not complete transaction',
        () async {
      final crudEntry = _createCrudEntry(
        op: UpdateType.put,
        table: 'items',
        id: 'item-1',
        opData: {'name': 'Test'},
      );

      when(() => mockDatabase.getNextCrudTransaction())
          .thenAnswer((_) async => createTransaction([crudEntry]));
      when(() => mockDataProvider.upsert('items', any())).thenThrow(
        const PostgrestException(code: '429', message: 'Rate Limited'),
      );

      await expectLater(
        () => connector.uploadData(mockDatabase),
        throwsA(isA<PostgrestException>()),
      );

      expect(completeCalled, isFalse);
    });

    test('PostgrestException with null code does not complete transaction',
        () async {
      final crudEntry = _createCrudEntry(
        op: UpdateType.put,
        table: 'items',
        id: 'item-1',
        opData: {'name': 'Test'},
      );

      when(() => mockDatabase.getNextCrudTransaction())
          .thenAnswer((_) async => createTransaction([crudEntry]));
      when(() => mockDataProvider.upsert('items', any())).thenThrow(
        const PostgrestException(message: 'Unknown error'),
      );

      await expectLater(
        () => connector.uploadData(mockDatabase),
        throwsA(isA<PostgrestException>()),
      );

      expect(completeCalled, isFalse);
    });

    test('PostgrestException with non-numeric code does not complete',
        () async {
      final crudEntry = _createCrudEntry(
        op: UpdateType.put,
        table: 'items',
        id: 'item-1',
        opData: {'name': 'Test'},
      );

      when(() => mockDatabase.getNextCrudTransaction())
          .thenAnswer((_) async => createTransaction([crudEntry]));
      when(() => mockDataProvider.upsert('items', any())).thenThrow(
        const PostgrestException(code: 'PGRST001', message: 'Postgres error'),
      );

      await expectLater(
        () => connector.uploadData(mockDatabase),
        throwsA(isA<PostgrestException>()),
      );

      expect(completeCalled, isFalse);
    });

    test('5xx errors do not complete transaction (allows retry)', () async {
      final crudEntry = _createCrudEntry(
        op: UpdateType.put,
        table: 'items',
        id: 'item-1',
        opData: {'name': 'Test'},
      );

      when(() => mockDatabase.getNextCrudTransaction())
          .thenAnswer((_) async => createTransaction([crudEntry]));
      when(() => mockDataProvider.upsert('items', any())).thenThrow(
        const PostgrestException(code: '500', message: 'Server Error'),
      );

      await expectLater(
        () => connector.uploadData(mockDatabase),
        throwsA(isA<PostgrestException>()),
      );

      expect(completeCalled, isFalse);
    });
  });
}

/// Helper to create CrudEntry for tests.
CrudEntry _createCrudEntry({
  required UpdateType op,
  required String table,
  required String id,
  Map<String, dynamic>? opData,
}) =>
    CrudEntry(
      1, // clientId
      op,
      table,
      id,
      null, // transactionId
      opData,
    );
