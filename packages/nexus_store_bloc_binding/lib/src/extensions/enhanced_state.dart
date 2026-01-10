import '../state/nexus_store_state.dart';

/// Extension on [NexusStoreState] providing convenience methods for data manipulation.
///
/// These helpers reduce boilerplate in the UI layer when working with store states.
///
/// ## Example
///
/// ```dart
/// // Transform data
/// final count = state.mapData((users) => users.length);
///
/// // Filter data
/// final activeUsers = state.where((u) => u.isActive);
///
/// // Find by ID
/// final user = state.findById('user-123', (u) => u.id);
///
/// // Combine states
/// final combined = usersState.combineWith(postsState);
/// ```
extension NexusStoreStateX<T> on NexusStoreState<T> {
  /// Transforms the data using the given function.
  ///
  /// Returns null if no data is available (initial state or loading without previous data).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final count = state.mapData((users) => users.length);
  /// final names = state.mapData((users) => users.map((u) => u.name).toList());
  /// ```
  R? mapData<R>(R Function(List<T> data) transform) {
    final data = dataOrNull;
    if (data == null) return null;
    return transform(data);
  }

  /// Filters the data using the given predicate.
  ///
  /// Returns an empty list if no data is available.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final activeUsers = state.where((u) => u.isActive);
  /// ```
  List<T> where(bool Function(T item) predicate) {
    final data = dataOrNull;
    if (data == null) return [];
    return data.where(predicate).toList();
  }

  /// Returns the first item or null if no data or empty data.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final firstUser = state.firstOrNull;
  /// ```
  T? get firstOrNull {
    final data = dataOrNull;
    if (data == null || data.isEmpty) return null;
    return data.first;
  }

  /// Finds an item by ID using the provided ID extractor.
  ///
  /// Returns null if not found or no data available.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = state.findById('user-123', (u) => u.id);
  /// ```
  T? findById<ID>(ID id, ID Function(T item) getId) {
    final data = dataOrNull;
    if (data == null) return null;

    for (final item in data) {
      if (getId(item) == id) return item;
    }
    return null;
  }

  /// Whether the data is empty or not available.
  ///
  /// Returns true for initial state, loading without previous data,
  /// or loaded state with empty list.
  bool get isEmpty {
    final data = dataOrNull;
    return data == null || data.isEmpty;
  }

  /// Whether the data is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns the length of the data, or 0 if no data available.
  int get length {
    final data = dataOrNull;
    return data?.length ?? 0;
  }

  /// Combines this state with another state of a different type.
  ///
  /// Returns a [CombinedState] that tracks loading and error states
  /// from both sources.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final combined = usersState.combineWith(postsState);
  /// if (combined.isLoading) {
  ///   return CircularProgressIndicator();
  /// }
  /// if (combined.hasError) {
  ///   return Text('Error: ${combined.firstError}');
  /// }
  /// final users = combined.firstData!;
  /// final posts = combined.secondData!;
  /// ```
  CombinedState<T, R> combineWith<R>(NexusStoreState<R> other) {
    return CombinedState<T, R>(this, other);
  }
}

/// Represents the combined state of two [NexusStoreState] instances.
///
/// Useful for coordinating UI that depends on multiple data sources.
class CombinedState<T, R> {
  /// Creates a combined state from two store states.
  CombinedState(this.first, this.second);

  /// The first state.
  final NexusStoreState<T> first;

  /// The second state.
  final NexusStoreState<R> second;

  /// Whether either state is currently loading.
  bool get isLoading => first.isLoading || second.isLoading;

  /// Whether either state has an error.
  bool get hasError => first.hasError || second.hasError;

  /// The first error encountered, if any.
  Object? get firstError {
    if (first.hasError) return first.error;
    if (second.hasError) return second.error;
    return null;
  }

  /// The data from the first state, or null if not available.
  List<T>? get firstData => first.dataOrNull;

  /// The data from the second state, or null if not available.
  List<R>? get secondData => second.dataOrNull;

  /// Whether both states have data available.
  bool get hasBothData => firstData != null && secondData != null;

  /// Maps both data sources if available.
  ///
  /// Returns null if either data source is not available.
  S? mapBoth<S>(S Function(List<T> first, List<R> second) transform) {
    final f = firstData;
    final s = secondData;
    if (f == null || s == null) return null;
    return transform(f, s);
  }
}
