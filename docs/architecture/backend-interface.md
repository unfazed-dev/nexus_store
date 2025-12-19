# Backend Interface

This document describes how to implement custom backends for nexus_store.

## StoreBackend Interface

All backends must implement `StoreBackend<T, ID>`:

```dart
abstract interface class StoreBackend<T, ID> {
  // --- Identity ---
  String get name;

  // --- Capabilities ---
  bool get supportsOffline;
  bool get supportsRealtime;
  bool get supportsTransactions;

  // --- Lifecycle ---
  Future<void> initialize();
  Future<void> close();

  // --- Read Operations ---
  Future<T?> get(ID id);
  Future<List<T>> getAll({Query<T>? query});
  Stream<T?> watch(ID id);
  Stream<List<T>> watchAll({Query<T>? query});

  // --- Write Operations ---
  Future<T> save(T item);
  Future<List<T>> saveAll(List<T> items);
  Future<bool> delete(ID id);
  Future<int> deleteAll(List<ID> ids);
  Future<int> deleteWhere(Query<T> query);

  // --- Sync Operations ---
  SyncStatus get syncStatus;
  Stream<SyncStatus> get syncStatusStream;
  Future<void> sync();
  Future<int> get pendingChangesCount;
}
```

## Implementing a Custom Backend

### Minimal Implementation

```dart
class MyBackend<T, ID> implements StoreBackend<T, ID> {
  final Map<ID, T> _data = {};
  final ID Function(T) getId;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  MyBackend({
    required this.getId,
    required this.fromJson,
    required this.toJson,
  });

  // --- Identity ---
  @override
  String get name => 'MyBackend';

  // --- Capabilities ---
  @override
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  // --- Lifecycle ---
  @override
  Future<void> initialize() async {
    // Connect to database, set up resources
  }

  @override
  Future<void> close() async {
    // Clean up resources
  }

  // --- Read Operations ---
  @override
  Future<T?> get(ID id) async => _data[id];

  @override
  Future<List<T>> getAll({Query<T>? query}) async {
    var items = _data.values.toList();
    if (query != null) {
      items = applyQuery(items, query);
    }
    return items;
  }

  @override
  Stream<T?> watch(ID id) async* {
    yield _data[id];
    // For realtime: yield on changes
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) async* {
    yield await getAll(query: query);
    // For realtime: yield on changes
  }

  // --- Write Operations ---
  @override
  Future<T> save(T item) async {
    _data[getId(item)] = item;
    return item;
  }

  @override
  Future<List<T>> saveAll(List<T> items) async {
    for (final item in items) {
      _data[getId(item)] = item;
    }
    return items;
  }

  @override
  Future<bool> delete(ID id) async {
    return _data.remove(id) != null;
  }

  @override
  Future<int> deleteAll(List<ID> ids) async {
    var count = 0;
    for (final id in ids) {
      if (_data.remove(id) != null) count++;
    }
    return count;
  }

  @override
  Future<int> deleteWhere(Query<T> query) async {
    final toDelete = await getAll(query: query);
    for (final item in toDelete) {
      _data.remove(getId(item));
    }
    return toDelete.length;
  }

  // --- Sync Operations ---
  @override
  SyncStatus get syncStatus => SyncStatus.synced;

  @override
  Stream<SyncStatus> get syncStatusStream =>
    Stream.value(SyncStatus.synced);

  @override
  Future<void> sync() async {
    // No-op for local-only backends
  }

  @override
  Future<int> get pendingChangesCount async => 0;
}
```

## Query Translation

Implement a query translator to convert `Query<T>` to your backend's format:

