import 'package:supabase/supabase.dart';

/// An abstraction over [SupabaseClient] to enable mocking in tests.
///
/// This wrapper encapsulates Supabase's fluent builder pattern, making it
/// possible to test the [SupabaseBackend] without requiring a real database.
///
/// ## Usage
///
/// For production code, use [DefaultSupabaseClientWrapper]:
/// ```dart
/// final wrapper = DefaultSupabaseClientWrapper(supabaseClient);
/// ```
///
/// For tests, create a mock implementation:
/// ```dart
/// class MockSupabaseClientWrapper extends Mock
///     implements SupabaseClientWrapper {}
/// ```
abstract class SupabaseClientWrapper {
  /// Gets a single record by ID.
  ///
  /// Returns `null` if no record is found.
  Future<Map<String, dynamic>?> get(
    String table,
    String primaryKeyColumn,
    Object id,
  );

  /// Gets all records from a table, optionally with a query builder callback.
  ///
  /// The [queryBuilder] can be used to add filters, ordering, and pagination.
  /// It receives the initial filter builder and should return a Future with
  /// the final results.
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    Future<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    )? queryBuilder,
  });

  /// Creates or updates a single record.
  ///
  /// Returns the created/updated record.
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  );

  /// Creates or updates multiple records.
  ///
  /// Returns the list of created/updated records.
  Future<List<Map<String, dynamic>>> upsertAll(
    String table,
    List<Map<String, dynamic>> data,
  );

  /// Deletes a single record by ID.
  Future<void> delete(
    String table,
    String primaryKeyColumn,
    Object id,
  );

  /// Deletes multiple records by their IDs.
  Future<void> deleteByIds(
    String table,
    String primaryKeyColumn,
    List<Object> ids,
  );

  /// Gets access to the underlying SupabaseClient for realtime operations.
  ///
  /// This is needed for initializing the [SupabaseRealtimeManager].
  SupabaseClient get client;
}

/// Default implementation of [SupabaseClientWrapper] that delegates to
/// a real [SupabaseClient].
class DefaultSupabaseClientWrapper implements SupabaseClientWrapper {
  /// Creates a wrapper around the given [SupabaseClient].
  DefaultSupabaseClientWrapper(this._client);

  final SupabaseClient _client;

  @override
  SupabaseClient get client => _client;

  @override
  Future<Map<String, dynamic>?> get(
    String table,
    String primaryKeyColumn,
    Object id,
  ) async {
    return _client
        .from(table)
        .select()
        .eq(primaryKeyColumn, id)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    Future<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    )? queryBuilder,
  }) async {
    final builder = _client.from(table).select();
    if (queryBuilder != null) {
      return queryBuilder(builder);
    }
    return builder;
  }

  @override
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return _client.from(table).upsert(data).select().single();
  }

  @override
  Future<List<Map<String, dynamic>>> upsertAll(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    return _client.from(table).upsert(data).select();
  }

  @override
  Future<void> delete(
    String table,
    String primaryKeyColumn,
    Object id,
  ) async {
    await _client.from(table).delete().eq(primaryKeyColumn, id);
  }

  @override
  Future<void> deleteByIds(
    String table,
    String primaryKeyColumn,
    List<Object> ids,
  ) async {
    await _client.from(table).delete().inFilter(primaryKeyColumn, ids);
  }
}
