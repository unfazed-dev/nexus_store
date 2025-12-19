/// Result type for store operations.
///
/// Provides idle, pending, success, and error states. Similar to Riverpod's
/// AsyncValue, this sealed class provides a type-safe way to handle async
/// states in Flutter widgets with pattern matching support.
///
/// Example:
/// ```dart
/// StoreResult<User> result = StoreResult.success(user);
///
/// result.when(
///   idle: () => Text('Idle'),
///   pending: (previous) => CircularProgressIndicator(),
///   success: (data) => Text(data.name),
///   error: (error, previous) => Text('Error: $error'),
/// );
/// ```
library;

import 'package:flutter/foundation.dart';

/// A sealed class representing the result of a store operation.
///
/// This type provides four possible states:
/// - [StoreResultIdle]: Initial state before any data is loaded
/// - [StoreResultPending]: Loading state, optionally with previous data
/// - [StoreResultSuccess]: Success state with data
/// - [StoreResultError]: Error state with error and optionally previous data
@immutable
sealed class StoreResult<T> {
  const StoreResult();

  /// Creates an idle result.
  const factory StoreResult.idle() = StoreResultIdle<T>;

  /// Creates a pending result, optionally with previous data.
  const factory StoreResult.pending([T? previousData]) = StoreResultPending<T>;

  /// Creates a success result with data.
  const factory StoreResult.success(T data) = StoreResultSuccess<T>;

  /// Creates an error result with an error and optionally previous data.
  const factory StoreResult.error(Object error, [T? previousData]) =
      StoreResultError<T>;

  /// Returns true if this result has data (either success or stale data).
  bool get hasData;

  /// Returns the data if available, or null otherwise.
  T? get data;

  /// Returns true if this result is in a loading state.
  bool get isLoading;

  /// Returns true if this result has an error.
  bool get hasError;

  /// Returns the error if available, or null otherwise.
  Object? get error;

  /// Pattern matches on all possible states.
  ///
  /// All callbacks are required. For partial matching, use [maybeWhen].
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) pending,
    required R Function(T data) success,
    required R Function(Object error, T? previousData) error,
  });

  /// Pattern matches on states with optional callbacks.
  ///
  /// The [orElse] callback is required and called for unhandled states.
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? pending,
    R Function(T data)? success,
    R Function(Object error, T? previousData)? error,
    required R Function() orElse,
  });

  /// Maps this result to a new result with a different type.
  StoreResult<R> map<R>(R Function(T data) transform);

  /// Creates a new result with the same type but potentially different state.
  StoreResult<T> copyWith({
    T? data,
    Object? error,
  });
}

/// Represents an idle state before any data is loaded.
@immutable
final class StoreResultIdle<T> extends StoreResult<T> {
  /// Creates an idle result state.
  const StoreResultIdle();

  @override
  bool get hasData => false;

  @override
  T? get data => null;

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) pending,
    required R Function(T data) success,
    required R Function(Object error, T? previousData) error,
  }) =>
      idle();

  @override
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? pending,
    R Function(T data)? success,
    R Function(Object error, T? previousData)? error,
    required R Function() orElse,
  }) =>
      idle?.call() ?? orElse();

  @override
  StoreResult<R> map<R>(R Function(T data) transform) =>
      StoreResult<R>.idle();

  @override
  StoreResult<T> copyWith({T? data, Object? error}) {
    if (data != null) {
      return StoreResult<T>.success(data);
    }
    if (error != null) {
      return StoreResult<T>.error(error);
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StoreResultIdle<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'StoreResult<$T>.idle()';
}

/// Represents a pending/loading state, optionally with previous data.
@immutable
final class StoreResultPending<T> extends StoreResult<T> {
  /// Creates a pending result state with optional [previousData].
  const StoreResultPending([this.previousData]);

  /// The previous data, if any, to show while loading.
  final T? previousData;

  @override
  bool get hasData => previousData != null;

  @override
  T? get data => previousData;

  @override
  bool get isLoading => true;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) pending,
    required R Function(T data) success,
    required R Function(Object error, T? previousData) error,
  }) =>
      pending(previousData);

  @override
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? pending,
    R Function(T data)? success,
    R Function(Object error, T? previousData)? error,
    required R Function() orElse,
  }) =>
      pending?.call(previousData) ?? orElse();

  @override
  StoreResult<R> map<R>(R Function(T data) transform) {
    final prev = previousData;
    return StoreResult<R>.pending(prev != null ? transform(prev) : null);
  }

  @override
  StoreResult<T> copyWith({T? data, Object? error}) {
    if (error != null) {
      return StoreResult<T>.error(error, data ?? previousData);
    }
    return StoreResult<T>.pending(data ?? previousData);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreResultPending<T> && other.previousData == previousData);

  @override
  int get hashCode => Object.hash(runtimeType, previousData);

  @override
  String toString() => 'StoreResult<$T>.pending($previousData)';
}

