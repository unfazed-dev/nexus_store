/// Flutter widgets example for nexus_store.
///
/// This example demonstrates:
/// - NexusStoreProvider for dependency injection
/// - NexusStoreBuilder for reactive lists
/// - NexusStoreItemBuilder for single items
/// - StoreResultBuilder for state handling
/// - Loading and error states
library;

import 'package:flutter/material.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

// ============================================================================
// Model
// ============================================================================

/// Simple Task model for the example.
class Task {
  /// Creates a new Task with the given properties.
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  /// Creates a Task from a JSON map.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        isCompleted: json['isCompleted'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// The unique identifier for this task.
  final String id;

  /// The title of the task.
  final String title;

  /// A detailed description of the task.
  final String description;

  /// Whether the task has been completed.
  final bool isCompleted;

  /// When the task was created.
  final DateTime createdAt;

  /// Converts this Task to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Creates a copy of this Task with the given fields replaced.
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
      );
}

// ============================================================================
// In-Memory Backend
// ============================================================================

/// Simple in-memory backend for demonstration.
class InMemoryBackend<T, ID>
    with StoreBackendDefaults<T, ID>
    implements StoreBackend<T, ID> {
  /// Creates an in-memory backend with the required serialization functions.
  InMemoryBackend({
    required this.getId,
    required this.fromJson,
    required this.toJson,
  });

  /// Function to extract the ID from an entity.
  final ID Function(T) getId;

  /// Function to deserialize an entity from JSON.
  // ignore: unreachable_from_main
  final T Function(Map<String, dynamic>) fromJson;

  /// Function to serialize an entity to JSON.
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
          case FilterOperator.greaterThanOrEquals:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) >=
                0;
          case FilterOperator.lessThanOrEquals:
            return (value as Comparable)
                    .compareTo(filter.value! as Comparable) <=
                0;
          case FilterOperator.whereIn:
            return (filter.value! as List).contains(value);
          case FilterOperator.whereNotIn:
            return !(filter.value! as List).contains(value);
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
    var result = items;
    for (final order in query.orderBy.reversed) {
      result = List.from(result)
        ..sort((a, b) {
          final jsonA = toJson(a);
          final jsonB = toJson(b);
          final valueA = jsonA[order.field] as Comparable;
          final valueB = jsonB[order.field] as Comparable;
          final comparison = valueA.compareTo(valueB);
          return order.descending ? -comparison : comparison;
        });
    }
    return result;
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

// ============================================================================
// App Entry Point
// ============================================================================

/// Global task store instance for the example app.
late NexusStore<Task, String> taskStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the backend and store
  final backend = InMemoryBackend<Task, String>(
    getId: (task) => task.id,
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );

  taskStore = NexusStore<Task, String>(
    backend: backend,
    config: StoreConfig.defaults,
  );

  await taskStore.initialize();

  // Add some sample data
  await taskStore.saveAll([
    Task(
      id: '1',
      title: 'Learn nexus_store',
      description: 'Read the documentation and try the examples',
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Task(
      id: '2',
      title: 'Build an app',
      description: 'Create a Flutter app using nexus_store',
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Task(
      id: '3',
      title: 'Deploy to production',
      description: 'Ship the app to users',
      isCompleted: false,
      createdAt: DateTime.now(),
    ),
  ]);

  runApp(
    NexusStoreProvider<Task, String>(
      store: taskStore,
      child: const TaskApp(),
    ),
  );
}

// ============================================================================
// App Widget
// ============================================================================

/// Main application widget that sets up MaterialApp with theme and home screen.
class TaskApp extends StatelessWidget {
  /// Creates the TaskApp widget.
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'nexus_store Flutter Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const TaskListScreen(),
      );
}

// ============================================================================
// Task List Screen - Using NexusStoreBuilder
// ============================================================================

