// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metrics_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MetricsConfig {
  /// Sample rate for metrics (0.0 to 1.0).
  ///
  /// - 1.0 = sample all operations (100%)
  /// - 0.5 = sample half of operations (50%)
  /// - 0.0 = sample none (disabled)
  double get sampleRate;

  /// Buffer size for buffered reporters.
  ///
  /// When the buffer reaches this size, it will auto-flush.
  int get bufferSize;

  /// Flush interval for buffered reporters.
  ///
  /// Metrics will be flushed at least this often.
  Duration get flushInterval;

  /// Whether to include stack traces in error metrics.
  ///
  /// Set to false in production to reduce overhead and payload size.
  bool get includeStackTraces;

  /// Whether to track timing for operations.
  ///
  /// When false, duration will be Duration.zero.
  bool get trackTiming;

  /// Create a copy of MetricsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MetricsConfigCopyWith<MetricsConfig> get copyWith =>
      _$MetricsConfigCopyWithImpl<MetricsConfig>(
          this as MetricsConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MetricsConfig &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate) &&
            (identical(other.bufferSize, bufferSize) ||
                other.bufferSize == bufferSize) &&
            (identical(other.flushInterval, flushInterval) ||
                other.flushInterval == flushInterval) &&
            (identical(other.includeStackTraces, includeStackTraces) ||
                other.includeStackTraces == includeStackTraces) &&
            (identical(other.trackTiming, trackTiming) ||
                other.trackTiming == trackTiming));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sampleRate, bufferSize,
      flushInterval, includeStackTraces, trackTiming);

  @override
  String toString() {
    return 'MetricsConfig(sampleRate: $sampleRate, bufferSize: $bufferSize, flushInterval: $flushInterval, includeStackTraces: $includeStackTraces, trackTiming: $trackTiming)';
  }
}

/// @nodoc
abstract mixin class $MetricsConfigCopyWith<$Res> {
  factory $MetricsConfigCopyWith(
          MetricsConfig value, $Res Function(MetricsConfig) _then) =
      _$MetricsConfigCopyWithImpl;
  @useResult
  $Res call(
      {double sampleRate,
      int bufferSize,
      Duration flushInterval,
      bool includeStackTraces,
      bool trackTiming});
}

