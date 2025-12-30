import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nexus_store/nexus_store.dart';

import '../state/nexus_item_state.dart';
import 'nexus_item_event.dart';

/// A Bloc that wraps a single item from a [NexusStore] and provides
/// event-driven state management.
///
/// This bloc subscribes to `watch(id)` when [LoadItem] is added and
/// emits [NexusItemState] changes as the item changes in the store.
///
/// Example:
/// ```dart
/// class UserBloc extends NexusItemBloc<User, String> {
///   UserBloc(NexusStore<User, String> store, String userId)
///       : super(store, userId);
/// }
///
/// // Usage
/// final bloc = UserBloc(userStore, 'user-123');
/// bloc.add(const LoadItem());
///
/// // In widget
/// BlocBuilder<UserBloc, NexusItemState<User>>(
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
class NexusItemBloc<T, ID>
    extends Bloc<NexusItemEvent<T, ID>, NexusItemState<T>> {
  /// Creates a bloc that watches a single item from the given [NexusStore].
  NexusItemBloc(this._store, this._id) : super(const NexusItemInitial()) {
    on<LoadItem<T, ID>>(_onLoadItem);
    on<SaveItem<T, ID>>(_onSaveItem);
    on<DeleteItem<T, ID>>(_onDeleteItem);
    on<RefreshItem<T, ID>>(_onRefreshItem);
    on<ItemDataReceived<T, ID>>(_onItemDataReceived);
    on<ItemErrorReceived<T, ID>>(_onItemErrorReceived);
  }

  final NexusStore<T, ID> _store;
  final ID _id;
  StreamSubscription<T?>? _subscription;

  /// The ID of the item being watched.
  ID get id => _id;

  /// Exposes the underlying store for direct access when needed.
  NexusStore<T, ID> get store => _store;

  Future<void> _onLoadItem(
    LoadItem<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) async {
    await _cancelSubscription();

    // Get previous data for optimistic UI
    final previousData = state.dataOrNull;
    emit(NexusItemLoading<T>(previousData: previousData));

    _subscription = _store.watch(_id).listen(
      (data) {
        add(ItemDataReceived<T, ID>(data));
      },
      onError: (Object error, StackTrace stackTrace) {
        add(ItemErrorReceived<T, ID>(error, stackTrace));
      },
    );
  }

  Future<void> _onSaveItem(
    SaveItem<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) async {
    try {
      await _store.save(event.item, policy: event.policy, tags: event.tags);
    } catch (error, stackTrace) {
      emit(NexusItemError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onDeleteItem(
    DeleteItem<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) async {
    try {
      await _store.delete(_id, policy: event.policy);
    } catch (error, stackTrace) {
      emit(NexusItemError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onRefreshItem(
    RefreshItem<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) async {
    add(const LoadItem());
  }

  void _onItemDataReceived(
    ItemDataReceived<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) {
    if (event.data == null) {
      emit(const NexusItemNotFound());
    } else {
      emit(NexusItemLoaded<T>(data: event.data as T));
    }
  }

  void _onItemErrorReceived(
    ItemErrorReceived<T, ID> event,
    Emitter<NexusItemState<T>> emit,
  ) {
    emit(NexusItemError<T>(
      error: event.error,
      stackTrace: event.stackTrace,
      previousData: state.dataOrNull,
    ));
  }

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
