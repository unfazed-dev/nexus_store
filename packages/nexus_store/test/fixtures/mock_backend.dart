import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:rxdart/rxdart.dart';

/// Mock implementation of [StoreBackend] for testing.
class MockStoreBackend<T, ID> extends Mock implements StoreBackend<T, ID> {}

/// Fake implementation of [StoreBackend] with controllable behavior.
///
/// Provides in-memory storage for testing without mocking.
class FakeStoreBackend<T, ID> with StoreBackendDefaults<T, ID> {
  FakeStoreBackend({
    this.idExtractor,
    this.backendName = 'FakeBackend',
  });

  /// Function to extract ID from entity.
  final ID Function(T)? idExtractor;

  /// The name of this backend.
  final String backendName;

  /// In-memory storage.
  final Map<ID, T> _storage = {};

  /// Field-level storage for lazy loading tests.
  final Map<ID, Map<String, dynamic>> _fieldStorage = {};

  /// BehaviorSubjects for watching individual items.
  final Map<ID, BehaviorSubject<T?>> _watchers = {};

  /// BehaviorSubject for watching all items.
  BehaviorSubject<List<T>>? _watchAllSubject;

  /// Sync status subject.
  final BehaviorSubject<SyncStatus> _syncStatusSubject =
      BehaviorSubject.seeded(SyncStatus.synced);

  /// Track pending changes for testing.
  int pendingChangesForTest = 0;

  /// Control flags for testing.
  bool shouldFailOnGet = false;
  bool shouldFailOnSave = false;
  bool shouldFailOnDelete = false;
  bool shouldFailOnSync = false;

  /// Error to throw when operations fail.
  Exception? errorToThrow;

  @override
  String get name => backendName;

  @override
  SyncStatus get syncStatus => _syncStatusSubject.value;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusSubject.stream;

  @override
  Future<int> get pendingChangesCount async => pendingChangesForTest;

