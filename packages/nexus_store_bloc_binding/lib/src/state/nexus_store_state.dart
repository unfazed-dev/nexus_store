import 'package:collection/collection.dart';

/// Base sealed class for store state management.
///
/// This class represents all possible states for a list-based store operation:
/// - [NexusStoreInitial]: Before first load
/// - [NexusStoreLoading]: Loading (with optional previous data)
/// - [NexusStoreLoaded]: Success with data
/// - [NexusStoreError]: Error (with optional previous data)
sealed class NexusStoreState<T> {
  const NexusStoreState();

  /// Pattern matching on all possible states.
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) loaded,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData)
        error,
  });

  /// Pattern matching with optional handlers and required fallback.
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T>? previousData)? loading,
    R Function(List<T> data)? loaded,
    R Function(Object error, StackTrace? stackTrace, List<T>? previousData)?
        error,
    required R Function() orElse,
  });

  /// Returns the data if available, null otherwise.
  List<T>? get dataOrNull;

  /// Whether the state is currently loading.
  bool get isLoading;

  /// Whether the state has data (includes loaded state or states with previous data).
  bool get hasData;

  /// Whether the state has an error.
  bool get hasError;

  /// Returns the error if in error state, null otherwise.
  Object? get error;

  /// Returns the stack trace if in error state, null otherwise.
  StackTrace? get stackTrace;
}

/// Initial state before first load.
final class NexusStoreInitial<T> extends NexusStoreState<T> {
  const NexusStoreInitial();

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) loaded,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData)
        error,
  }) =>
      initial();

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T>? previousData)? loading,
    R Function(List<T> data)? loaded,
    R Function(Object error, StackTrace? stackTrace, List<T>? previousData)?
        error,
    required R Function() orElse,
  }) =>
      initial != null ? initial() : orElse();

  @override
  List<T>? get dataOrNull => null;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusStoreInitial<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NexusStoreInitial<$T>()';
}

/// Loading state with optional previous data for optimistic UI.
final class NexusStoreLoading<T> extends NexusStoreState<T> {
  const NexusStoreLoading({this.previousData});

  /// Previous data to show while loading (optimistic UI).
  final List<T>? previousData;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) loaded,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData)
        error,
  }) =>
      loading(previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T>? previousData)? loading,
    R Function(List<T> data)? loaded,
    R Function(Object error, StackTrace? stackTrace, List<T>? previousData)?
        error,
    required R Function() orElse,
  }) =>
      loading != null ? loading(previousData) : orElse();

  @override
  List<T>? get dataOrNull => previousData;

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

  static const _listEquality = ListEquality<dynamic>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusStoreLoading<T> &&
          runtimeType == other.runtimeType &&
          _listEquality.equals(previousData, other.previousData);

  @override
  int get hashCode => Object.hash(runtimeType, _listEquality.hash(previousData));

  @override
  String toString() => 'NexusStoreLoading<$T>(previousData: $previousData)';
}

/// Loaded state with data.
final class NexusStoreLoaded<T> extends NexusStoreState<T> {
  const NexusStoreLoaded({required this.data});

  /// The loaded data.
  final List<T> data;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) loaded,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData)
        error,
  }) =>
      loaded(data);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T>? previousData)? loading,
    R Function(List<T> data)? loaded,
    R Function(Object error, StackTrace? stackTrace, List<T>? previousData)?
        error,
    required R Function() orElse,
  }) =>
      loaded != null ? loaded(data) : orElse();

  @override
  List<T>? get dataOrNull => data;

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

  static const _listEquality = ListEquality<dynamic>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusStoreLoaded<T> &&
          runtimeType == other.runtimeType &&
          _listEquality.equals(data, other.data);

  @override
  int get hashCode => Object.hash(runtimeType, _listEquality.hash(data));

  @override
  String toString() => 'NexusStoreLoaded<$T>(data: $data)';
}

/// Error state with optional previous data for recovery UI.
final class NexusStoreError<T> extends NexusStoreState<T> {
  NexusStoreError({
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
  final List<T>? previousData;

  @override
  R when<R>({
    required R Function() initial,
    required R Function(List<T>? previousData) loading,
    required R Function(List<T> data) loaded,
    required R Function(Object error, StackTrace? stackTrace, List<T>? previousData)
        error,
  }) =>
      error(this.error, stackTrace, previousData);

  @override
  R maybeWhen<R>({
    R Function()? initial,
    R Function(List<T>? previousData)? loading,
    R Function(List<T> data)? loaded,
    R Function(Object error, StackTrace? stackTrace, List<T>? previousData)?
        error,
    required R Function() orElse,
  }) =>
      error != null ? error(this.error, stackTrace, previousData) : orElse();

  @override
  List<T>? get dataOrNull => previousData;

  @override
  bool get isLoading => false;

  @override
  bool get hasData => previousData != null;

  @override
  bool get hasError => true;

  static const _listEquality = ListEquality<dynamic>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexusStoreError<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace &&
          _listEquality.equals(previousData, other.previousData);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        error,
        stackTrace,
        _listEquality.hash(previousData),
      );

  @override
  String toString() =>
      'NexusStoreError<$T>(error: $error, stackTrace: $stackTrace, previousData: $previousData)';
}
