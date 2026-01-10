/// Integration tests for DefaultSupabaseDataProvider with real Supabase.
///
/// These tests exercise the Supabase REST API methods:
/// - upsert()
/// - update()
/// - delete()
///
/// ## Requirements
/// - Active Supabase project with `test_items` table
/// - Valid credentials in test_config.dart
///
/// ## Running Tests
/// ```bash
/// dart test test/integration/supabase_data_provider_test.dart --tags=integration
/// ```
@Tags(['integration', 'supabase'])
@Timeout(Duration(minutes: 2))
library;

import 'package:nexus_store_powersync_adapter/src/supabase_connector.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../test_config.dart';
import 'test_item_model.dart';

void main() {
  group('DefaultSupabaseDataProvider Integration Tests', () {
    late SupabaseClient supabase;
    late DefaultSupabaseDataProvider provider;
    final createdIds = <String>[];

    setUpAll(() async {
      supabase = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
      provider = DefaultSupabaseDataProvider(supabase);
    });

    tearDown(() async {
      // Clean up any test records created during tests
      for (final id in createdIds) {
        try {
          await supabase.rest.from('test_items').delete().eq('id', id);
        } on PostgrestException catch (_) {
          // Ignore errors during cleanup
        }
      }
      createdIds.clear();
    });

    tearDownAll(() {
      supabase.dispose();
    });

    group('upsert()', () {
      test('inserts new record', () async {
        final id = generateTestId('upsert_insert');
        createdIds.add(id);

        final data = {'id': id, 'name': 'Test Insert', 'value': 42};

        await provider.upsert('test_items', data);

        // Verify the record was inserted
        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, hasLength(1));
        expect(result.first['name'], equals('Test Insert'));
        expect(result.first['value'], equals(42));
      });

      test('updates existing record (upsert behavior)', () async {
        final id = generateTestId('upsert_update');
        createdIds.add(id);

        // Insert initial record
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'Original', 'value': 1},
        );

        // Upsert with same ID but different values
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'Updated', 'value': 2},
        );

        // Verify the record was updated
        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, hasLength(1));
        expect(result.first['name'], equals('Updated'));
        expect(result.first['value'], equals(2));
      });

      test('handles null values', () async {
        final id = generateTestId('upsert_null');
        createdIds.add(id);

        final data = {'id': id, 'name': 'Null Value Test', 'value': null};

        await provider.upsert('test_items', data);

        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, hasLength(1));
        expect(result.first['value'], isNull);
      });
    });

    group('update()', () {
      test('updates specific fields by ID', () async {
        final id = generateTestId('update_fields');
        createdIds.add(id);

        // Insert initial record
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'Original Name', 'value': 100},
        );

        // Update only the name field
        await provider.update('test_items', id, {'name': 'New Name'});

        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, hasLength(1));
        expect(result.first['name'], equals('New Name'));
        // Value should remain unchanged
        expect(result.first['value'], equals(100));
      });

      test('updates multiple fields', () async {
        final id = generateTestId('update_multi');
        createdIds.add(id);

        // Insert initial record
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'Initial', 'value': 10},
        );

        // Update both name and value
        await provider.update(
          'test_items',
          id,
          {'name': 'Multi Update', 'value': 20},
        );

        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, hasLength(1));
        expect(result.first['name'], equals('Multi Update'));
        expect(result.first['value'], equals(20));
      });

      test('no-op for non-existent ID', () async {
        final id = generateTestId('update_nonexistent');
        // Note: Don't add to createdIds since it won't exist

        // This should not throw - Supabase returns empty result
        await provider.update('test_items', id, {'name': 'Should Not Exist'});

        // Verify nothing was created
        final result =
            await supabase.rest.from('test_items').select().eq('id', id);

        expect(result, isEmpty);
      });
    });

    group('delete()', () {
      test('removes existing record', () async {
        final id = generateTestId('delete_existing');
        // Don't add to createdIds since we're deleting it

        // Insert a record to delete
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'To Delete', 'value': 999},
        );

        // Verify it exists
        var result =
            await supabase.rest.from('test_items').select().eq('id', id);
        expect(result, hasLength(1));

        // Delete the record
        await provider.delete('test_items', id);

        // Verify it's gone
        result = await supabase.rest.from('test_items').select().eq('id', id);
        expect(result, isEmpty);
      });

      test('no-op for non-existent ID', () async {
        final id = generateTestId('delete_nonexistent');

        // This should not throw
        await provider.delete('test_items', id);

        // Verify nothing exists
        final result =
            await supabase.rest.from('test_items').select().eq('id', id);
        expect(result, isEmpty);
      });

      test('delete is idempotent', () async {
        final id = generateTestId('delete_idempotent');

        // Insert and delete
        await provider.upsert(
          'test_items',
          {'id': id, 'name': 'Idempotent Test'},
        );
        await provider.delete('test_items', id);

        // Delete again - should not throw
        await provider.delete('test_items', id);

        // Verify still gone
        final result =
            await supabase.rest.from('test_items').select().eq('id', id);
        expect(result, isEmpty);
      });
    });
  });

  group('DefaultSupabaseAuthProvider Integration Tests', () {
    late SupabaseClient supabase;
    late DefaultSupabaseAuthProvider authProvider;

    setUpAll(() async {
      supabase = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
      authProvider = DefaultSupabaseAuthProvider(supabase);
    });

    tearDownAll(() {
      supabase.dispose();
    });

    test('getAccessToken returns null when not authenticated', () async {
      final token = await authProvider.getAccessToken();
      // With anon key, there's no session until user signs in
      expect(token, isNull);
    });

    test('getUserId returns null when not authenticated', () async {
      final userId = await authProvider.getUserId();
      expect(userId, isNull);
    });

    test('getTokenExpiresAt returns null when not authenticated', () async {
      final expiresAt = await authProvider.getTokenExpiresAt();
      expect(expiresAt, isNull);
    });
  });
}
