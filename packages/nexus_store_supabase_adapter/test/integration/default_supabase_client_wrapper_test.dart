// ignore_for_file: unreachable_from_main, lines_longer_than_80_chars
@Tags(['integration'])
library;

import 'package:nexus_store_supabase_adapter/src/supabase_client_wrapper.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

/// Test configuration for Supabase integration tests.
///
/// Uses the same Supabase instance as PowerSync adapter tests.
class TestConfig {
  TestConfig._();

  static const supabaseUrl = 'https://ohfsnnhytsfwjdywsqdc.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oZnNubmh5dHNmd2pkeXdzcWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODk3MTAsImV4cCI6MjA4MTQ2NTcxMH0.NRyLSwzscRjytXho60CIEDHdwXOV0jrdkdI2sROJJaU';
}

void main() {
  group('DefaultSupabaseClientWrapper Integration Tests', () {
    late SupabaseClient client;
    late DefaultSupabaseClientWrapper wrapper;
    const tableName = 'test_items';
    const primaryKey = 'id';
    // Unique prefix for this test file to avoid conflicts with other test files
    const testPrefix = 'dcw-';

    setUpAll(() async {
      // Initialize Supabase client
      client = SupabaseClient(
        TestConfig.supabaseUrl,
        TestConfig.supabaseAnonKey,
      );
      wrapper = DefaultSupabaseClientWrapper(client);

      // Clean up any existing test data for this test file only
      try {
        await client.from(tableName).delete().like(primaryKey, '$testPrefix%');
      } on Object {
        // Table might not exist or be empty - that's fine
      }
    });

    tearDownAll(() async {
      // Clean up test data for this test file only
      try {
        await client.from(tableName).delete().like(primaryKey, '$testPrefix%');
      } on Object {
        // Ignore cleanup errors
      }
    });

    tearDown(() async {
      // Clean up after each test - only records from this test file
      try {
        await client.from(tableName).delete().like(primaryKey, '$testPrefix%');
      } on Object {
        // Ignore cleanup errors
      }
    });

    group('client getter', () {
      test('returns the underlying SupabaseClient', () {
        expect(wrapper.client, equals(client));
      });
    });

    group('upsert', () {
      test('creates a new record', () async {
        final data = {
          'id': '${testPrefix}test-1',
          'name': 'Test Item',
          'value': 100,
        };

        final result = await wrapper.upsert(tableName, data);

        expect(result['id'], equals('${testPrefix}test-1'));
        expect(result['name'], equals('Test Item'));
        expect(result['value'], equals(100));
      });

      test('updates an existing record', () async {
        // First create
        final data = {
          'id': '${testPrefix}test-2',
          'name': 'Original',
          'value': 50,
        };
        await wrapper.upsert(tableName, data);

        // Then update
        final updated = {
          'id': '${testPrefix}test-2',
          'name': 'Updated',
          'value': 100,
        };
        final result = await wrapper.upsert(tableName, updated);

        expect(result['id'], equals('${testPrefix}test-2'));
        expect(result['name'], equals('Updated'));
        expect(result['value'], equals(100));
      });
    });

    group('upsertAll', () {
      test('creates multiple records', () async {
        final data = [
          {'id': '${testPrefix}batch-1', 'name': 'Item 1', 'value': 10},
          {'id': '${testPrefix}batch-2', 'name': 'Item 2', 'value': 20},
          {'id': '${testPrefix}batch-3', 'name': 'Item 3', 'value': 30},
        ];

        final results = await wrapper.upsertAll(tableName, data);

        expect(results.length, equals(3));
        expect(results[0]['id'], equals('${testPrefix}batch-1'));
        expect(results[1]['id'], equals('${testPrefix}batch-2'));
        expect(results[2]['id'], equals('${testPrefix}batch-3'));
      });
    });

    group('get', () {
      test('retrieves a record by ID', () async {
        // Create a record first
        final data = {
          'id': '${testPrefix}get-test-1',
          'name': 'Get Test',
          'value': 42,
        };
        await wrapper.upsert(tableName, data);

        final result =
            await wrapper.get(tableName, primaryKey, '${testPrefix}get-test-1');

        expect(result, isNotNull);
        expect(result!['id'], equals('${testPrefix}get-test-1'));
        expect(result['name'], equals('Get Test'));
        expect(result['value'], equals(42));
      });

      test('returns null for non-existent ID', () async {
        final result = await wrapper.get(
          tableName,
          primaryKey,
          '${testPrefix}non-existent-id',
        );

        expect(result, isNull);
      });
    });

    group('getAll', () {
      test('retrieves all records without query builder', () async {
        // Create some records
        await wrapper.upsertAll(tableName, [
          {'id': '${testPrefix}all-1', 'name': 'All Item 1', 'value': 1},
          {'id': '${testPrefix}all-2', 'name': 'All Item 2', 'value': 2},
        ]);

        // Query only records for this test file
        final results = await wrapper.getAll(
          tableName,
          queryBuilder: (builder) async =>
              builder.like(primaryKey, '$testPrefix%'),
        );

        expect(results.length, greaterThanOrEqualTo(2));
        expect(results.any((r) => r['id'] == '${testPrefix}all-1'), isTrue);
        expect(results.any((r) => r['id'] == '${testPrefix}all-2'), isTrue);
      });

      test('retrieves records with query builder', () async {
        // Create some records with different values
        await wrapper.upsertAll(tableName, [
          {'id': '${testPrefix}query-1', 'name': 'Query Item', 'value': 100},
          {'id': '${testPrefix}query-2', 'name': 'Query Item', 'value': 200},
          {'id': '${testPrefix}query-3', 'name': 'Other Item', 'value': 300},
        ]);

        final results = await wrapper.getAll(
          tableName,
          queryBuilder: (builder) async => builder
              .like(primaryKey, '$testPrefix%')
              .eq('name', 'Query Item')
              .order('value', ascending: true),
        );

        expect(results.length, equals(2));
        expect(results[0]['id'], equals('${testPrefix}query-1'));
        expect(results[1]['id'], equals('${testPrefix}query-2'));
      });
    });

    group('delete', () {
      test('deletes a record by ID', () async {
        // Create a record
        await wrapper.upsert(
          tableName,
          {'id': '${testPrefix}delete-1', 'name': 'To Delete', 'value': 0},
        );

        // Verify it exists
        var result =
            await wrapper.get(tableName, primaryKey, '${testPrefix}delete-1');
        expect(result, isNotNull);

        // Delete it
        await wrapper.delete(tableName, primaryKey, '${testPrefix}delete-1');

        // Verify it's gone
        result =
            await wrapper.get(tableName, primaryKey, '${testPrefix}delete-1');
        expect(result, isNull);
      });

      test('does not throw for non-existent ID', () async {
        // Should not throw
        await expectLater(
          wrapper.delete(tableName, primaryKey, '${testPrefix}non-existent'),
          completes,
        );
      });
    });

    group('deleteByIds', () {
      test('deletes multiple records by IDs', () async {
        // Create records
        await wrapper.upsertAll(tableName, [
          {'id': '${testPrefix}multi-del-1', 'name': 'Delete 1', 'value': 1},
          {'id': '${testPrefix}multi-del-2', 'name': 'Delete 2', 'value': 2},
          {'id': '${testPrefix}multi-del-3', 'name': 'Keep', 'value': 3},
        ]);

        // Delete two of them
        await wrapper.deleteByIds(
          tableName,
          primaryKey,
          ['${testPrefix}multi-del-1', '${testPrefix}multi-del-2'],
        );

        // Verify deleted
        final result1 = await wrapper.get(
            tableName, primaryKey, '${testPrefix}multi-del-1');
        final result2 = await wrapper.get(
            tableName, primaryKey, '${testPrefix}multi-del-2');
        final result3 = await wrapper.get(
            tableName, primaryKey, '${testPrefix}multi-del-3');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNotNull);
      });

      test('handles empty ID list gracefully', () async {
        // Should not throw
        await expectLater(
          wrapper.deleteByIds(tableName, primaryKey, []),
          completes,
        );
      });
    });
  });
}
