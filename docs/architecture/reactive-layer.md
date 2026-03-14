# Reactive Layer

The reactive layer provides real-time data updates using RxDart streams.

## Overview

nexus_store uses RxDart's `BehaviorSubject` for its reactive streams. This provides:

- **Immediate value on subscribe** - New subscribers get the current value immediately
- **Continuous updates** - Subsequent changes are pushed to all subscribers
- **Replay capability** - Late subscribers don't miss the current state

## BehaviorSubject vs Regular Streams

### Regular Stream
```dart
// Subscriber gets nothing until next emit
stream.listen((data) => print(data));
```

### BehaviorSubject (used by nexus_store)
```dart
// Subscriber immediately gets current value
subject.stream.listen((data) => print(data));  // Prints current value NOW
```

## Watch Methods

### watch(id)

Watch a single entity for changes:

```dart
userStore.watch('user-123').listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  } else {
    print('User not found or deleted');
  }
});
```

- Returns `Stream<T?>` - nullable because entity might not exist
- Emits immediately with current value
- Emits on every update to the entity
- Emits `null` if entity is deleted

### watchAll(query)

Watch all entities matching a query:

```dart
userStore.watchAll(
  query: Query<User>()
    .where('status', isEqualTo: 'active')
    .orderBy('name'),
).listen((users) {
  print('Active users: ${users.length}');
});
```

- Returns `Stream<List<T>>` - always a list
- Emits immediately with current matching entities
- Emits when any entity is added, updated, or deleted

## Sync Status Stream

Monitor synchronization state:

```dart
store.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.synced:
      showSnackBar('All changes saved');
    case SyncStatus.syncing:
      showSnackBar('Syncing...');
    case SyncStatus.pending:
      showSnackBar('Changes pending');
    case SyncStatus.error:
      showSnackBar('Sync failed');
    case SyncStatus.paused:
      showSnackBar('Sync paused');
    case SyncStatus.conflict:
      showSnackBar('Conflict detected');
  }
});
```

## ReactiveStoreMixin

The `ReactiveStoreMixin` provides reactive state management:

```dart
// Create reactive state
final state = createReactiveState<User?>(null);

// Update state
state.value = newUser;

// Or transform current value
state.update((current) => current?.copyWith(name: 'New Name'));

// Subscribe to changes
state.stream.listen((user) => print(user));

// Dispose when done
await state.dispose();
```

### ReactiveList

Specialized reactive collection for lists:

```dart
final list = ReactiveList<User>([]);

// Modifications
list.add(user);
list.remove(user);
list.removeAt(0);
list.clear();

// Properties
list.length;
list.isEmpty;
list[0];

// Stream updates
list.stream.listen((users) => print(users));
```

### ReactiveMap

Specialized reactive collection for maps:

```dart
final map = ReactiveMap<String, User>({});

// Modifications
map.set('user-1', user);
map.remove('user-1');
map.clear();

// Properties
map['user-1'];
map.containsKey('user-1');

// Stream updates
map.stream.listen((users) => print(users));
```

## Flutter Integration

### NexusStoreBuilder

Automatically subscribes to `watchAll`:

```dart
NexusStoreBuilder<User, String>(
  store: userStore,
  query: Query<User>().where('isActive', isEqualTo: true),
  builder: (context, users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, i) => Text(users[i].name),
  ),
)
```

### NexusStoreItemBuilder

Automatically subscribes to `watch`:

```dart
NexusStoreItemBuilder<User, String>(
  store: userStore,
  id: 'user-123',
  builder: (context, user) => user != null
    ? Text(user.name)
    : Text('Not found'),
)
```

### StoreResultStreamBuilder

Build UI from any stream:

```dart
StoreResultStreamBuilder<List<User>>(
  stream: customStream,
  builder: (context, users) => ListView(...),
)
```

## Stream Operators

Combine nexus_store streams with RxDart operators:

```dart
import 'package:rxdart/rxdart.dart';

// Debounce rapid updates
userStore.watchAll()
  .debounceTime(Duration(milliseconds: 300))
  .listen((users) => updateUI(users));

// Combine multiple streams
Rx.combineLatest2(
  userStore.watch('user-1'),
  postStore.watchAll(query: Query<Post>().where('userId', isEqualTo: 'user-1')),
  (user, posts) => UserWithPosts(user, posts),
).listen((data) => updateUI(data));

// Filter out null values
userStore.watch('user-1')
  .whereType<User>()
  .listen((user) => print(user.name));  // Only non-null users
```

## Performance Considerations

1. **Subscription cleanup** - Always cancel subscriptions when widgets dispose
2. **Query specificity** - More specific queries mean fewer updates
3. **Debouncing** - Use `debounceTime` for high-frequency updates
4. **Distinctness** - Backend should only emit when data actually changes

## Error Handling in Streams

```dart
userStore.watchAll().listen(
  (users) => updateUI(users),
  onError: (error) => showError(error),
);

// Or with StreamBuilder error handling
StreamBuilder<List<User>>(
  stream: userStore.watchAll(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    return UserList(users: snapshot.data!);
  },
)
```

## Best Practices

1. **Use watch for single items** - More efficient than watchAll for single entities
2. **Apply queries in watchAll** - Filter at the source, not in the UI
3. **Handle loading states** - Streams may not emit immediately for network-first policies
4. **Dispose subscriptions** - Use StatefulWidget lifecycle or StreamSubscription.cancel()
5. **Consider offline state** - Streams work offline but may have stale data

## See Also

- [Architecture Overview](overview.md)
- [Flutter Extension README](../../packages/nexus_store_flutter_widgets/README.md)
