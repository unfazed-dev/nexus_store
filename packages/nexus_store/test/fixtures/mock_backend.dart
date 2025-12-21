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
}
