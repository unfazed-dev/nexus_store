import 'package:powersync/powersync.dart';
import 'package:supabase/supabase.dart';

/// Interface for providing Supabase authentication data.
///
/// This abstraction allows for easy testing and alternative implementations.
abstract class SupabaseAuthProvider {
  /// Gets the current access token, or null if not authenticated.
  Future<String?> getAccessToken();

  /// Gets the current user ID, or null if not authenticated.
  Future<String?> getUserId();

  /// Gets the token expiration time, or null if not available.
  Future<DateTime?> getTokenExpiresAt();
}

/// Interface for Supabase data operations.
///
/// This abstraction allows for easy testing and alternative implementations.
abstract class SupabaseDataProvider {
  /// Upserts data into a table.
  Future<void> upsert(String table, Map<String, dynamic> data);

  /// Updates data in a table by ID.
  Future<void> update(String table, String id, Map<String, dynamic> data);

  /// Deletes a record from a table by ID.
  Future<void> delete(String table, String id);
}

/// Default implementation of [SupabaseAuthProvider] using SupabaseClient.
class DefaultSupabaseAuthProvider implements SupabaseAuthProvider {
  /// Creates a provider with the given Supabase client.
  DefaultSupabaseAuthProvider(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> getAccessToken() async =>
      _client.auth.currentSession?.accessToken;

  @override
  Future<String?> getUserId() async => _client.auth.currentSession?.user.id;

  @override
  Future<DateTime?> getTokenExpiresAt() async {
    final expiresIn = _client.auth.currentSession?.expiresIn;
    if (expiresIn == null) return null;
    return DateTime.now().add(Duration(seconds: expiresIn));
  }
}

/// Default implementation of [SupabaseDataProvider] using SupabaseClient.
class DefaultSupabaseDataProvider implements SupabaseDataProvider {
  /// Creates a provider with the given Supabase client.
  DefaultSupabaseDataProvider(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    await _client.rest.from(table).upsert(data);
  }

  @override
  Future<void> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _client.rest.from(table).update(data).eq('id', id);
  }

  @override
  Future<void> delete(String table, String id) async {
    await _client.rest.from(table).delete().eq('id', id);
  }
}

/// A PowerSync connector that integrates with Supabase for authentication
/// and data synchronization.
///
/// Example usage:
/// ```dart
/// final connector = SupabasePowerSyncConnector.withClient(
///   supabase: Supabase.instance.client,
///   powerSyncUrl: 'https://xxx.powersync.co',
/// );
/// ```
class SupabasePowerSyncConnector extends PowerSyncBackendConnector {
  /// Creates a connector with explicit auth and data providers.
  ///
  /// This constructor is useful for testing with mocked providers.
  SupabasePowerSyncConnector({
    required SupabaseAuthProvider authProvider,
    required SupabaseDataProvider dataProvider,
    required String powerSyncUrl,
  })  : _authProvider = authProvider,
        _dataProvider = dataProvider,
        _powerSyncUrl = powerSyncUrl;

  /// Creates a connector with a Supabase client.
  ///
  /// This is the recommended constructor for production use.
  factory SupabasePowerSyncConnector.withClient({
    required SupabaseClient supabase,
    required String powerSyncUrl,
  }) => SupabasePowerSyncConnector(
      authProvider: DefaultSupabaseAuthProvider(supabase),
      dataProvider: DefaultSupabaseDataProvider(supabase),
      powerSyncUrl: powerSyncUrl,
    );

  final SupabaseAuthProvider _authProvider;
  final SupabaseDataProvider _dataProvider;
  final String _powerSyncUrl;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final token = await _authProvider.getAccessToken();
    if (token == null) {
      return null;
    }

    final userId = await _authProvider.getUserId();
    final expiresAt = await _authProvider.getTokenExpiresAt();

    return PowerSyncCredentials(
      endpoint: _powerSyncUrl,
      token: token,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    try {
      for (final op in transaction.crud) {
        final table = op.table;
        final id = op.id;

        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.of(op.opData ?? {});
            data['id'] = id;
            await _dataProvider.upsert(table, data);
          case UpdateType.patch:
            await _dataProvider.update(table, id, op.opData ?? {});
          case UpdateType.delete:
            await _dataProvider.delete(table, id);
        }
      }

      await transaction.complete();
    } on PostgrestException catch (e) {
      // Check if this is a fatal error that shouldn't be retried
      if (_isFatalError(e)) {
        // Mark as complete to prevent infinite retries
        await transaction.complete();
        rethrow;
      }
      // Let PowerSync retry on transient errors
      rethrow;
    }
  }

  bool _isFatalError(PostgrestException e) {
    // HTTP 4xx errors (except 429 rate limit) are usually fatal
    final code = e.code;
    if (code == null) return false;

    final statusCode = int.tryParse(code);
    if (statusCode == null) return false;

    return statusCode >= 400 && statusCode < 500 && statusCode != 429;
  }
}
