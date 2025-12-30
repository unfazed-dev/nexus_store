/// Base sealed class for single item state management.
///
/// This class represents all possible states for a single-item store operation:
/// - [NexusItemInitial]: Before first load
/// - [NexusItemLoading]: Loading (with optional previous data)
/// - [NexusItemLoaded]: Success with data
/// - [NexusItemNotFound]: Item not found (null from store)
/// - [NexusItemError]: Error (with optional previous data)
sealed class NexusItemState<T> {
  const NexusItemState();

  /// Pattern matching on all possible states.
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  });

  /// Pattern matching with optional handlers and required fallback.
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  });

  /// Returns the data if available, null otherwise.
  T? get dataOrNull;

  /// Whether the state is currently loading.
  bool get isLoading;

  /// Whether the state has data.
  bool get hasData;

  /// Whether the state has an error.
  bool get hasError;

  /// Returns the error if in error state, null otherwise.
  Object? get error;

  /// Returns the stack trace if in error state, null otherwise.
  StackTrace? get stackTrace;

  /// Whether the item was not found.
  bool get isNotFound;
}

/// Initial state before first load.
final class NexusItemInitial<T> extends NexusItemState<T> {
  const NexusItemInitial();

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      initial();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      initial != null ? initial() : orElse();

  @override
  T? get dataOrNull => null;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => false;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool get isNotFound => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemInitial<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NexusItemInitial<$T>()';
}

/// Loading state with optional previous data for optimistic UI.
final class NexusItemLoading<T> extends NexusItemState<T> {
  const NexusItemLoading({this.previousData});

  /// Previous data to show while loading (optimistic UI).
  final T? previousData;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      loading(previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      loading != null ? loading(previousData) : orElse();

  @override
  T? get dataOrNull => previousData;

  @override
  bool get isLoading => true;

  @override
  bool get hasData => previousData != null;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool get isNotFound => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemLoading<T> &&
          runtimeType == other.runtimeType &&
          previousData == other.previousData;

  @override
  int get hashCode => Object.hash(runtimeType, previousData);

  @override
  String toString() => 'NexusItemLoading<$T>(previousData: $previousData)';
}

/// Loaded state with data.
final class NexusItemLoaded<T> extends NexusItemState<T> {
  const NexusItemLoaded({required this.data});

  /// The loaded data.
  final T data;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      loaded(data);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      loaded != null ? loaded(data) : orElse();

  @override
  T? get dataOrNull => data;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => true;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool get isNotFound => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemLoaded<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'NexusItemLoaded<$T>(data: $data)';
}

/// Not found state when the item doesn't exist.
final class NexusItemNotFound<T> extends NexusItemState<T> {
  const NexusItemNotFound();

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      notFound();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      notFound != null ? notFound() : orElse();

  @override
  T? get dataOrNull => null;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => false;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool get isNotFound => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemNotFound<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NexusItemNotFound<$T>()';
}

/// Error state with optional previous data for recovery UI.
final class NexusItemError<T> extends NexusItemState<T> {
  NexusItemError({
    required this.error,
    this.stackTrace,
    this.previousData,
  });

  /// The error that occurred.
  @override
  final Object error;

  /// The stack trace of the error.
  @override
  final StackTrace? stackTrace;

  /// Previous data to show during error state.
  final T? previousData;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) loaded,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      error(this.error, stackTrace, previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? loaded,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      error != null ? error(this.error, stackTrace, previousData) : orElse();

  @override
  T? get dataOrNull => previousData;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => previousData != null;

  @override
  bool get hasError => true;

  @override
  bool get isNotFound => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemError<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace &&
          previousData == other.previousData;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace, previousData);

  @override
  String toString() =>
      'NexusItemError<$T>(error: $error, stackTrace: $stackTrace, previousData: $previousData)';
}
