import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexus_store/nexus_store.dart';

import '../state/nexus_item_state.dart';

/// A Cubit that wraps a single item from a [NexusStore] and provides reactive
/// state management.
///
/// This cubit auto-subscribes to `watch(id)` when [load] is called and
/// emits [NexusItemState] changes as the item changes in the store.
///
/// Example:
/// ```dart
/// class UserCubit extends NexusItemCubit<User, String> {
///   UserCubit(NexusStore<User, String> store, String userId)
///       : super(store, userId);
/// }
///
/// // Usage
/// final cubit = UserCubit(userStore, 'user-123');
/// await cubit.load();
///
/// // In widget
/// BlocBuilder<UserCubit, NexusItemState<User>>(
///   builder: (context, state) {
///     return state.when(
///       initial: () => Text('Press load'),
///       loading: (prev) => CircularProgressIndicator(),
///       loaded: (user) => UserCard(user: user),
///       notFound: () => Text('User not found'),
///       error: (e, st, prev) => ErrorWidget(e),
///     );
///   },
/// );
/// ```
class NexusItemCubit<T, ID> extends Cubit<NexusItemState<T>> {
  /// Creates a cubit that watches a single item from the given [NexusStore].
  NexusItemCubit(this._store, this._id) : super(const NexusItemInitial());

  final NexusStore<T, ID> _store;
  final ID _id;
  StreamSubscription<T?>? _subscription;

  /// The ID of the item being watched.
  ID get id => _id;

  /// Exposes the underlying store for direct access when needed.
  NexusStore<T, ID> get store => _store;

  /// Loads the item by subscribing to [NexusStore.watch].
  ///
  /// If a subscription already exists, it will be cancelled first.
  /// The cubit will emit [NexusItemLoading] immediately, then
  /// [NexusItemLoaded] when data arrives, [NexusItemNotFound] if the item
  /// doesn't exist, or [NexusItemError] on failure.
  Future<void> load() async {
    await _cancelSubscription();

    // Get previous data for optimistic UI
    final previousData = state.dataOrNull;
    emit(NexusItemLoading<T>(previousData: previousData));

    _subscription = _store.watch(_id).listen(
      (data) {
        if (data == null) {
          emit(const NexusItemNotFound());
        } else {
          emit(NexusItemLoaded<T>(data: data));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(NexusItemError<T>(
          error: error,
          stackTrace: stackTrace,
          previousData: state.dataOrNull,
        ));
      },
    );
  }

  /// Saves the item to the store.
  ///
  /// Calls [onSave] before saving for custom logic.
  /// Emits [NexusItemError] on failure with previous data preserved.
  Future<T> save(T item, {WritePolicy? policy, Set<String>? tags}) async {
    onSave(item);
    try {
      return await _store.save(item, policy: policy, tags: tags);
    } catch (error, stackTrace) {
      emit(NexusItemError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
      rethrow;
    }
  }

  /// Deletes the item from the store using the cubit's [id].
  ///
  /// Calls [onDelete] before deleting for custom logic.
  /// Emits [NexusItemError] on failure with previous data preserved.
  Future<bool> delete({WritePolicy? policy}) async {
    onDelete();
    try {
      return await _store.delete(_id, policy: policy);
    } catch (error, stackTrace) {
      emit(NexusItemError<T>(
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
    await load();
  }

  /// Override this method to add custom logic before saving an item.
  @protected
  void onSave(T item) {}

  /// Override this method to add custom logic before deleting the item.
  @protected
  void onDelete() {}

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