/// @nodoc
class _$MetricsConfigCopyWithImpl<$Res>
    implements $MetricsConfigCopyWith<$Res> {
  _$MetricsConfigCopyWithImpl(this._self, this._then);

  final MetricsConfig _self;
  final $Res Function(MetricsConfig) _then;

  /// Create a copy of MetricsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sampleRate = null,
    Object? bufferSize = null,
    Object? flushInterval = null,
    Object? includeStackTraces = null,
    Object? trackTiming = null,
  }) {
    return _then(_self.copyWith(
      sampleRate: null == sampleRate
          ? _self.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as double,
      bufferSize: null == bufferSize
          ? _self.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as int,
      flushInterval: null == flushInterval
          ? _self.flushInterval
          : flushInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      includeStackTraces: null == includeStackTraces
          ? _self.includeStackTraces
          : includeStackTraces // ignore: cast_nullable_to_non_nullable
              as bool,
      trackTiming: null == trackTiming
          ? _self.trackTiming
          : trackTiming // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [MetricsConfig].
extension MetricsConfigPatterns on MetricsConfig {
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
    TResult Function(_MetricsConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig() when $default != null:
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
    TResult Function(_MetricsConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig():
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
    TResult? Function(_MetricsConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig() when $default != null:
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
    TResult Function(double sampleRate, int bufferSize, Duration flushInterval,
            bool includeStackTraces, bool trackTiming)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig() when $default != null:
        return $default(_that.sampleRate, _that.bufferSize, _that.flushInterval,
            _that.includeStackTraces, _that.trackTiming);
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
    TResult Function(double sampleRate, int bufferSize, Duration flushInterval,
            bool includeStackTraces, bool trackTiming)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig():
        return $default(_that.sampleRate, _that.bufferSize, _that.flushInterval,
            _that.includeStackTraces, _that.trackTiming);
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
    TResult? Function(double sampleRate, int bufferSize, Duration flushInterval,
            bool includeStackTraces, bool trackTiming)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetricsConfig() when $default != null:
        return $default(_that.sampleRate, _that.bufferSize, _that.flushInterval,
            _that.includeStackTraces, _that.trackTiming);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MetricsConfig extends MetricsConfig {
  const _MetricsConfig(
      {this.sampleRate = 1.0,
      this.bufferSize = 100,
      this.flushInterval = const Duration(seconds: 30),
      this.includeStackTraces = true,
      this.trackTiming = true})
      : super._();

  /// Sample rate for metrics (0.0 to 1.0).
  ///
  /// - 1.0 = sample all operations (100%)
  /// - 0.5 = sample half of operations (50%)
  /// - 0.0 = sample none (disabled)
  @override
  @JsonKey()
  final double sampleRate;

  /// Buffer size for buffered reporters.
  ///
  /// When the buffer reaches this size, it will auto-flush.
  @override
  @JsonKey()
  final int bufferSize;

  /// Flush interval for buffered reporters.
  ///
  /// Metrics will be flushed at least this often.
  @override
  @JsonKey()
  final Duration flushInterval;

  /// Whether to include stack traces in error metrics.
  ///
  /// Set to false in production to reduce overhead and payload size.
  @override
  @JsonKey()
  final bool includeStackTraces;

  /// Whether to track timing for operations.
  ///
  /// When false, duration will be Duration.zero.
  @override
  @JsonKey()
  final bool trackTiming;

  /// Create a copy of MetricsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MetricsConfigCopyWith<_MetricsConfig> get copyWith =>
      __$MetricsConfigCopyWithImpl<_MetricsConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MetricsConfig &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate) &&
            (identical(other.bufferSize, bufferSize) ||
                other.bufferSize == bufferSize) &&
            (identical(other.flushInterval, flushInterval) ||
                other.flushInterval == flushInterval) &&
            (identical(other.includeStackTraces, includeStackTraces) ||
                other.includeStackTraces == includeStackTraces) &&
            (identical(other.trackTiming, trackTiming) ||
                other.trackTiming == trackTiming));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sampleRate, bufferSize,
      flushInterval, includeStackTraces, trackTiming);

  @override
  String toString() {
    return 'MetricsConfig(sampleRate: $sampleRate, bufferSize: $bufferSize, flushInterval: $flushInterval, includeStackTraces: $includeStackTraces, trackTiming: $trackTiming)';
  }
}

/// @nodoc
abstract mixin class _$MetricsConfigCopyWith<$Res>
    implements $MetricsConfigCopyWith<$Res> {
  factory _$MetricsConfigCopyWith(
          _MetricsConfig value, $Res Function(_MetricsConfig) _then) =
      __$MetricsConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double sampleRate,
      int bufferSize,
      Duration flushInterval,
      bool includeStackTraces,
      bool trackTiming});
}

/// @nodoc
class __$MetricsConfigCopyWithImpl<$Res>
    implements _$MetricsConfigCopyWith<$Res> {
  __$MetricsConfigCopyWithImpl(this._self, this._then);

  final _MetricsConfig _self;
  final $Res Function(_MetricsConfig) _then;

  /// Create a copy of MetricsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sampleRate = null,
    Object? bufferSize = null,
    Object? flushInterval = null,
    Object? includeStackTraces = null,
    Object? trackTiming = null,
  }) {
    return _then(_MetricsConfig(
      sampleRate: null == sampleRate
          ? _self.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as double,
      bufferSize: null == bufferSize
          ? _self.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as int,
      flushInterval: null == flushInterval
          ? _self.flushInterval
          : flushInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      includeStackTraces: null == includeStackTraces
          ? _self.includeStackTraces
          : includeStackTraces // ignore: cast_nullable_to_non_nullable
              as bool,
      trackTiming: null == trackTiming
          ? _self.trackTiming
          : trackTiming // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
