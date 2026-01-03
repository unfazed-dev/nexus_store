/// Complete integration example for nexus_store.
///
/// This example demonstrates the full integration stack:
/// - **Core**: NexusStore for unified data operations
/// - **Backend**: InMemoryBackend (can swap for Drift/PowerSync/Supabase)
/// - **Binding**: Riverpod for state management
/// - **Widgets**: nexus_store_flutter_widgets for reactive UI
///
/// This pattern is recommended for production Flutter apps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_store/nexus_store.dart';
// nexus_store_flutter_widgets provides StoreResultBuilder, etc.
// This example uses Riverpod's AsyncValue directly instead.
// ignore: unused_import
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';
import 'package:nexus_store_riverpod_binding/nexus_store_riverpod_binding.dart';

// ============================================================================
// 1. MODEL - Define your data model
// ============================================================================

/// A Todo item with title, description, and completion status.
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  Todo copyWith({String? title, String? description, bool? isCompleted}) =>
      Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
      );
}

// ============================================================================
// 2. BACKEND - In-memory for demo (swap for Drift/PowerSync/Supabase)
// ============================================================================

/// Simple in-memory backend for demonstration.
/// In production, replace with DriftBackend, PowerSyncBackend, etc.
class InMemoryBackend<T, ID>
    with StoreBackendDefaults<T, ID>
    implements StoreBackend<T, ID> {
  InMemoryBackend({
    required this.getId,
    required this.toJson,
  });

  final ID Function(T) getId;
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
  Future<List<T>> getAll({Query<T>? query}) async => _data.values.toList();
  @override
  Stream<T?> watch(ID id) async* {
    yield _data[id];
  }

  @override
  Stream<List<T>> watchAll({Query<T>? query}) async* {
    yield _data.values.toList();
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
  Future<int> deleteWhere(Query<T> query) async => 0;
}

// ============================================================================
// 3. RIVERPOD PROVIDERS - State management with Riverpod
// ============================================================================

/// Provider for the todo store.
final todoStoreProvider = Provider<NexusStore<Todo, String>>((ref) {
  final backend = InMemoryBackend<Todo, String>(
    getId: (todo) => todo.id,
    toJson: (todo) => todo.toJson(),
  );

  final store = NexusStore<Todo, String>(
    backend: backend,
    config: StoreConfig(fetchPolicy: FetchPolicy.cacheFirst),
  );

  // Initialize store and bind lifecycle
  store.initialize();
  store.bindToRef(ref);

  return store;
});

/// Stream provider for all todos (reactive updates).
final todosProvider = StreamProvider<List<Todo>>((ref) {
  final store = ref.watch(todoStoreProvider);
  return store.watchAll();
});

/// Stream provider for a single todo by ID.
final todoByIdProvider =
    StreamProvider.family<Todo?, String>((ref, String id) {
  final store = ref.watch(todoStoreProvider);
  return store.watch(id);
});

/// Computed provider for completed todos count.
final completedCountProvider = Provider<int>((ref) {
  final todosAsync = ref.watch(todosProvider);
  return todosAsync.maybeWhen(
    data: (todos) => todos.where((t) => t.isCompleted).length,
    orElse: () => 0,
  );
});

// ============================================================================
// 4. APP ENTRY POINT
// ============================================================================

void main() {
  runApp(const ProviderScope(child: TodoApp()));
}

/// Main application widget.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nexus_store Complete Integration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

// ============================================================================
// 5. UI - Todo List Screen with Riverpod + NexusStore
// ============================================================================

/// Main screen showing the todo list.
class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosProvider);
    final completedCount = ref.watch(completedCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Chip(
                label: Text('$completedCount done'),
                backgroundColor: Colors.green[100],
              ),
            ),
          ),
        ],
      ),
      body: todosAsync.when(
        data: (todos) => todos.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) => TodoTile(todo: todos[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodo(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTodo(BuildContext context, WidgetRef ref) async {
    final store = ref.read(todoStoreProvider);
    await store.save(
      Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Todo ${DateTime.now().second}',
        description: 'Created at ${DateTime.now()}',
      ),
    );
  }
}

/// Empty state widget when no todos exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No todos yet', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Tap + to add one', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Individual todo tile with toggle and delete actions.
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final store = ref.read(todoStoreProvider);
        await store.delete(todo.id);
      },
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => _toggleComplete(ref),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: todo.description.isNotEmpty ? Text(todo.description) : null,
      ),
    );
  }

  Future<void> _toggleComplete(WidgetRef ref) async {
    final store = ref.read(todoStoreProvider);
    await store.save(todo.copyWith(isCompleted: !todo.isCompleted));
  }
}
