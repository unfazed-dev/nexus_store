// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryMetrics {
  /// Current estimated cache size in bytes.
  int get currentBytes;

  /// Peak cache size in bytes since last reset.
  int get maxBytes;

  /// Total number of items evicted since last reset.
  int get evictionCount;

  /// Number of pinned items (protected from eviction).
  int get pinnedCount;

  /// Estimated size of pinned items in bytes.
  int get pinnedBytes;

  /// Current memory pressure level.
  MemoryPressureLevel get pressureLevel;

  /// Total number of items in the cache.
  int get itemCount;

  /// When these metrics were captured.
  DateTime get timestamp;

  /// Create a copy of MemoryMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MemoryMetricsCopyWith<MemoryMetrics> get copyWith =>
      _$MemoryMetricsCopyWithImpl<MemoryMetrics>(
          this as MemoryMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MemoryMetrics &&
            (identical(other.currentBytes, currentBytes) ||
                other.currentBytes == currentBytes) &&
            (identical(other.maxBytes, maxBytes) ||
                other.maxBytes == maxBytes) &&
            (identical(other.evictionCount, evictionCount) ||
                other.evictionCount == evictionCount) &&
            (identical(other.pinnedCount, pinnedCount) ||
                other.pinnedCount == pinnedCount) &&
            (identical(other.pinnedBytes, pinnedBytes) ||
                other.pinnedBytes == pinnedBytes) &&
            (identical(other.pressureLevel, pressureLevel) ||
                other.pressureLevel == pressureLevel) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentBytes,
      maxBytes,
      evictionCount,
      pinnedCount,
      pinnedBytes,
      pressureLevel,
      itemCount,
      timestamp);

  @override
  String toString() {
    return 'MemoryMetrics(currentBytes: $currentBytes, maxBytes: $maxBytes, evictionCount: $evictionCount, pinnedCount: $pinnedCount, pinnedBytes: $pinnedBytes, pressureLevel: $pressureLevel, itemCount: $itemCount, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $MemoryMetricsCopyWith<$Res> {
  factory $MemoryMetricsCopyWith(
          MemoryMetrics value, $Res Function(MemoryMetrics) _then) =
      _$MemoryMetricsCopyWithImpl;
  @useResult
  $Res call(
      {int currentBytes,
      int maxBytes,
      int evictionCount,
      int pinnedCount,
      int pinnedBytes,
      MemoryPressureLevel pressureLevel,
      int itemCount,
      DateTime timestamp});
}

