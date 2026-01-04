/// Basic usage example for nexus_store.
///
/// This example demonstrates:
/// - Store initialization with an in-memory backend
/// - CRUD operations (create, read, update, delete)
/// - Query builder usage
/// - Reactive streams with watch/watchAll
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:nexus_store/nexus_store.dart';

/// Logs a message for the example output.
void log(String message) => developer.log(message, name: 'nexus_store');

/// Simple User model for the example.
class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.age,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
        age: json['age'] as int,
      );
  final String id;
  final String name;
  final String email;
  final String status;
  final int age;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'status': status,
        'age': age,
      };

  User copyWith({
    String? name,
    String? email,
    String? status,
    int? age,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        status: status ?? this.status,
        age: age ?? this.age,
      );

  @override
  String toString() => 'User(id: $id, name: $name, status: $status, age: $age)';
}

/// Simple in-memory backend for demonstration.
class InMemoryBackend<T, ID>
    with StoreBackendDefaults<T, ID>
    implements StoreBackend<T, ID> {
  InMemoryBackend({
    required this.getId,
    required this.fromJson,
    required this.toJson,
  });
  final ID Function(T) getId;
  // ignore: unreachable_from_main
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final Map<ID, T> _data = {};

  @override
  String get name => 'InMemoryBackend';

  @override
  bool get supportsOffline => false;

  @override
  bool get supportsRealtime => false;

  @override
  bool get supportsTransactions => false;

  @override
  SyncStatus get syncStatus => SyncStatus.synced;

  @override
  Stream<SyncStatus> get syncStatusStream => Stream.value(SyncStatus.synced);

  @override
  Future<int> get pendingChangesCount async => 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> sync() async {}

  @override
  Future<T?> get(ID id) async => _data[id];

  @override
  Future<List<T>> getAll({Query<T>? query}) async {
    var items = _data.values.toList();
    if (query != null) {
      items = _applyFilters(items, query);
      items = _applyOrdering(items, query);
      items = _applyPagination(items, query);
    }
    return items;
  }

  @override
  Stream<T?> watch(ID id) async* {
    yield _data[id];
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) async* {
    yield await getAll(query: query);
  }

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
  Future<bool> delete(ID id) async => _data.remove(id) != null;

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

  List<T> _applyFilters(List<T> items, Query<T> query) {
    var result = items;
    for (final filter in query.filters) {
      result = result.where((item) {
        final json = toJson(item);
        final value = json[filter.field];
        switch (filter.operator) {
          case FilterOperator.equals:
            return value == filter.value;
          case FilterOperator.notEquals:
            return value != filter.value;
          case FilterOperator.greaterThan:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) >
                0;
          case FilterOperator.lessThan:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) <
                0;
          case FilterOperator.whereIn:
            return (filter.value! as List).contains(value);
          case FilterOperator.whereNotIn:
            return !(filter.value! as List).contains(value);
          case FilterOperator.greaterThanOrEquals:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) >=
                0;
          case FilterOperator.lessThanOrEquals:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) <=
                0;
          case FilterOperator.contains:
            return (value as String).contains(filter.value! as String);
          case FilterOperator.startsWith:
            return (value as String).startsWith(filter.value! as String);
          case FilterOperator.endsWith:
            return (value as String).endsWith(filter.value! as String);
          case FilterOperator.isNull:
            return value == null;
          case FilterOperator.isNotNull:
            return value != null;
          case FilterOperator.arrayContains:
            return (value as List).contains(filter.value);
          case FilterOperator.arrayContainsAny:
            final list = value as List;
            return (filter.value! as List).any(list.contains);
        }
      }).toList();
    }
    return result;
  }

  List<T> _applyOrdering(List<T> items, Query<T> query) {
    for (final order in query.orderBy.reversed) {
      items.sort((a, b) {
        final jsonA = toJson(a);
        final jsonB = toJson(b);
        final valueA = jsonA[order.field] as Comparable;
        final valueB = jsonB[order.field] as Comparable;
        final comparison = valueA.compareTo(valueB);
        return order.descending ? -comparison : comparison;
      });
    }
    return items;
  }

  List<T> _applyPagination(List<T> items, Query<T> query) {
    var result = items;
    if (query.offset != null) {
      result = result.skip(query.offset!).toList();
    }
    if (query.limit != null) {
      result = result.take(query.limit!).toList();
    }
    return result;
  }
}

