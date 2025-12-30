import 'dart:async';

import 'package:nexus_store/nexus_store.dart';
import 'package:signals/signals.dart';

import '../state/nexus_item_signal_state.dart';
import '../state/nexus_signal_state.dart';

/// Extension on [NexusStore] to provide signal-based reactive access.
extension NexusStoreSignalExtension<T, ID> on NexusStore<T, ID> {
  /// Converts the store's watchAll stream to a [Signal].
  ///
  /// Returns a signal that automatically updates when the store emits
  /// new data. The signal starts with an empty list and updates as
  /// data arrives.
  ///
  /// Example:
  /// ```dart
  /// final userStore = NexusStore<User, String>(backend: backend);
  /// final usersSignal = userStore.toSignal();
  ///
  /// Watch((context) {
  ///   final users = usersSignal.value;
  ///   return ListView(children: users.map((u) => UserTile(u)).toList());
  /// });
  /// ```
  Signal<List<T>> toSignal({Query<T>? query}) {
    final signal = Signal<List<T>>(<T>[]);
    StreamSubscription<List<T>>? subscription;

    subscription = watchAll(query: query).listen(
      (data) => signal.value = data,
      onError: (Object error) {
        // Errors are silently ignored in basic signal mode
        // Use toStateSignal() for error handling
      },
    );

    // Register cleanup when signal is disposed
    signal.onDispose(() {
      subscription?.cancel();
    });

    return signal;
  }

  /// Converts the store's watch stream for a single item to a [Signal].
  ///
  /// Returns a signal that automatically updates when the watched item
  /// changes. The signal starts with null and updates when data arrives.
  ///
  /// Example:
  /// ```dart
  /// final currentUserSignal = userStore.toItemSignal(currentUserId);
  ///
  /// Watch((context) {
  ///   final user = currentUserSignal.value;
  ///   return user != null ? UserCard(user) : NotFoundWidget();
  /// });
  /// ```
  Signal<T?> toItemSignal(ID id) {
    final signal = Signal<T?>(null);
    StreamSubscription<T?>? subscription;

    subscription = watch(id).listen(
      (data) => signal.value = data,
      onError: (Object error) {
        // Errors are silently ignored in basic signal mode
        // Use toItemStateSignal() for error handling
      },
    );

    // Register cleanup when signal is disposed
    signal.onDispose(() {
      subscription?.cancel();
    });

    return signal;
  }

  /// Converts the store's watchAll stream to a state-aware [Signal].
  ///
  /// Returns a signal of [NexusSignalState] that tracks loading, data,
  /// and error states. This is useful for showing loading indicators
  /// and error messages.
  ///
  /// Example:
  /// ```dart
  /// final usersStateSignal = userStore.toStateSignal();
  ///
  /// Watch((context) {
  ///   return usersStateSignal.value.when(
  ///     initial: () => Text('Ready'),
  ///     loading: (prev) => Column(children: [
  ///       if (prev != null) UserList(users: prev),
  ///       CircularProgressIndicator(),
  ///     ]),
  ///     data: (users) => UserList(users: users),
  ///     error: (e, st, prev) => ErrorWidget(e),
  ///   );
  /// });
  /// ```
  Signal<NexusSignalState<T>> toStateSignal({Query<T>? query}) {
    final signal = Signal<NexusSignalState<T>>(const NexusSignalInitial());
    StreamSubscription<List<T>>? subscription;
    List<T>? previousData;

    subscription = watchAll(query: query).listen(
      (data) {
        previousData = data;
        signal.value = NexusSignalData(data: data);
      },
      onError: (Object error, StackTrace stackTrace) {
        signal.value = NexusSignalError(
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        );
      },
    );

    // Register cleanup when signal is disposed
    signal.onDispose(() {
      subscription?.cancel();
    });

    return signal;
  }

  /// Converts the store's watch stream for a single item to a state-aware [Signal].
  ///
  /// Returns a signal of [NexusItemSignalState] that tracks loading, data,
  /// not found, and error states.
  ///
  /// Example:
  /// ```dart
  /// final userStateSignal = userStore.toItemStateSignal(userId);
  ///
  /// Watch((context) {
  ///   return userStateSignal.value.when(
  ///     initial: () => Text('Ready'),
  ///     loading: (prev) => CircularProgressIndicator(),
  ///     data: (user) => UserCard(user),
  ///     notFound: () => Text('User not found'),
  ///     error: (e, st, prev) => ErrorWidget(e),
  ///   );
  /// });
  /// ```
  Signal<NexusItemSignalState<T>> toItemStateSignal(ID id) {
    final signal = Signal<NexusItemSignalState<T>>(const NexusItemSignalInitial());
    StreamSubscription<T?>? subscription;
    T? previousData;

    subscription = watch(id).listen(
      (data) {
        if (data == null) {
          signal.value = const NexusItemSignalNotFound();
        } else {
          previousData = data;
          signal.value = NexusItemSignalData(data: data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        signal.value = NexusItemSignalError(
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        );
      },
    );

    // Register cleanup when signal is disposed
    signal.onDispose(() {
      subscription?.cancel();
    });

    return signal;
  }
}
