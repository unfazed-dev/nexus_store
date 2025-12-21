// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cache_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CacheMetric {
  /// The type of cache event.
  CacheEvent get event;

  /// The ID of the affected item (if single item).
  String? get itemId;

  /// Tags associated with the cache entry.
  Set<String> get tags;

  /// When the event occurred.
  DateTime get timestamp;

  /// Number of items affected (for batch operations).
  int get itemCount;

  /// Create a copy of CacheMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CacheMetricCopyWith<CacheMetric> get copyWith =>
      _$CacheMetricCopyWithImpl<CacheMetric>(this as CacheMetric, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CacheMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event, itemId,
      const DeepCollectionEquality().hash(tags), timestamp, itemCount);

  @override
  String toString() {
    return 'CacheMetric(event: $event, itemId: $itemId, tags: $tags, timestamp: $timestamp, itemCount: $itemCount)';
  }
}

/// @nodoc
abstract mixin class $CacheMetricCopyWith<$Res> {
  factory $CacheMetricCopyWith(
          CacheMetric value, $Res Function(CacheMetric) _then) =
      _$CacheMetricCopyWithImpl;
  @useResult
  $Res call(
      {CacheEvent event,
      String? itemId,
      Set<String> tags,
      DateTime timestamp,
      int itemCount});
}

/// @nodoc
class _$CacheMetricCopyWithImpl<$Res> implements $CacheMetricCopyWith<$Res> {
  _$CacheMetricCopyWithImpl(this._self, this._then);

  final CacheMetric _self;
  final $Res Function(CacheMetric) _then;

  /// Create a copy of CacheMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
    Object? itemId = freezed,
    Object? tags = null,
    Object? timestamp = null,
    Object? itemCount = null,
  }) {
    return _then(_self.copyWith(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as CacheEvent,
      itemId: freezed == itemId
          ? _self.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [CacheMetric].
extension CacheMetricPatterns on CacheMetric {
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
    TResult Function(_CacheMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacheMetric() when $default != null:
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
    TResult Function(_CacheMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMetric():
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
    TResult? Function(_CacheMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMetric() when $default != null:
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
    TResult Function(CacheEvent event, String? itemId, Set<String> tags,
            DateTime timestamp, int itemCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacheMetric() when $default != null:
        return $default(_that.event, _that.itemId, _that.tags, _that.timestamp,
            _that.itemCount);
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
    TResult Function(CacheEvent event, String? itemId, Set<String> tags,
            DateTime timestamp, int itemCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMetric():
        return $default(_that.event, _that.itemId, _that.tags, _that.timestamp,
            _that.itemCount);
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
    TResult? Function(CacheEvent event, String? itemId, Set<String> tags,
            DateTime timestamp, int itemCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMetric() when $default != null:
        return $default(_that.event, _that.itemId, _that.tags, _that.timestamp,
            _that.itemCount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CacheMetric extends CacheMetric {
  const _CacheMetric(
      {required this.event,
      this.itemId,
      final Set<String> tags = const <String>{},
      required this.timestamp,
      this.itemCount = 1})
      : _tags = tags,
        super._();

  /// The type of cache event.
  @override
  final CacheEvent event;

  /// The ID of the affected item (if single item).
  @override
  final String? itemId;

  /// Tags associated with the cache entry.
  final Set<String> _tags;

  /// Tags associated with the cache entry.
  @override
  @JsonKey()
  Set<String> get tags {
    if (_tags is EqualUnmodifiableSetView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_tags);
  }

  /// When the event occurred.
  @override
  final DateTime timestamp;

  /// Number of items affected (for batch operations).
  @override
  @JsonKey()
  final int itemCount;

  /// Create a copy of CacheMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CacheMetricCopyWith<_CacheMetric> get copyWith =>
      __$CacheMetricCopyWithImpl<_CacheMetric>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CacheMetric &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event, itemId,
      const DeepCollectionEquality().hash(_tags), timestamp, itemCount);

  @override
  String toString() {
    return 'CacheMetric(event: $event, itemId: $itemId, tags: $tags, timestamp: $timestamp, itemCount: $itemCount)';
  }
}

/// @nodoc
abstract mixin class _$CacheMetricCopyWith<$Res>
    implements $CacheMetricCopyWith<$Res> {
  factory _$CacheMetricCopyWith(
          _CacheMetric value, $Res Function(_CacheMetric) _then) =
      __$CacheMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {CacheEvent event,
      String? itemId,
      Set<String> tags,
      DateTime timestamp,
      int itemCount});
}

/// @nodoc
class __$CacheMetricCopyWithImpl<$Res> implements _$CacheMetricCopyWith<$Res> {
  __$CacheMetricCopyWithImpl(this._self, this._then);

  final _CacheMetric _self;
  final $Res Function(_CacheMetric) _then;

  /// Create a copy of CacheMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? event = null,
    Object? itemId = freezed,
    Object? tags = null,
    Object? timestamp = null,
    Object? itemCount = null,
  }) {
    return _then(_CacheMetric(
      event: null == event
          ? _self.event
          : event // ignore: cast_nullable_to_non_nullable
              as CacheEvent,
      itemId: freezed == itemId
          ? _self.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