/// Represents a success state with data.
@immutable
final class StoreResultSuccess<T> extends StoreResult<T> {
  /// Creates a success result state with [data].
  const StoreResultSuccess(this._data);

  final T _data;

  @override
  bool get hasData => true;

  @override
  T get data => _data;

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) pending,
    required R Function(T data) success,
    required R Function(Object error, T? previousData) error,
  }) =>
      success(_data);

  @override
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? pending,
    R Function(T data)? success,
    R Function(Object error, T? previousData)? error,
    required R Function() orElse,
  }) =>
      success?.call(_data) ?? orElse();

  @override
  StoreResult<R> map<R>(R Function(T data) transform) =>
      StoreResult<R>.success(transform(_data));

  @override
  StoreResult<T> copyWith({T? data, Object? error}) {
    if (error != null) {
      return StoreResult<T>.error(error, data ?? _data);
    }
    return StoreResult<T>.success(data ?? _data);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreResultSuccess<T> && other._data == _data);

  @override
  int get hashCode => Object.hash(runtimeType, _data);

  @override
  String toString() => 'StoreResult<$T>.success($_data)';
}

/// Represents an error state with an error and optionally previous data.
@immutable
final class StoreResultError<T> extends StoreResult<T> {
  /// Creates an error result state with [error] and optional [previousData].
  const StoreResultError(this._error, [this.previousData]);

  final Object _error;

  /// The previous data, if any, to show alongside the error.
  final T? previousData;

  @override
  bool get hasData => previousData != null;

  @override
  T? get data => previousData;

  @override
  bool get isLoading => false;

  @override
  bool get hasError => true;

  @override
  Object get error => _error;

  @override
  R when<R>({
    required R Function() idle,
    required R Function(T? previousData) pending,
    required R Function(T data) success,
    required R Function(Object error, T? previousData) error,
  }) =>
      error(_error, previousData);

  @override
  R maybeWhen<R>({
    R Function()? idle,
    R Function(T? previousData)? pending,
    R Function(T data)? success,
    R Function(Object error, T? previousData)? error,
    required R Function() orElse,
  }) =>
      error?.call(_error, previousData) ?? orElse();

  @override
  StoreResult<R> map<R>(R Function(T data) transform) {
    final prev = previousData;
    return StoreResult<R>.error(_error, prev != null ? transform(prev) : null);
  }

  @override
  StoreResult<T> copyWith({T? data, Object? error}) =>
      StoreResult<T>.error(error ?? _error, data ?? previousData);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreResultError<T> &&
          other._error == _error &&
          other.previousData == previousData);

  @override
  int get hashCode => Object.hash(runtimeType, _error, previousData);

  @override
  String toString() => 'StoreResult<$T>.error($_error, $previousData)';
}

/// Extension methods for [StoreResult].
extension StoreResultExtensions<T> on StoreResult<T> {
  /// Returns the data if available, or the provided default value.
  T dataOr(T defaultValue) => data ?? defaultValue;

  /// Returns the data if available, or throws the error if present.
  ///
  /// Throws [StateError] if neither data nor error is available.
  T requireData() {
    if (hasData) return data as T;
    if (hasError) {
      final err = error;
      if (err is Exception) throw err;
      if (err is Error) throw err;
      throw Exception(err.toString());
    }
    throw StateError('No data available in $this');
  }

  /// Converts this result to a nullable data value.
  ///
  /// Returns the data if successful, null otherwise.
  T? toNullable() => this is StoreResultSuccess<T> ? data : null;

  /// Returns true if this is an idle state.
  bool get isIdle => this is StoreResultIdle<T>;

  /// Returns true if this is a success state.
  bool get isSuccess => this is StoreResultSuccess<T>;

  /// Refreshing state - pending with previous successful data.
  bool get isRefreshing => isLoading && hasData;
}
