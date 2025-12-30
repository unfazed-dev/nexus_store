import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexus_store/nexus_store.dart';

import '../state/nexus_store_state.dart';

/// A Cubit that wraps a [NexusStore] and provides reactive state management.
///
/// This cubit auto-subscribes to `watchAll()` when [load] is called and
/// emits [NexusStoreState] changes as data flows through the store.
///
/// Example:
/// ```dart
/// class UsersCubit extends NexusStoreCubit<User, String> {
///   UsersCubit(NexusStore<User, String> store) : super(store);
/// }
///
/// // Usage
/// final cubit = UsersCubit(userStore);
/// await cubit.load();
///
/// // In widget
/// BlocBuilder<UsersCubit, NexusStoreState<User>>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => Text('Press load'),
///       loading: (prev) => CircularProgressIndicator(),
///       loaded: (users) => UserList(users: users),
///       error: (e, st, prev) => ErrorWidget(e),
///     );
///   },
/// );
/// ```
class NexusStoreCubit<T, ID> extends Cubit<NexusStoreState<T>> {
  /// Creates a cubit that wraps the given [NexusStore].
  NexusStoreCubit(this._store) : super(const NexusStoreInitial());

  final NexusStore<T, ID> _store;
  StreamSubscription<List<T>>? _subscription;
  Query<T>? _currentQuery;

  /// Exposes the underlying store for direct access when needed.
  NexusStore<T, ID> get store => _store;

  /// Loads data by subscribing to [NexusStore.watchAll].
  ///
  /// If a subscription already exists, it will be cancelled first.
  /// The cubit will emit [NexusStoreLoading] immediately, then
  /// [NexusStoreLoaded] when data arrives or [NexusStoreError] on failure.
  ///
  /// Optional [query] can be provided to filter/sort the results.
  Future<void> load({Query<T>? query}) async {
    await _cancelSubscription();
    _currentQuery = query;

    // Get previous data for optimistic UI
    final previousData = state.dataOrNull;
    emit(NexusStoreLoading<T>(previousData: previousData));

    _subscription = _store.watchAll(query: query).listen(
      (data) {
        emit(NexusStoreLoaded<T>(data: data));
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(NexusStoreError<T>(
          error: error,
          stackTrace: stackTrace,
          previousData: state.dataOrNull,
        ));
      },
    );
  }

  /// Saves an item to the store.
  ///
  /// Calls [onSave] before saving for custom logic.
  /// Emits [NexusStoreError] on failure with previous data preserved.
  Future<T> save(T item, {WritePolicy? policy, Set<String>? tags}) async {
    onSave(item);
    try {
      return await _store.save(item, policy: policy, tags: tags);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
      rethrow;
    }
  }

  /// Saves multiple items to the store.
  ///
  /// Emits [NexusStoreError] on failure with previous data preserved.
  Future<List<T>> saveAll(
    List<T> items, {
    WritePolicy? policy,
    Set<String>? tags,
  }) async {
    try {
      return await _store.saveAll(items, policy: policy, tags: tags);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
      rethrow;
    }
  }

  /// Deletes an item from the store by ID.
  ///
  /// Calls [onDelete] before deleting for custom logic.
  /// Emits [NexusStoreError] on failure with previous data preserved.
  Future<bool> delete(ID id, {WritePolicy? policy}) async {
    onDelete(id);
    try {
      return await _store.delete(id, policy: policy);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
      rethrow;
    }
  }

  /// Deletes multiple items from the store by IDs.
  ///
  /// Emits [NexusStoreError] on failure with previous data preserved.
  Future<int> deleteAll(List<ID> ids, {WritePolicy? policy}) async {
    try {
      return await _store.deleteAll(ids, policy: policy);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
      rethrow;
    }
  }

  /// Refreshes the data by re-subscribing to the store.
  ///
  /// Cancels the current subscription and loads fresh data.
  Future<void> refresh() async {
    await load(query: _currentQuery);
  }

  /// Override this method to add custom logic before saving an item.
  @protected
  void onSave(T item) {}

  /// Override this method to add custom logic before deleting an item.
  @protected
  void onDelete(ID id) {}

  Future<void> _cancelSubscription() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscription();
    return super.close();
  }
}