```dart
class MyQueryTranslator<T> {
  final Map<String, dynamic> Function(T) toJson;

  MyQueryTranslator({required this.toJson});

  List<T> apply(List<T> items, Query<T> query) {
    var result = items;

    // Apply filters
    for (final filter in query.filters) {
      result = result.where((item) {
        final value = toJson(item)[filter.field];
        return matchesFilter(value, filter);
      }).toList();
    }

    // Apply ordering
    for (final order in query.orderBy) {
      result.sort((a, b) {
        final va = toJson(a)[order.field] as Comparable;
        final vb = toJson(b)[order.field] as Comparable;
        final cmp = va.compareTo(vb);
        return order.descending ? -cmp : cmp;
      });
    }

    // Apply pagination
    if (query.offset != null) {
      result = result.skip(query.offset!).toList();
    }
    if (query.limit != null) {
      result = result.take(query.limit!).toList();
    }

    return result;
  }

  bool matchesFilter(dynamic value, QueryFilter filter) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return value == filter.value;
      case FilterOperator.notEquals:
        return value != filter.value;
      case FilterOperator.greaterThan:
        return (value as Comparable).compareTo(filter.value) > 0;
      case FilterOperator.lessThan:
        return (value as Comparable).compareTo(filter.value) < 0;
      case FilterOperator.whereIn:
        return (filter.value as List).contains(value);
      // ... other operators
      default:
        return true;
    }
  }
}
```

## Capabilities

### supportsOffline

Return `true` if the backend can store and retrieve data without network:

- Local databases (SQLite, IndexedDB): `true`
- Remote-only APIs (REST, GraphQL): `false`
- Offline-first with sync (PowerSync, Brick): `true`

### supportsRealtime

Return `true` if the backend provides live updates:

- Supabase Realtime: `true`
- PowerSync: `true`
- Plain SQLite: `false`

### supportsTransactions

Return `true` if the backend supports atomic transactions:

- SQL databases: `true`
- Many NoSQL: `false`

## Reactive Streams Implementation

For backends with realtime support:

```dart
class RealtimeBackend<T, ID> implements StoreBackend<T, ID> {
  final _itemControllers = <ID, BehaviorSubject<T?>>{};
  final _allController = BehaviorSubject<List<T>>();

  @override
  Stream<T?> watch(ID id) {
    _itemControllers[id] ??= BehaviorSubject<T?>();
    // Initial fetch
    get(id).then((item) => _itemControllers[id]!.add(item));
    return _itemControllers[id]!.stream;
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) {
    // Initial fetch
    getAll(query: query).then((items) => _allController.add(items));
    return _allController.stream;
  }

  @override
  Future<T> save(T item) async {
    // ... save logic

    // Notify watchers
    final id = getId(item);
    _itemControllers[id]?.add(item);

    // Refresh all watcher
    final all = await getAll();
    _allController.add(all);

    return item;
  }

  @override
  Future<void> close() async {
    for (final controller in _itemControllers.values) {
      await controller.close();
    }
    await _allController.close();
  }
}
```

## Error Handling

Throw appropriate `StoreError` subclasses:

```dart
@override
Future<T?> get(ID id) async {
  try {
    return await fetchFromDatabase(id);
  } on DatabaseException catch (e) {
    throw StoreError('Database error: $e');
  } on SocketException catch (e) {
    throw NetworkError('Network error: $e', isRetryable: true);
  }
}
```

## Testing Your Backend

Create comprehensive tests:

```dart
void main() {
  late MyBackend<User, String> backend;

  setUp(() async {
    backend = MyBackend<User, String>(
      getId: (u) => u.id,
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
    );
    await backend.initialize();
  });

  tearDown(() async {
    await backend.close();
  });

  test('saves and retrieves item', () async {
    final user = User(id: '1', name: 'Alice');
    await backend.save(user);

    final retrieved = await backend.get('1');
    expect(retrieved?.name, equals('Alice'));
  });

  test('applies query filters', () async {
    await backend.saveAll([
      User(id: '1', name: 'Alice', status: 'active'),
      User(id: '2', name: 'Bob', status: 'inactive'),
    ]);

    final active = await backend.getAll(
      query: Query<User>().where('status', isEqualTo: 'active'),
    );

    expect(active.length, equals(1));
    expect(active.first.name, equals('Alice'));
  });

  // ... more tests
}
```

## Best Practices

1. **Initialize lazily** - Only connect when needed
2. **Handle connection failures** - Throw appropriate errors
3. **Clean up resources** - Implement `close()` properly
4. **Emit stream updates** - Keep watchers in sync
5. **Document capabilities** - Clearly state what's supported
6. **Test thoroughly** - Cover all operations and edge cases

## See Also

- [Architecture Overview](overview.md)
- [Policy Engine](policy-engine.md)
