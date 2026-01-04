import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_client_wrapper.dart';
import 'package:test/test.dart';

/// Mock implementation of SupabaseClientWrapper for testing.
class MockSupabaseClientWrapper extends Mock implements SupabaseClientWrapper {}

void main() {
  group('SupabaseClientWrapper', () {
    group('interface contract', () {
      test('get returns a single record by id', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.get('users', 'id', '123'))
            .thenAnswer((_) async => {'id': '123', 'name': 'Alice'});

        final result = await mockWrapper.get('users', 'id', '123');

        expect(result, isNotNull);
        expect(result!['id'], '123');
        expect(result['name'], 'Alice');
      });

      test('get returns null when record not found', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.get('users', 'id', 'missing'))
            .thenAnswer((_) async => null);

        final result = await mockWrapper.get('users', 'id', 'missing');

        expect(result, isNull);
      });

      test('getAll returns list of records', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.getAll('users')).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice'},
            {'id': '2', 'name': 'Bob'},
          ],
        );

        final result = await mockWrapper.getAll('users');

        expect(result, hasLength(2));
        expect(result[0]['name'], 'Alice');
        expect(result[1]['name'], 'Bob');
      });

      test('getAll returns empty list when no records', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.getAll('users'))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        final result = await mockWrapper.getAll('users');

        expect(result, isEmpty);
      });

      test('upsert creates or updates a record', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.upsert('users', {'id': '1', 'name': 'Alice'}))
            .thenAnswer((_) async => {'id': '1', 'name': 'Alice'});

        final result =
            await mockWrapper.upsert('users', {'id': '1', 'name': 'Alice'});

        expect(result['id'], '1');
        expect(result['name'], 'Alice');
      });

      test('upsertAll creates or updates multiple records', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(
          () => mockWrapper.upsertAll('users', [
            {'id': '1', 'name': 'Alice'},
            {'id': '2', 'name': 'Bob'},
          ]),
        ).thenAnswer(
          (_) async => [
            {'id': '1', 'name': 'Alice'},
            {'id': '2', 'name': 'Bob'},
          ],
        );

        final result = await mockWrapper.upsertAll('users', [
          {'id': '1', 'name': 'Alice'},
          {'id': '2', 'name': 'Bob'},
        ]);

        expect(result, hasLength(2));
      });

      test('delete removes a record by id', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.delete('users', 'id', '123'))
            .thenAnswer((_) async {});

        await mockWrapper.delete('users', 'id', '123');

        verify(() => mockWrapper.delete('users', 'id', '123')).called(1);
      });

      test('deleteByIds removes multiple records', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.deleteByIds('users', 'id', ['1', '2']))
            .thenAnswer((_) async {});

        await mockWrapper.deleteByIds('users', 'id', ['1', '2']);

        verify(() => mockWrapper.deleteByIds('users', 'id', ['1', '2']))
            .called(1);
      });
    });

    group('error handling', () {
      test('get throws on database error', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.get('users', 'id', '123'))
            .thenThrow(Exception('Database error'));

        expect(
          () => mockWrapper.get('users', 'id', '123'),
          throwsException,
        );
      });

      test('upsert throws on constraint violation', () async {
        final mockWrapper = MockSupabaseClientWrapper();

        when(() => mockWrapper.upsert('users', {'id': '1', 'name': 'Alice'}))
            .thenThrow(Exception('Unique constraint violation'));

        expect(
          () => mockWrapper.upsert('users', {'id': '1', 'name': 'Alice'}),
          throwsException,
        );
      });
    });
  });
}
