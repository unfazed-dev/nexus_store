// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncMetric {
  /// The type of sync event.
  SyncEvent get event;

  /// Duration of the sync operation (for completed/failed).
  Duration? get duration;

  /// Number of items synced.
  int get itemsSynced;

  /// Error message if sync failed.
  String? get error;

  /// When the event occurred.
  DateTime get timestamp;

  /// Create a copy of SyncMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncMetricCopyWith<SyncMetric> get copyWith =>
      _$SyncMetricCopyWithImpl<SyncMetric>(this as SyncMetric, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.itemsSynced, itemsSynced) ||
                other.itemsSynced == itemsSynced) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, event, duration, itemsSynced, error, timestamp);

  @override
  String toString() {
    return 'SyncMetric(event: $event, duration: $duration, itemsSynced: $itemsSynced, error: $error, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $SyncMetricCopyWith<$Res> {
  factory $SyncMetricCopyWith(
          SyncMetric value, $Res Function(SyncMetric) _then) =
      _$SyncMetricCopyWithImpl;
  @useResult
  $Res call(
      {SyncEvent event,
      Duration? duration,
      int itemsSynced,
      String? error,
      DateTime timestamp});
}

/// @nodoc
class _$SyncMetricCopyWithImpl<$Res> implements $SyncMetricCopyWith<$Res> {
  _$SyncMetricCopyWithImpl(this._self, this._then);

  final SyncMetric _self;
  final $Res Function(SyncMetric) _then;

  /// Create a copy of SyncMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? duration = freezed,
    Object? itemsSynced = null,
    Object? error = freezed,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as SyncEvent,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      itemsSynced: null == itemsSynced
          ? _self.itemsSynced
          : itemsSynced // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [SyncMetric].
extension SyncMetricPatterns on SyncMetric {
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
    TResult Function(_SyncMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMetric() when $default != null:
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
    TResult Function(_SyncMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMetric():
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
    TResult? Function(_SyncMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMetric() when $default != null:
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
    TResult Function(SyncEvent event, Duration? duration, int itemsSynced,
            String? error, DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMetric() when $default != null:
        return $default(_that.event, _that.duration, _that.itemsSynced,
            _that.error, _that.timestamp);
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
    TResult Function(SyncEvent event, Duration? duration, int itemsSynced,
            String? error, DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMetric():
        return $default(_that.event, _that.duration, _that.itemsSynced,
            _that.error, _that.timestamp);
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
    TResult? Function(SyncEvent event, Duration? duration, int itemsSynced,
            String? error, DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMetric() when $default != null:
        return $default(_that.event, _that.duration, _that.itemsSynced,
            _that.error, _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SyncMetric extends SyncMetric {
  const _SyncMetric(
      {required this.event,
      this.duration,
      this.itemsSynced = 0,
      this.error,
      required this.timestamp})
      : super._();

  /// The type of sync event.
  @override
  final SyncEvent event;

  /// Duration of the sync operation (for completed/failed).
  @override
  final Duration? duration;

  /// Number of items synced.
  @override
  @JsonKey()
  final int itemsSynced;

  /// Error message if sync failed.
  @override
  final String? error;

  /// When the event occurred.
  @override
  final DateTime timestamp;

  /// Create a copy of SyncMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncMetricCopyWith<_SyncMetric> get copyWith =>
      __$SyncMetricCopyWithImpl<_SyncMetric>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.itemsSynced, itemsSynced) ||
                other.itemsSynced == itemsSynced) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, event, duration, itemsSynced, error, timestamp);

  @override
  String toString() {
    return 'SyncMetric(event: $event, duration: $duration, itemsSynced: $itemsSynced, error: $error, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$SyncMetricCopyWith<$Res>
    implements $SyncMetricCopyWith<$Res> {
  factory _$SyncMetricCopyWith(
          _SyncMetric value, $Res Function(_SyncMetric) _then) =
      __$SyncMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {SyncEvent event,
      Duration? duration,
      int itemsSynced,
      String? error,
      DateTime timestamp});
}

/// @nodoc
class __$SyncMetricCopyWithImpl<$Res> implements _$SyncMetricCopyWith<$Res> {
  __$SyncMetricCopyWithImpl(this._self, this._then);

  final _SyncMetric _self;
  final $Res Function(_SyncMetric) _then;

  /// Create a copy of SyncMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? event = null,
    Object? duration = freezed,
    Object? itemsSynced = null,
    Object? error = freezed,
    Object? timestamp = null,
  }) {
    return _then(_SyncMetric(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as SyncEvent,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      itemsSynced: null == itemsSynced
          ? _self.itemsSynced
          : itemsSynced // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