  @override
  Future<T?> get(ID id) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('Get failed');
    }
    return _storage[id];
  }

  @override
  Future<List<T>> getAll({Query<T>? query}) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('GetAll failed');
    }
    return _storage.values.toList();
  }

  @override
  Stream<T?> watch(ID id) {
    _watchers[id] ??= BehaviorSubject.seeded(_storage[id]);
    return _watchers[id]!.stream;
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) {
    _watchAllSubject ??= BehaviorSubject.seeded(_storage.values.toList());
    return _watchAllSubject!.stream;
  }

  @override
  Future<T> save(T item) async {
    if (shouldFailOnSave) {
      throw errorToThrow ?? Exception('Save failed');
    }
    final id = idExtractor?.call(item);
    if (id != null) {
      _storage[id] = item;
      _watchers[id]?.add(item);
      _watchAllSubject?.add(_storage.values.toList());
    }
    return item;
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    if (shouldFailOnSave) {
      throw errorToThrow ?? Exception('SaveAll failed');
    }
    for (final item in items) {
      final id = idExtractor?.call(item);
      if (id != null) {
        _storage[id] = item;
        _watchers[id]?.add(item);
      }
    }
    _watchAllSubject?.add(_storage.values.toList());
    return items;
  }

  @override
  Future<bool> delete(ID id) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('Delete failed');
    }
    final existed = _storage.containsKey(id);
    _storage.remove(id);
    _watchers[id]?.add(null);
    _watchAllSubject?.add(_storage.values.toList());
    return existed;
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('DeleteAll failed');
    }
    var count = 0;
    for (final id in ids) {
      if (_storage.containsKey(id)) {
        _storage.remove(id);
        _watchers[id]?.add(null);
        count++;
      }
    }
    _watchAllSubject?.add(_storage.values.toList());
    return count;
  }

  @override
  Future<int> deleteWhere(Query<T> query) async {
    if (shouldFailOnDelete) {
      throw errorToThrow ?? Exception('DeleteWhere failed');
    }
    // For testing, just clear all
    final count = _storage.length;
    _storage.clear();
    _watchAllSubject?.add([]);
    return count;
  }

  @override
  Future<void> sync() async {
    if (shouldFailOnSync) {
      throw errorToThrow ?? Exception('Sync failed');
    }
    _syncStatusSubject.add(SyncStatus.syncing);
    await Future<void>.delayed(Duration.zero);
    pendingChangesForTest = 0;
    _syncStatusSubject.add(SyncStatus.synced);
  }

  /// Manually set sync status for testing.
  void setSyncStatus(SyncStatus status) {
    _syncStatusSubject.add(status);
  }

  /// Add item directly to storage for testing.
  void addToStorage(ID id, T item) {
    _storage[id] = item;
    _watchers[id]?.add(item);
    _watchAllSubject?.add(_storage.values.toList());
    _notifyPagedWatchers();
  }

  /// Get storage contents for verification.
  Map<ID, T> get storage => Map.unmodifiable(_storage);

  /// Clear all data.
  void clear() {
    _storage.clear();
    for (final subject in _watchers.values) {
      subject.add(null);
    }
    _watchAllSubject?.add([]);
    _notifyPagedWatchers();
  }

  @override
  Future<void> close() async {
    await _syncStatusSubject.close();
    for (final subject in _watchers.values) {
      await subject.close();
    }
    await _watchAllSubject?.close();
    for (final controller in _pagedWatchers.values) {
      await controller.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Pagination Support
  // ---------------------------------------------------------------------------

  @override
  bool get supportsPagination => true;

  /// Map of active paged watchers.
  final Map<int, StreamController<PagedResult<T>>> _pagedWatchers = {};
  int _pagedWatcherCounter = 0;

  /// Field accessor for filtering/ordering test entities.
  /// Override this to provide custom field extraction.
  Object? Function(T item, String field)? fieldAccessor;

  @override
  Future<PagedResult<T>> getAllPaged({Query<T>? query}) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('GetAllPaged failed');
    }

    var items = _storage.values.toList();
    final totalCount = items.length;

    // Apply filters if query has them
    if (query != null && query.filters.isNotEmpty) {
      items = _applyFilters(items, query.filters);
    }

    // Apply ordering
    if (query != null && query.orderBy.isNotEmpty) {
      items = _applyOrdering(items, query.orderBy);
    }

    // Handle cursor-based pagination
    final afterCursor = query?.afterCursor;
    final beforeCursor = query?.beforeCursor;
    final firstCount = query?.firstCount;
    final lastCount = query?.lastCount;

    var startIndex = 0;
    var endIndex = items.length;

    // Handle after cursor (forward pagination)
    if (afterCursor != null) {
      final cursorIndex = afterCursor.toValues()['_index'] as int?;
      if (cursorIndex != null && cursorIndex < items.length) {
        startIndex = cursorIndex;
      }
    }

    // Handle before cursor (backward pagination)
    if (beforeCursor != null) {
      final cursorIndex = beforeCursor.toValues()['_index'] as int?;
      if (cursorIndex != null && cursorIndex <= items.length) {
        endIndex = cursorIndex;
      }
    }

    // Apply first/last limits
    if (firstCount != null) {
      endIndex = (startIndex + firstCount).clamp(0, items.length);
    }

    if (lastCount != null) {
      startIndex = (endIndex - lastCount).clamp(0, endIndex);
    }

    // Extract the page
    final pageItems = items.sublist(startIndex, endIndex);

    // Build page info
    final hasNextPage = endIndex < items.length;
    final hasPreviousPage = startIndex > 0;

    Cursor? startCursor;
    Cursor? endCursor;

    if (pageItems.isNotEmpty) {
      startCursor = Cursor.fromValues({'_index': startIndex});
      // Only provide endCursor (nextCursor) if there are more pages
      if (hasNextPage) {
        endCursor = Cursor.fromValues({'_index': endIndex});
      }
    }

    return PagedResult<T>(
      items: pageItems,
      pageInfo: PageInfo(
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        startCursor: startCursor,
        endCursor: endCursor,
        totalCount: totalCount,
      ),
    );
  }

  @override
  Stream<PagedResult<T>> watchAllPaged({Query<T>? query}) {
    final id = _pagedWatcherCounter++;
    final controller = StreamController<PagedResult<T>>.broadcast(
      onCancel: () => _pagedWatchers.remove(id),
    );
    _pagedWatchers[id] = controller;

    // Emit initial value
    getAllPaged(query: query).then(controller.add);

    // Store query for updates
    _pagedWatcherQueries[id] = query;

    return controller.stream;
  }

  final Map<int, Query<T>?> _pagedWatcherQueries = {};

  void _notifyPagedWatchers() {
    for (final entry in _pagedWatchers.entries) {
      final query = _pagedWatcherQueries[entry.key];
      getAllPaged(query: query).then(entry.value.add);
    }
  }

  List<T> _applyFilters(List<T> items, List<QueryFilter> filters) {
    return items.where((item) {
      for (final filter in filters) {
        final fieldValue = _getFieldValue(item, filter.field);
        if (!_matchesFilter(fieldValue, filter)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<T> _applyOrdering(List<T> items, List<QueryOrderBy> orderSpecs) {
    final result = List<T>.from(items);
    result.sort((a, b) {
      for (final spec in orderSpecs) {
        final aValue = _getFieldValue(a, spec.field);
        final bValue = _getFieldValue(b, spec.field);
        final comparison = _compareValues(aValue, bValue);
        if (comparison != 0) {
          return spec.descending ? -comparison : comparison;
        }
      }
      return 0;
    });
    return result;
  }

  Object? _getFieldValue(T item, String field) {
    if (fieldAccessor != null) {
      return fieldAccessor!(item, field);
    }
    // Default: try to access via reflection-like mechanism for test entities
    // For production, backends should implement their own field access
    return null;
  }

  bool _matchesFilter(Object? value, QueryFilter filter) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return value == filter.value;
      case FilterOperator.notEquals:
        return value != filter.value;
      case FilterOperator.isNull:
        return value == null;
      case FilterOperator.isNotNull:
        return value != null;
      case FilterOperator.lessThan:
        return _compareValues(value, filter.value) < 0;
      case FilterOperator.lessThanOrEquals:
        return _compareValues(value, filter.value) <= 0;
      case FilterOperator.greaterThan:
        return _compareValues(value, filter.value) > 0;
      case FilterOperator.greaterThanOrEquals:
        return _compareValues(value, filter.value) >= 0;
      case FilterOperator.whereIn:
        final list = filter.value as List?;
        return list?.contains(value) ?? false;
      case FilterOperator.whereNotIn:
        final list = filter.value as List?;
        return !(list?.contains(value) ?? true);
      case FilterOperator.arrayContains:
        final list = value as List?;
        return list?.contains(filter.value) ?? false;
      case FilterOperator.arrayContainsAny:
        final list = value as List?;
        final filterList = filter.value as List?;
        if (list == null || filterList == null) return false;
        return list.any(filterList.contains);
      case FilterOperator.contains:
        return value.toString().contains(filter.value.toString());
      case FilterOperator.startsWith:
        return value.toString().startsWith(filter.value.toString());
      case FilterOperator.endsWith:
        return value.toString().endsWith(filter.value.toString());
    }
  }

  int _compareValues(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is Comparable && b is Comparable) {
      return a.compareTo(b);
    }

    return a.toString().compareTo(b.toString());
  }

  // ---------------------------------------------------------------------------
  // Field Operations (Lazy Loading)
  // ---------------------------------------------------------------------------

  @override
  bool get supportsFieldOperations => true;

  @override
  Future<dynamic> getField(ID id, String fieldName) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('GetField failed');
    }
    return _fieldStorage[id]?[fieldName];
  }

  @override
  Future<Map<ID, dynamic>> getFieldBatch(
    List<ID> ids,
    String fieldName,
  ) async {
    if (shouldFailOnGet) {
      throw errorToThrow ?? Exception('GetFieldBatch failed');
    }
    final results = <ID, dynamic>{};
    for (final id in ids) {
      final value = _fieldStorage[id]?[fieldName];
      if (value != null) {
        results[id] = value;
      }
    }
    return results;
  }

  /// Add a field value to storage for testing lazy loading.
  void addFieldToStorage(ID id, String fieldName, dynamic value) {
    _fieldStorage[id] ??= {};
    _fieldStorage[id]![fieldName] = value;
  }

  /// Get field storage contents for verification.
  Map<ID, Map<String, dynamic>> get fieldStorage =>
      Map.unmodifiable(_fieldStorage);

  /// Clear field storage.
  void clearFieldStorage() {
    _fieldStorage.clear();
  }

  // ---------------------------------------------------------------------------
  // Pending Changes Support (for testing retryAllPending/cancelAllPending)
  // ---------------------------------------------------------------------------

  /// List of pending changes for testing.
  final List<PendingChange<T>> _pendingChanges = [];

  /// Stream controller for pending changes.
  final _pendingChangesController =
      BehaviorSubject<List<PendingChange<T>>>.seeded([]);

  @override
  Stream<List<PendingChange<T>>> get pendingChangesStream =>
      _pendingChangesController.stream;

  /// Add a pending change for testing.
  void addPendingChange(PendingChange<T> change) {
    _pendingChanges.add(change);
    _pendingChangesController.add(List.unmodifiable(_pendingChanges));
  }

  /// Clear pending changes.
  void clearPendingChanges() {
    _pendingChanges.clear();
    _pendingChangesController.add([]);
  }

  /// Track retried change IDs for verification.
  final List<String> retriedChangeIds = [];

  /// Track cancelled change IDs for verification.
  final List<String> cancelledChangeIds = [];

  @override
  Future<void> retryChange(String changeId) async {
    retriedChangeIds.add(changeId);
    // Remove from pending changes on retry
    _pendingChanges.removeWhere((c) => c.id == changeId);
    _pendingChangesController.add(List.unmodifiable(_pendingChanges));
  }

  @override
  Future<PendingChange<T>?> cancelChange(String changeId) async {
    cancelledChangeIds.add(changeId);
    final index = _pendingChanges.indexWhere((c) => c.id == changeId);
    if (index >= 0) {
      final change = _pendingChanges.removeAt(index);
      _pendingChangesController.add(List.unmodifiable(_pendingChanges));
      return change;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Transaction Support
  // ---------------------------------------------------------------------------

  /// Whether this backend supports transactions (configurable for testing).
  bool supportsTransactionsForTest = true;

  @override
  bool get supportsTransactions => supportsTransactionsForTest;

  /// Active transactions for testing.
  final Map<String, _TransactionState<T, ID>> _transactions = {};

  @override
  Future<String> beginTransaction() async {
    final txId = 'test_tx_${DateTime.now().microsecondsSinceEpoch}';
    _transactions[txId] = _TransactionState<T, ID>();
    return txId;
  }

  @override
  Future<void> commitTransaction(String transactionId) async {
    final tx = _transactions.remove(transactionId);
    if (tx == null) {
      throw const TransactionError(message: 'Unknown transaction');
    }
    // Operations already applied - just clean up
  }

  @override
  Future<void> rollbackTransaction(String transactionId) async {
    final tx = _transactions.remove(transactionId);
    if (tx == null) {
      throw const TransactionError(message: 'Unknown transaction');
    }
    // Revert operations in reverse order
    for (final op in tx.operations.reversed) {
      if (op.originalValue != null) {
        _storage[op.id] = op.originalValue as T;
        _watchers[op.id]?.add(op.originalValue as T);
      } else {
        _storage.remove(op.id);
        _watchers[op.id]?.add(null);
      }
    }
    _watchAllSubject?.add(_storage.values.toList());
    _notifyPagedWatchers();
  }

  @override
  Future<R> runInTransaction<R>(Future<R> Function() callback) async {
    final txId = await beginTransaction();
    try {
      final result = await callback();
      await commitTransaction(txId);
      return result;
    } catch (e) {
      await rollbackTransaction(txId);
      rethrow;
    }
  }
}

/// Internal class to track transaction state for testing.
class _TransactionState<T, ID> {
  final List<_PendingOperation<T, ID>> operations = [];
}

/// Internal class to track pending operations within a transaction.
class _PendingOperation<T, ID> {
  _PendingOperation({
    required this.id,
    this.originalValue,
  });

  final ID id;
  final T? originalValue;
}