/// @nodoc
class _$MemoryMetricsCopyWithImpl<$Res>
    implements $MemoryMetricsCopyWith<$Res> {
  _$MemoryMetricsCopyWithImpl(this._self, this._then);

  final MemoryMetrics _self;
  final $Res Function(MemoryMetrics) _then;

  /// Create a copy of MemoryMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentBytes = null,
    Object? maxBytes = null,
    Object? evictionCount = null,
    Object? pinnedCount = null,
    Object? pinnedBytes = null,
    Object? pressureLevel = null,
    Object? itemCount = null,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      currentBytes: null == currentBytes
          ? _self.currentBytes
          : currentBytes // ignore: cast_nullable_to_non_nullable
              as int,
      maxBytes: null == maxBytes
          ? _self.maxBytes
          : maxBytes // ignore: cast_nullable_to_non_nullable
              as int,
      evictionCount: null == evictionCount
          ? _self.evictionCount
          : evictionCount // ignore: cast_nullable_to_non_nullable
              as int,
      pinnedCount: null == pinnedCount
          ? _self.pinnedCount
          : pinnedCount // ignore: cast_nullable_to_non_nullable
              as int,
      pinnedBytes: null == pinnedBytes
          ? _self.pinnedBytes
          : pinnedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      pressureLevel: null == pressureLevel
          ? _self.pressureLevel
          : pressureLevel // ignore: cast_nullable_to_non_nullable
              as MemoryPressureLevel,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [MemoryMetrics].
extension MemoryMetricsPatterns on MemoryMetrics {
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
    TResult Function(_MemoryMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics() when $default != null:
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
    TResult Function(_MemoryMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics():
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
    TResult? Function(_MemoryMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics() when $default != null:
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
    TResult Function(
            int currentBytes,
            int maxBytes,
            int evictionCount,
            int pinnedCount,
            int pinnedBytes,
            MemoryPressureLevel pressureLevel,
            int itemCount,
            DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics() when $default != null:
        return $default(
            _that.currentBytes,
            _that.maxBytes,
            _that.evictionCount,
            _that.pinnedCount,
            _that.pinnedBytes,
            _that.pressureLevel,
            _that.itemCount,
            _that.timestamp);
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
    TResult Function(
            int currentBytes,
            int maxBytes,
            int evictionCount,
            int pinnedCount,
            int pinnedBytes,
            MemoryPressureLevel pressureLevel,
            int itemCount,
            DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics():
        return $default(
            _that.currentBytes,
            _that.maxBytes,
            _that.evictionCount,
            _that.pinnedCount,
            _that.pinnedBytes,
            _that.pressureLevel,
            _that.itemCount,
            _that.timestamp);
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
    TResult? Function(
            int currentBytes,
            int maxBytes,
            int evictionCount,
            int pinnedCount,
            int pinnedBytes,
            MemoryPressureLevel pressureLevel,
            int itemCount,
            DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryMetrics() when $default != null:
        return $default(
            _that.currentBytes,
            _that.maxBytes,
            _that.evictionCount,
            _that.pinnedCount,
            _that.pinnedBytes,
            _that.pressureLevel,
            _that.itemCount,
            _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MemoryMetrics extends MemoryMetrics {
  const _MemoryMetrics(
      {required this.currentBytes,
      required this.maxBytes,
      required this.evictionCount,
      required this.pinnedCount,
      required this.pinnedBytes,
      required this.pressureLevel,
      required this.itemCount,
      required this.timestamp})
      : super._();

  /// Current estimated cache size in bytes.
  @override
  final int currentBytes;

  /// Peak cache size in bytes since last reset.
  @override
  final int maxBytes;

  /// Total number of items evicted since last reset.
  @override
  final int evictionCount;

  /// Number of pinned items (protected from eviction).
  @override
  final int pinnedCount;

  /// Estimated size of pinned items in bytes.
  @override
  final int pinnedBytes;

  /// Current memory pressure level.
  @override
  final MemoryPressureLevel pressureLevel;

  /// Total number of items in the cache.
  @override
  final int itemCount;

  /// When these metrics were captured.
  @override
  final DateTime timestamp;

  /// Create a copy of MemoryMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MemoryMetricsCopyWith<_MemoryMetrics> get copyWith =>
      __$MemoryMetricsCopyWithImpl<_MemoryMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MemoryMetrics &&
            (identical(other.currentBytes, currentBytes) ||
                other.currentBytes == currentBytes) &&
            (identical(other.maxBytes, maxBytes) ||
                other.maxBytes == maxBytes) &&
            (identical(other.evictionCount, evictionCount) ||
                other.evictionCount == evictionCount) &&
            (identical(other.pinnedCount, pinnedCount) ||
                other.pinnedCount == pinnedCount) &&
            (identical(other.pinnedBytes, pinnedBytes) ||
                other.pinnedBytes == pinnedBytes) &&
            (identical(other.pressureLevel, pressureLevel) ||
                other.pressureLevel == pressureLevel) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentBytes,
      maxBytes,
      evictionCount,
      pinnedCount,
      pinnedBytes,
      pressureLevel,
      itemCount,
      timestamp);

  @override
  String toString() {
    return 'MemoryMetrics(currentBytes: $currentBytes, maxBytes: $maxBytes, evictionCount: $evictionCount, pinnedCount: $pinnedCount, pinnedBytes: $pinnedBytes, pressureLevel: $pressureLevel, itemCount: $itemCount, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$MemoryMetricsCopyWith<$Res>
    implements $MemoryMetricsCopyWith<$Res> {
  factory _$MemoryMetricsCopyWith(
          _MemoryMetrics value, $Res Function(_MemoryMetrics) _then) =
      __$MemoryMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int currentBytes,
      int maxBytes,
      int evictionCount,
      int pinnedCount,
      int pinnedBytes,
      MemoryPressureLevel pressureLevel,
      int itemCount,
      DateTime timestamp});
}

/// @nodoc
class __$MemoryMetricsCopyWithImpl<$Res>
    implements _$MemoryMetricsCopyWith<$Res> {
  __$MemoryMetricsCopyWithImpl(this._self, this._then);

  final _MemoryMetrics _self;
  final $Res Function(_MemoryMetrics) _then;

  /// Create a copy of MemoryMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentBytes = null,
    Object? maxBytes = null,
    Object? evictionCount = null,
    Object? pinnedCount = null,
    Object? pinnedBytes = null,
    Object? pressureLevel = null,
    Object? itemCount = null,
    Object? timestamp = null,
  }) {
    return _then(_MemoryMetrics(
      currentBytes: null == currentBytes
          ? _self.currentBytes
          : currentBytes // ignore: cast_nullable_to_non_nullable
              as int,
      maxBytes: null == maxBytes
          ? _self.maxBytes
          : maxBytes // ignore: cast_nullable_to_non_nullable
              as int,
      evictionCount: null == evictionCount
          ? _self.evictionCount
          : evictionCount // ignore: cast_nullable_to_non_nullable
              as int,
      pinnedCount: null == pinnedCount
          ? _self.pinnedCount
          : pinnedCount // ignore: cast_nullable_to_non_nullable
              as int,
      pinnedBytes: null == pinnedBytes
          ? _self.pinnedBytes
          : pinnedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      pressureLevel: null == pressureLevel
          ? _self.pressureLevel
          : pressureLevel // ignore: cast_nullable_to_non_nullable
              as MemoryPressureLevel,
      itemCount: null == itemCount
          ? _self.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
