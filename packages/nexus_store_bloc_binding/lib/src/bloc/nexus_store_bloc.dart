import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nexus_store/nexus_store.dart';

import '../state/nexus_store_state.dart';
import 'nexus_store_event.dart';

/// A Bloc that wraps a [NexusStore] and provides event-driven state management.
///
/// This bloc subscribes to `watchAll()` when [LoadAll] is added and
/// emits [NexusStoreState] changes as data flows through the store.
///
/// Example:
/// ```dart
/// class UsersBloc extends NexusStoreBloc<User, String> {
///   UsersBloc(NexusStore<User, String> store) : super(store);
/// }
///
/// // Usage
/// final bloc = UsersBloc(userStore);
/// bloc.add(const LoadAll());
///
/// // In widget
/// BlocBuilder<UsersBloc, NexusStoreState<User>>(
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
class NexusStoreBloc<T, ID>
    extends Bloc<NexusStoreEvent<T, ID>, NexusStoreState<T>> {
  /// Creates a bloc that wraps the given [NexusStore].
  NexusStoreBloc(this._store) : super(const NexusStoreInitial()) {
    on<LoadAll<T, ID>>(_onLoadAll);
    on<Save<T, ID>>(_onSave);
    on<SaveAll<T, ID>>(_onSaveAll);
    on<Delete<T, ID>>(_onDelete);
    on<DeleteAll<T, ID>>(_onDeleteAll);
    on<Refresh<T, ID>>(_onRefresh);
    on<DataReceived<T, ID>>(_onDataReceived);
    on<ErrorReceived<T, ID>>(_onErrorReceived);
  }

  final NexusStore<T, ID> _store;
  StreamSubscription<List<T>>? _subscription;
  Query<T>? _currentQuery;

  /// Exposes the underlying store for direct access when needed.
  NexusStore<T, ID> get store => _store;

  Future<void> _onLoadAll(
    LoadAll<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    await _cancelSubscription();
    _currentQuery = event.query;

    // Get previous data for optimistic UI
    final previousData = state.dataOrNull;
    emit(NexusStoreLoading<T>(previousData: previousData));

    _subscription = _store.watchAll(query: event.query).listen(
      (data) {
        add(DataReceived<T, ID>(data));
      },
      onError: (Object error, StackTrace stackTrace) {
        add(ErrorReceived<T, ID>(error, stackTrace));
      },
    );
  }

  Future<void> _onSave(
    Save<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    try {
      await _store.save(event.item, policy: event.policy, tags: event.tags);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onSaveAll(
    SaveAll<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    try {
      await _store.saveAll(event.items, policy: event.policy, tags: event.tags);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onDelete(
    Delete<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    try {
      await _store.delete(event.id, policy: event.policy);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onDeleteAll(
    DeleteAll<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    try {
      await _store.deleteAll(event.ids, policy: event.policy);
    } catch (error, stackTrace) {
      emit(NexusStoreError<T>(
        error: error,
        stackTrace: stackTrace,
        previousData: state.dataOrNull,
      ));
    }
  }

  Future<void> _onRefresh(
    Refresh<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) async {
    add(LoadAll<T, ID>(query: _currentQuery));
  }

  void _onDataReceived(
    DataReceived<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) {
    emit(NexusStoreLoaded<T>(data: event.data));
  }

  void _onErrorReceived(
    ErrorReceived<T, ID> event,
    Emitter<NexusStoreState<T>> emit,
  ) {
    emit(NexusStoreError<T>(
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
