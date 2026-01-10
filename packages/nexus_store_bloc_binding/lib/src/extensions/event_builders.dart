import 'dart:async';

import 'package:nexus_store/nexus_store.dart';

import '../bloc/nexus_store_bloc.dart';
import '../bloc/nexus_store_event.dart';
import '../cubit/nexus_store_cubit.dart';

/// Extension on [NexusStoreCubit] providing helper methods for common patterns.
///
/// ## Example
///
/// ```dart
/// // Debounced loading for search
/// cubit.loadDebounced(
///   query: searchQuery,
///   delay: Duration(milliseconds: 300),
/// );
///
/// // Load with automatic retry on failure
/// await cubit.loadWithRetry(maxRetries: 3);
/// ```
extension NexusStoreCubitX<T, ID> on NexusStoreCubit<T, ID> {
  static final Map<int, Timer?> _debounceTimers = {};

  /// Loads data with debouncing to prevent rapid repeated calls.
  ///
  /// Useful for search-as-you-type scenarios where you don't want to
  /// trigger a load on every keystroke.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // In search text field onChange
  /// cubit.loadDebounced(
  ///   query: Query<User>().where('name').contains(searchText),
  ///   delay: Duration(milliseconds: 300),
  /// );
  /// ```
  void loadDebounced({
    Query<T>? query,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    // Cancel any existing timer for this cubit
    _debounceTimers[hashCode]?.cancel();

    _debounceTimers[hashCode] = Timer(delay, () {
      load(query: query);
      _debounceTimers.remove(hashCode);
    });
  }

  /// Loads data with automatic retry on failure.
  ///
  /// Will retry up to [maxRetries] times with [delay] between attempts.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await cubit.loadWithRetry(
  ///   maxRetries: 3,
  ///   delay: Duration(seconds: 1),
  /// );
  /// ```
  Future<void> loadWithRetry({
    Query<T>? query,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    var attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      await load(query: query);

      // Wait a tick for state to update
      await Future<void>.delayed(Duration.zero);

      // Check if successful
      if (!state.hasError) {
        return;
      }

      // If we have more retries, wait and try again
      if (attempts < maxRetries) {
        await Future<void>.delayed(delay);
      }
    }
  }
}

/// Extension on [NexusStoreBloc] providing helper methods for common patterns.
///
/// ## Example
///
/// ```dart
/// // Debounced event adding
/// bloc.addDebounced(
///   LoadAll<User, String>(query: searchQuery),
///   delay: Duration(milliseconds: 300),
/// );
/// ```
extension NexusStoreBlocX<T, ID> on NexusStoreBloc<T, ID> {
  static final Map<int, Timer?> _debounceTimers = {};

  /// Adds an event with debouncing to prevent rapid repeated additions.
  ///
  /// Useful for search-as-you-type scenarios where you don't want to
  /// trigger a load on every keystroke.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // In search text field onChange
  /// bloc.addDebounced(
  ///   LoadAll<User, String>(query: searchQuery),
  ///   delay: Duration(milliseconds: 300),
  /// );
  /// ```
  void addDebounced(
    NexusStoreEvent<T, ID> event, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    // Cancel any existing timer for this bloc
    _debounceTimers[hashCode]?.cancel();

    _debounceTimers[hashCode] = Timer(delay, () {
      add(event);
      _debounceTimers.remove(hashCode);
    });
  }
}

/// Pre-built event sequences for common operations.
///
/// Use this class to get lists of events for multi-step operations.
///
/// ## Example
///
/// ```dart
/// final sequences = EventSequences<User, String>();
///
/// // Save and then refresh to ensure list is updated
/// for (final event in sequences.saveAndRefresh(user)) {
///   bloc.add(event);
/// }
///
/// // Delete and refresh
/// for (final event in sequences.deleteAndRefresh(userId)) {
///   bloc.add(event);
/// }
/// ```
class EventSequences<T, ID> {
  /// Creates event sequences for the given types.
  const EventSequences();

  /// Creates a save followed by refresh sequence.
  ///
  /// Useful when you want to ensure the list is refreshed after saving.
  List<NexusStoreEvent<T, ID>> saveAndRefresh(T item) {
    return [
      Save<T, ID>(item),
      Refresh<T, ID>(),
    ];
  }

  /// Creates a delete followed by refresh sequence.
  ///
  /// Useful when you want to ensure the list is refreshed after deleting.
  List<NexusStoreEvent<T, ID>> deleteAndRefresh(ID id) {
    return [
      Delete<T, ID>(id),
      Refresh<T, ID>(),
    ];
  }

  /// Creates a batch save followed by refresh sequence.
  ///
  /// Useful when saving multiple items and refreshing the list.
  List<NexusStoreEvent<T, ID>> batchSave(List<T> items) {
    return [
      SaveAll<T, ID>(items),
      Refresh<T, ID>(),
    ];
  }

  /// Creates a batch delete followed by refresh sequence.
  ///
  /// Useful when deleting multiple items and refreshing the list.
  List<NexusStoreEvent<T, ID>> batchDelete(List<ID> ids) {
    return [
      DeleteAll<T, ID>(ids),
      Refresh<T, ID>(),
    ];
  }
}