Future<void> main() async {
  log('=== nexus_store Basic Usage Example ===\n');

  // Create the backend and store
  final backend = InMemoryBackend<User, String>(
    getId: (user) => user.id,
    fromJson: User.fromJson,
    toJson: (user) => user.toJson(),
  );

  final userStore = NexusStore<User, String>(
    backend: backend,
    config: StoreConfig.defaults,
  );

  await userStore.initialize();
  log('Store initialized.\n');

  // --- CRUD Operations ---
  log('--- CRUD Operations ---\n');

  // Create
  log('Creating users...');
  await userStore.save(
    User(
      id: '1',
      name: 'Alice',
      email: 'alice@example.com',
      status: 'active',
      age: 28,
    ),
  );
  await userStore.save(
    User(
      id: '2',
      name: 'Bob',
      email: 'bob@example.com',
      status: 'active',
      age: 35,
    ),
  );
  await userStore.save(
    User(
      id: '3',
      name: 'Charlie',
      email: 'charlie@example.com',
      status: 'inactive',
      age: 42,
    ),
  );
  log('Created 3 users.\n');

  // Read single
  final alice = await userStore.get('1');
  log('Get user 1: $alice\n');

  // Read all
  final allUsers = await userStore.getAll();
  log('All users (${allUsers.length}):');
  for (final user in allUsers) {
    log('  - $user');
  }
  log('');

  // Update
  log('Updating Alice...');
  final updatedAlice = alice!.copyWith(status: 'premium', age: 29);
  await userStore.save(updatedAlice);
  final refreshedAlice = await userStore.get('1');
  log('Updated user 1: $refreshedAlice\n');

  // Delete
  log('Deleting Charlie (id: 3)...');
  final deleted = await userStore.delete('3');
  log('Deleted: $deleted');
  final remaining = await userStore.getAll();
  log('Remaining users: ${remaining.length}\n');

  // --- Query Builder ---
  log('--- Query Builder ---\n');

  // Add more users for querying
  await userStore.saveAll([
    User(
      id: '4',
      name: 'Diana',
      email: 'diana@example.com',
      status: 'active',
      age: 25,
    ),
    User(
      id: '5',
      name: 'Eve',
      email: 'eve@example.com',
      status: 'active',
      age: 31,
    ),
    User(
      id: '6',
      name: 'Frank',
      email: 'frank@example.com',
      status: 'inactive',
      age: 45,
    ),
  ]);

  // Filter by status
  final activeUsers = await userStore.getAll(
    query: const Query<User>().where('status', isEqualTo: 'active'),
  );
  log('Active users (${activeUsers.length}):');
  for (final user in activeUsers) {
    log('  - $user');
  }
  log('');

  // Filter with comparison
  final olderUsers = await userStore.getAll(
    query: const Query<User>().where('age', isGreaterThan: 30),
  );
  log('Users older than 30 (${olderUsers.length}):');
  for (final user in olderUsers) {
    log('  - $user');
  }
  log('');

  // Order by age descending
  final orderedUsers = await userStore.getAll(
    query: const Query<User>().orderByField('age', descending: true),
  );
  log('Users ordered by age (descending):');
  for (final user in orderedUsers) {
    log('  - $user');
  }
  log('');

  // Pagination
  final pagedUsers = await userStore.getAll(
    query: const Query<User>().orderByField('name').limitTo(2).offsetBy(1),
  );
  log('Page 2 (2 users, offset 1):');
  for (final user in pagedUsers) {
    log('  - $user');
  }
  log('');

  // Combined query
  final complexQuery = await userStore.getAll(
    query: const Query<User>()
        .where('status', isEqualTo: 'active')
        .where('age', isGreaterThan: 25)
        .orderByField('name')
        .limitTo(3),
  );
  log('Active users > 25 years, sorted by name, limit 3:');
  for (final user in complexQuery) {
    log('  - $user');
  }
  log('');

  // --- Reactive Streams ---
  log('--- Reactive Streams ---\n');

  // Watch all users
  log('Watching all users...');
  final subscription = userStore.watchAll().listen((users) {
    log('  Stream update: ${users.length} users');
  });

  // Give the stream time to emit
  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Watch with query
  log('Watching active users...');
  final activeSubscription = userStore
      .watchAll(query: const Query<User>().where('status', isEqualTo: 'active'))
      .listen((users) {
    log('  Active stream: ${users.length} active users');
  });

  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Watch single user
  log('Watching user 1...');
  final userSubscription = userStore.watch('1').listen((user) {
    log('  User 1 stream: ${user?.name}');
  });

  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Clean up subscriptions
  await subscription.cancel();
  await activeSubscription.cancel();
  await userSubscription.cancel();

  // --- Sync Status ---
  log('\n--- Sync Status ---\n');

  log('Sync status: ${userStore.syncStatus}');
  log('Pending changes: ${await userStore.pendingChangesCount}');

  // Clean up
  await userStore.dispose();
  log('\nStore disposed. Example complete!');
}
