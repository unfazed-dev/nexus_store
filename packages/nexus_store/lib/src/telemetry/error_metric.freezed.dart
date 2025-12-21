// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorMetric {
  /// The error that occurred.
  Object get error;

  /// Stack trace at time of error.
  StackTrace? get stackTrace;

  /// The operation that was being performed.
  String? get operation;

  /// Whether the error was recoverable.
  bool get recoverable;

  /// When the error occurred.
  DateTime get timestamp;

  /// Create a copy of ErrorMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ErrorMetricCopyWith<ErrorMetric> get copyWith =>
      _$ErrorMetricCopyWithImpl<ErrorMetric>(this as ErrorMetric, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ErrorMetric &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.recoverable, recoverable) ||
                other.recoverable == recoverable) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(error),
      stackTrace,
      operation,
      recoverable,
      timestamp);

  @override
  String toString() {
    return 'ErrorMetric(error: $error, stackTrace: $stackTrace, operation: $operation, recoverable: $recoverable, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $ErrorMetricCopyWith<$Res> {
  factory $ErrorMetricCopyWith(
          ErrorMetric value, $Res Function(ErrorMetric) _then) =
      _$ErrorMetricCopyWithImpl;
  @useResult
  $Res call(
      {Object error,
      StackTrace? stackTrace,
      String? operation,
      bool recoverable,
      DateTime timestamp});
}

/// @nodoc
class _$ErrorMetricCopyWithImpl<$Res> implements $ErrorMetricCopyWith<$Res> {
  _$ErrorMetricCopyWithImpl(this._self, this._then);

  final ErrorMetric _self;
  final $Res Function(ErrorMetric) _then;

  /// Create a copy of ErrorMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
    Object? stackTrace = freezed,
    Object? operation = freezed,
    Object? recoverable = null,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      error: null == error ? _self.error : error,
      stackTrace: freezed == stackTrace
          ? _self.stackTrace
          : stackTrace // ignore: cast_nullable_to_non_nullable
              as StackTrace?,
      operation: freezed == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String?,
      recoverable: null == recoverable
          ? _self.recoverable
          : recoverable // ignore: cast_nullable_to_non_nullable
              as bool,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [ErrorMetric].
extension ErrorMetricPatterns on ErrorMetric {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ErrorMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ErrorMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ErrorMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Object error, StackTrace? stackTrace, String? operation,
            bool recoverable, DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric() when $default != null:
        return $default(_that.error, _that.stackTrace, _that.operation,
            _that.recoverable, _that.timestamp);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Object error, StackTrace? stackTrace, String? operation,
            bool recoverable, DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric():
        return $default(_that.error, _that.stackTrace, _that.operation,
            _that.recoverable, _that.timestamp);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Object error, StackTrace? stackTrace, String? operation,
            bool recoverable, DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ErrorMetric() when $default != null:
        return $default(_that.error, _that.stackTrace, _that.operation,
            _that.recoverable, _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ErrorMetric extends ErrorMetric {
  const _ErrorMetric(
      {required this.error,
      this.stackTrace,
      this.operation,
      this.recoverable = false,
      required this.timestamp})
      : super._();

  /// The error that occurred.
  @override
  final Object error;

  /// Stack trace at time of error.
  @override
  final StackTrace? stackTrace;

  /// The operation that was being performed.
  @override
  final String? operation;

  /// Whether the error was recoverable.
  @override
  @JsonKey()
  final bool recoverable;

  /// When the error occurred.
  @override
  final DateTime timestamp;

  /// Create a copy of ErrorMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ErrorMetricCopyWith<_ErrorMetric> get copyWith =>
      __$ErrorMetricCopyWithImpl<_ErrorMetric>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ErrorMetric &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.recoverable, recoverable) ||
                other.recoverable == recoverable) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(error),
      stackTrace,
      operation,
      recoverable,
      timestamp);

  @override
  String toString() {
    return 'ErrorMetric(error: $error, stackTrace: $stackTrace, operation: $operation, recoverable: $recoverable, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$ErrorMetricCopyWith<$Res>
    implements $ErrorMetricCopyWith<$Res> {
  factory _$ErrorMetricCopyWith(
          _ErrorMetric value, $Res Function(_ErrorMetric) _then) =
      __$ErrorMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Object error,
      StackTrace? stackTrace,
      String? operation,
      bool recoverable,
      DateTime timestamp});
}

/// @nodoc
class __$ErrorMetricCopyWithImpl<$Res> implements _$ErrorMetricCopyWith<$Res> {
  __$ErrorMetricCopyWithImpl(this._self, this._then);

  final _ErrorMetric _self;
  final $Res Function(_ErrorMetric) _then;

  /// Create a copy of ErrorMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
    Object? stackTrace = freezed,
    Object? operation = freezed,
    Object? recoverable = null,
    Object? timestamp = null,
  }) {
    return _then(_ErrorMetric(
      error: null == error ? _self.error : error,
      stackTrace: freezed == stackTrace
          ? _self.stackTrace
          : stackTrace // ignore: cast_nullable_to_non_nullable
              as StackTrace?,
      operation: freezed == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String?,
      recoverable: null == recoverable
          ? _self.recoverable
          : recoverable // ignore: cast_nullable_to_non_nullable
              as bool,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