/// Main screen showing a list of tasks with filter options.
class TaskListScreen extends StatefulWidget {
  /// Creates the TaskListScreen widget.
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          actions: [
            IconButton(
              icon: Icon(
                _showCompleted ? Icons.visibility : Icons.visibility_off,
              ),
              tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
              onPressed: () => setState(() => _showCompleted = !_showCompleted),
            ),
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'StoreResult Example',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StoreResultExample(),
                ),
              ),
            ),
          ],
        ),
        body: NexusStoreBuilder<Task, String>(
          store: context.nexusStore<Task, String>(),
          query: _showCompleted
              ? null
              : const Query<Task>().where('isCompleted', isEqualTo: false),
          builder: (context, tasks) {
            if (tasks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('No tasks', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskListTile(
                  task: task,
                  onTap: () => _navigateToDetail(context, task.id),
                  onToggle: () => _toggleTask(task),
                  onDelete: () => _deleteTask(task.id),
                );
              },
            );
          },
          loading: const Center(child: CircularProgressIndicator()),
          error: (context, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addTask(context),
          child: const Icon(Icons.add),
        ),
      );

  void _navigateToDetail(BuildContext context, String taskId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailScreen(taskId: taskId),
      ),
    );
  }

  Future<void> _toggleTask(Task task) async {
    final store = context.nexusStore<Task, String>();
    await store.save(task.copyWith(isCompleted: !task.isCompleted));
    if (mounted) setState(() {});
  }

  Future<void> _deleteTask(String id) async {
    final store = context.nexusStore<Task, String>();
    await store.delete(id);
    if (mounted) setState(() {});
  }

  Future<void> _addTask(BuildContext context) async {
    final store = context.nexusStore<Task, String>();
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Task ${DateTime.now().second}',
      description: 'Description for the new task',
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await store.save(newTask);
    if (mounted) setState(() {});
  }
}

// ============================================================================
// Task List Tile
// ============================================================================

/// A list tile widget for displaying a single task with actions.
class TaskListTile extends StatelessWidget {
  /// Creates a TaskListTile with the required callbacks.
  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  /// The task to display.
  final Task task;

  /// Callback when the tile is tapped.
  final VoidCallback onTap;

  /// Callback when the completion status is toggled.
  final VoidCallback onToggle;

  /// Callback when the delete button is pressed.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: task.isCompleted ? Colors.green : null,
          ),
          onPressed: onToggle,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
      );
}

// ============================================================================
// Task Detail Screen - Using NexusStoreItemBuilder
// ============================================================================

/// Screen showing the details of a single task.
class TaskDetailScreen extends StatelessWidget {
  /// Creates a TaskDetailScreen for the given task ID.
  const TaskDetailScreen({super.key, required this.taskId});

  /// The ID of the task to display.
  final String taskId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: NexusStoreItemBuilder<Task, String>(
          store: context.nexusStore<Task, String>(),
          id: taskId,
          builder: (context, task) {
            if (task == null) {
              return const Center(
                child: Text('Task not found'),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(task.isCompleted ? 'Completed' : 'Pending'),
                    backgroundColor: task.isCompleted
                        ? Colors.green[100]
                        : Colors.orange[100],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(task.description),
                  const SizedBox(height: 16),
                  Text(
                    'Created: ${task.createdAt.toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
          loading: const Center(child: CircularProgressIndicator()),
          error: (context, error) => Center(child: Text('Error: $error')),
        ),
      );
}

// ============================================================================
// StoreResult Example Widget
// ============================================================================

/// Example showing how to use StoreResultBuilder for manual state handling.
class StoreResultExample extends StatefulWidget {
  /// Creates the StoreResultExample widget.
  const StoreResultExample({super.key});

  @override
  State<StoreResultExample> createState() => _StoreResultExampleState();
}

class _StoreResultExampleState extends State<StoreResultExample> {
  StoreResult<List<Task>> _result = const StoreResult.idle();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _result = const StoreResult.pending());

    try {
      final tasks = await taskStore.getAll();
      setState(() => _result = StoreResult.success(tasks));
    } on Exception catch (e) {
      setState(() => _result = StoreResult.error(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('StoreResult Example'),
        ),
        body: StoreResultBuilder<List<Task>>(
          result: _result,
          builder: (context, tasks) => ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(tasks[index].title),
            ),
          ),
          idle: (context) => const Center(
            child: Text('Tap the refresh button to load tasks'),
          ),
          pending: (context, previousTasks) => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (context, error, previousTasks) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTasks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadTasks,
          child: const Icon(Icons.refresh),
        ),
      );
}
