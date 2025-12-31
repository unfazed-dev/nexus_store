/// Base sealed class for single item state management with signals.
///
/// This class represents all possible states for a single item store operation:
/// - [NexusItemSignalInitial]: Before first load
/// - [NexusItemSignalLoading]: Loading (with optional previous data)
/// - [NexusItemSignalData]: Success with data
/// - [NexusItemSignalNotFound]: Item not found
/// - [NexusItemSignalError]: Error (with optional previous data)
sealed class NexusItemSignalState<T> {
  const NexusItemSignalState();

  /// Pattern matching on all possible states.
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  });

  /// Pattern matching with optional handlers and required fallback.
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  });

  /// Returns the data if available, null otherwise.
  T? get dataOrNull;

  /// Whether the state is currently loading.
  bool get isLoading;

  /// Whether the state has data (includes loaded state or states with previous data).
  bool get hasData;

  /// Whether the state has an error.
  bool get hasError;

  /// Whether the item was not found.
  bool get isNotFound;

  /// Returns the error if in error state, null otherwise.
  Object? get error;

  /// Returns the stack trace if in error state, null otherwise.
  StackTrace? get stackTrace;
}

/// Initial state before first load.
final class NexusItemSignalInitial<T> extends NexusItemSignalState<T> {
  const NexusItemSignalInitial();

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      initial();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
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
  bool get isNotFound => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemSignalInitial<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NexusItemSignalInitial<$T>()';
}

/// Loading state with optional previous data for optimistic UI.
final class NexusItemSignalLoading<T> extends NexusItemSignalState<T> {
  const NexusItemSignalLoading({this.previousData});

  /// Previous data to show while loading (optimistic UI).
  final T? previousData;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      loading(previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
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
  bool get isNotFound => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemSignalLoading<T> &&
          runtimeType == other.runtimeType &&
          previousData == other.previousData;

  @override
  int get hashCode => Object.hash(runtimeType, previousData);

  @override
  String toString() =>
      'NexusItemSignalLoading<$T>(previousData: $previousData)';
}

/// Data state with loaded data.
final class NexusItemSignalData<T> extends NexusItemSignalState<T> {
  const NexusItemSignalData({required this.data});

  /// The loaded data.
  final T data;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      data(this.data);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
    R Function()? notFound,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) =>
      data != null ? data(this.data) : orElse();

  @override
  T? get dataOrNull => data;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => true;

  @override
  bool get hasError => false;

  @override
  bool get isNotFound => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemSignalData<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'NexusItemSignalData<$T>(data: $data)';
}

/// Not found state when item doesn't exist.
final class NexusItemSignalNotFound<T> extends NexusItemSignalState<T> {
  const NexusItemSignalNotFound();

  @override
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      notFound();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
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
  bool get isNotFound => true;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusItemSignalNotFound<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NexusItemSignalNotFound<$T>()';
}

/// Error state with optional previous data for recovery UI.
final class NexusItemSignalError<T> extends NexusItemSignalState<T> {
  NexusItemSignalError({
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
    required R Function(T data) data,
    required R Function() notFound,
    required R Function(Object error, StackTrace? stackTrace, T? previousData)
        error,
  }) =>
      error(this.error, stackTrace, previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? data,
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
      other is NexusItemSignalError<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace &&
          previousData == other.previousData;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace, previousData);

  @override
  String toString() =>
      'NexusItemSignalError<$T>(error: $error, stackTrace: $stackTrace, previousData: $previousData)';
}
