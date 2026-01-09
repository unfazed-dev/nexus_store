import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:powersync/powersync.dart';
import 'package:test/test.dart';

// Mock classes for the abstraction layer
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

class MockSupabaseDataProvider extends Mock implements SupabaseDataProvider {}

class MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}

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
    // Integration tests would go here with real Supabase client
    // For unit tests, we test the abstraction layer above
  });

  group('DefaultSupabaseDataProvider', () {
    // Integration tests would go here with real Supabase client
    // For unit tests, we test the abstraction layer above
  });
}

/// Helper to create CrudEntry for tests.
CrudEntry _createCrudEntry({
  required UpdateType op,
  required String table,
  required String id,
  Map<String, dynamic>? opData,
}) => CrudEntry(
    1, // clientId
    op,
    table,
    id,
    null, // transactionId
    opData,
  );
