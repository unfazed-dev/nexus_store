import 'package:nexus_store/src/config/policies.dart';
import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:nexus_store/src/query/query_scope.dart';

/// A proxy around [NexusStore] that auto-applies [QueryScope]s to read queries.
///
/// Write operations (save, delete, upsert) pass through unmodified.
/// Read operations (getAll, getOne, watchAll, watchOne, count, existsWhere,
/// deleteWhere, updateWhere) have scopes applied to their queries.
///
/// ## Example
///
/// ```dart
/// final scopedStore = ScopedStore(
///   store: userStore,
///   scopes: [SoftDeleteScope(), OwnerScope(ownerId: 'user-123')],
/// );
///
/// // Automatically excludes soft-deleted + filters by owner
/// final users = await scopedStore.getAll();
/// ```
class ScopedStore<T, ID> {
  /// Creates a scoped store.
  ScopedStore({
    required NexusStore<T, ID> store,
    required List<QueryScope<T>> scopes,
  })  : _store = store,
        _scopes = List.unmodifiable(scopes);

  final NexusStore<T, ID> _store;
  final List<QueryScope<T>> _scopes;

  /// The underlying store.
  NexusStore<T, ID> get store => _store;

  /// The scopes applied by this proxy.
  List<QueryScope<T>> get scopes => _scopes;

  /// Applies all scopes to a query.
  Query<T> _applyScopes(Query<T>? query) {
    var result = query ?? Query<T>();
    for (final scope in _scopes) {
      result = scope.apply(result);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Read operations (scoped)
  // ---------------------------------------------------------------------------

  /// Retrieves all entities matching the scoped query.
  Future<List<T>> getAll({Query<T>? query, FetchPolicy? policy}) {
    return _store.getAll(query: _applyScopes(query), policy: policy);
  }

  /// Retrieves a single entity matching the scoped query.
  Future<T?> getOne({Query<T>? query, FetchPolicy? policy}) {
    return _store.getOne(query: _applyScopes(query), policy: policy);
  }

  /// Watches all entities matching the scoped query.
  Stream<List<T>> watchAll({Query<T>? query}) {
    return _store.watchAll(query: _applyScopes(query));
  }

  /// Watches a single entity matching the scoped query.
  Stream<T?> watchOne(Query<T> query) {
    return _store.watchOne(_applyScopes(query));
  }

  /// Returns the count of entities matching the scoped query.
  Future<int> count({Query<T>? query, FetchPolicy? policy}) {
    return _store.count(query: _applyScopes(query), policy: policy);
  }

  /// Returns true if any entity matches the scoped query.
  Future<bool> existsWhere(Query<T> query) {
    return _store.existsWhere(_applyScopes(query));
  }

  /// Deletes entities matching the scoped query.
  Future<int> deleteWhere(Query<T> query) {
    return _store.deleteWhere(_applyScopes(query));
  }

  /// Updates entities matching the scoped query.
  Future<int> updateWhere(Query<T> query, Map<String, dynamic> updates) {
    return _store.updateWhere(_applyScopes(query), updates);
  }

  // ---------------------------------------------------------------------------
  // Write operations (pass-through)
  // ---------------------------------------------------------------------------

  /// Saves an entity (pass-through, no scope applied).
  Future<T> save(T item, {WritePolicy? policy}) {
    return _store.save(item, policy: policy);
  }

  /// Deletes an entity by ID (pass-through, no scope applied).
  Future<bool> delete(ID id) {
    return _store.delete(id);
  }

  /// Upserts an entity (pass-through, no scope applied).
  Future<T> upsert(T item) {
    return _store.upsert(item);
  }

  /// Finds an entity by field value within the scoped query.
  Future<T?> findBy(String field, Object value, {FetchPolicy? policy}) {
    return getOne(
      query: Query<T>().where(field, isEqualTo: value),
      policy: policy,
    );
  }
}
