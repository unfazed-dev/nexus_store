// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'degradation_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DegradationConfig {
  /// Whether degradation handling is enabled.
  ///
  /// When false, no automatic degradation occurs. Defaults to true.
  bool get enabled;

  /// Whether automatic degradation is enabled.
  ///
  /// When true, the system automatically degrades based on
  /// component health and circuit breaker state. Defaults to true.
  bool get autoDegradation;

  /// Default operational mode.
  ///
  /// The mode to use when the system is functioning normally.
  /// Defaults to [DegradationMode.normal].
  DegradationMode get defaultMode;

  /// Fallback mode when degradation occurs.
  ///
  /// The mode to switch to when automatic degradation triggers.
  /// Defaults to [DegradationMode.cacheOnly].
  DegradationMode get fallbackMode;

  /// Cooldown period before attempting recovery.
  ///
  /// After degrading, the system waits this long before attempting
  /// to return to normal operation. Defaults to 60 seconds.
  Duration get cooldown;

  /// Create a copy of DegradationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DegradationConfigCopyWith<DegradationConfig> get copyWith =>
      _$DegradationConfigCopyWithImpl<DegradationConfig>(
          this as DegradationConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DegradationConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.autoDegradation, autoDegradation) ||
                other.autoDegradation == autoDegradation) &&
            (identical(other.defaultMode, defaultMode) ||
                other.defaultMode == defaultMode) &&
            (identical(other.fallbackMode, fallbackMode) ||
                other.fallbackMode == fallbackMode) &&
            (identical(other.cooldown, cooldown) ||
                other.cooldown == cooldown));
  }

  @override
  int get hashCode => Object.hash(runtimeType, enabled, autoDegradation,
      defaultMode, fallbackMode, cooldown);

  @override
  String toString() {
    return 'DegradationConfig(enabled: $enabled, autoDegradation: $autoDegradation, defaultMode: $defaultMode, fallbackMode: $fallbackMode, cooldown: $cooldown)';
  }
}

/// @nodoc
abstract mixin class $DegradationConfigCopyWith<$Res> {
  factory $DegradationConfigCopyWith(
          DegradationConfig value, $Res Function(DegradationConfig) _then) =
      _$DegradationConfigCopyWithImpl;
  @useResult
  $Res call(
      {bool enabled,
      bool autoDegradation,
      DegradationMode defaultMode,
      DegradationMode fallbackMode,
      Duration cooldown});
}

/// @nodoc
class _$DegradationConfigCopyWithImpl<$Res>
    implements $DegradationConfigCopyWith<$Res> {
  _$DegradationConfigCopyWithImpl(this._self, this._then);

  final DegradationConfig _self;
  final $Res Function(DegradationConfig) _then;

  /// Create a copy of DegradationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? autoDegradation = null,
    Object? defaultMode = null,
    Object? fallbackMode = null,
    Object? cooldown = null,
  }) {
    return _then(_self.copyWith(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoDegradation: null == autoDegradation
          ? _self.autoDegradation
          : autoDegradation // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultMode: null == defaultMode
          ? _self.defaultMode
          : defaultMode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      fallbackMode: null == fallbackMode
          ? _self.fallbackMode
          : fallbackMode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      cooldown: null == cooldown
          ? _self.cooldown
          : cooldown // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// Adds pattern-matching-related methods to [DegradationConfig].
extension DegradationConfigPatterns on DegradationConfig {
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
    TResult Function(_DegradationConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig() when $default != null:
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
    TResult Function(_DegradationConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig():
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
    TResult? Function(_DegradationConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig() when $default != null:
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
            bool enabled,
            bool autoDegradation,
            DegradationMode defaultMode,
            DegradationMode fallbackMode,
            Duration cooldown)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig() when $default != null:
        return $default(_that.enabled, _that.autoDegradation, _that.defaultMode,
            _that.fallbackMode, _that.cooldown);
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
            bool enabled,
            bool autoDegradation,
            DegradationMode defaultMode,
            DegradationMode fallbackMode,
            Duration cooldown)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig():
        return $default(_that.enabled, _that.autoDegradation, _that.defaultMode,
            _that.fallbackMode, _that.cooldown);
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
            bool enabled,
            bool autoDegradation,
            DegradationMode defaultMode,
            DegradationMode fallbackMode,
            Duration cooldown)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationConfig() when $default != null:
        return $default(_that.enabled, _that.autoDegradation, _that.defaultMode,
            _that.fallbackMode, _that.cooldown);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DegradationConfig extends DegradationConfig {
  const _DegradationConfig(
      {this.enabled = true,
      this.autoDegradation = true,
      this.defaultMode = DegradationMode.normal,
      this.fallbackMode = DegradationMode.cacheOnly,
      this.cooldown = const Duration(seconds: 60)})
      : super._();

  /// Whether degradation handling is enabled.
  ///
  /// When false, no automatic degradation occurs. Defaults to true.
  @override
  @JsonKey()
  final bool enabled;

  /// Whether automatic degradation is enabled.
  ///
  /// When true, the system automatically degrades based on
  /// component health and circuit breaker state. Defaults to true.
  @override
  @JsonKey()
  final bool autoDegradation;

  /// Default operational mode.
  ///
  /// The mode to use when the system is functioning normally.
  /// Defaults to [DegradationMode.normal].
  @override
  @JsonKey()
  final DegradationMode defaultMode;

  /// Fallback mode when degradation occurs.
  ///
  /// The mode to switch to when automatic degradation triggers.
  /// Defaults to [DegradationMode.cacheOnly].
  @override
  @JsonKey()
  final DegradationMode fallbackMode;

  /// Cooldown period before attempting recovery.
  ///
  /// After degrading, the system waits this long before attempting
  /// to return to normal operation. Defaults to 60 seconds.
  @override
  @JsonKey()
  final Duration cooldown;

  /// Create a copy of DegradationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DegradationConfigCopyWith<_DegradationConfig> get copyWith =>
      __$DegradationConfigCopyWithImpl<_DegradationConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DegradationConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.autoDegradation, autoDegradation) ||
                other.autoDegradation == autoDegradation) &&
            (identical(other.defaultMode, defaultMode) ||
                other.defaultMode == defaultMode) &&
            (identical(other.fallbackMode, fallbackMode) ||
                other.fallbackMode == fallbackMode) &&
            (identical(other.cooldown, cooldown) ||
                other.cooldown == cooldown));
  }

  @override
  int get hashCode => Object.hash(runtimeType, enabled, autoDegradation,
      defaultMode, fallbackMode, cooldown);

  @override
  String toString() {
    return 'DegradationConfig(enabled: $enabled, autoDegradation: $autoDegradation, defaultMode: $defaultMode, fallbackMode: $fallbackMode, cooldown: $cooldown)';
  }
}

/// @nodoc
abstract mixin class _$DegradationConfigCopyWith<$Res>
    implements $DegradationConfigCopyWith<$Res> {
  factory _$DegradationConfigCopyWith(
          _DegradationConfig value, $Res Function(_DegradationConfig) _then) =
      __$DegradationConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enabled,
      bool autoDegradation,
      DegradationMode defaultMode,
      DegradationMode fallbackMode,
      Duration cooldown});
}

/// @nodoc
class __$DegradationConfigCopyWithImpl<$Res>
    implements _$DegradationConfigCopyWith<$Res> {
  __$DegradationConfigCopyWithImpl(this._self, this._then);

  final _DegradationConfig _self;
  final $Res Function(_DegradationConfig) _then;

  /// Create a copy of DegradationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? autoDegradation = null,
    Object? defaultMode = null,
    Object? fallbackMode = null,
    Object? cooldown = null,
  }) {
    return _then(_DegradationConfig(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoDegradation: null == autoDegradation
          ? _self.autoDegradation
          : autoDegradation // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultMode: null == defaultMode
          ? _self.defaultMode
          : defaultMode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      fallbackMode: null == fallbackMode
          ? _self.fallbackMode
          : fallbackMode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      cooldown: null == cooldown
          ? _self.cooldown
          : cooldown // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// @nodoc
mixin _$DegradationMetrics {
  /// Current degradation mode.
  DegradationMode get mode;

  /// Timestamp when this snapshot was taken.
  DateTime get timestamp;

  /// Number of times the system has degraded.
  int get degradationCount;

  /// Number of times the system has recovered.
  int get recoveryCount;

  /// Timestamp of the last mode change.
  DateTime? get lastModeChange;

  /// Create a copy of DegradationMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DegradationMetricsCopyWith<DegradationMetrics> get copyWith =>
      _$DegradationMetricsCopyWithImpl<DegradationMetrics>(
          this as DegradationMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DegradationMetrics &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.degradationCount, degradationCount) ||
                other.degradationCount == degradationCount) &&
            (identical(other.recoveryCount, recoveryCount) ||
                other.recoveryCount == recoveryCount) &&
            (identical(other.lastModeChange, lastModeChange) ||
                other.lastModeChange == lastModeChange));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mode, timestamp,
      degradationCount, recoveryCount, lastModeChange);

  @override
  String toString() {
    return 'DegradationMetrics(mode: $mode, timestamp: $timestamp, degradationCount: $degradationCount, recoveryCount: $recoveryCount, lastModeChange: $lastModeChange)';
  }
}

/// @nodoc
abstract mixin class $DegradationMetricsCopyWith<$Res> {
  factory $DegradationMetricsCopyWith(
          DegradationMetrics value, $Res Function(DegradationMetrics) _then) =
      _$DegradationMetricsCopyWithImpl;
  @useResult
  $Res call(
      {DegradationMode mode,
      DateTime timestamp,
      int degradationCount,
      int recoveryCount,
      DateTime? lastModeChange});
}

/// @nodoc
class _$DegradationMetricsCopyWithImpl<$Res>
    implements $DegradationMetricsCopyWith<$Res> {
  _$DegradationMetricsCopyWithImpl(this._self, this._then);

  final DegradationMetrics _self;
  final $Res Function(DegradationMetrics) _then;

  /// Create a copy of DegradationMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? timestamp = null,
    Object? degradationCount = null,
    Object? recoveryCount = null,
    Object? lastModeChange = freezed,
  }) {
    return _then(_self.copyWith(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      degradationCount: null == degradationCount
          ? _self.degradationCount
          : degradationCount // ignore: cast_nullable_to_non_nullable
              as int,
      recoveryCount: null == recoveryCount
          ? _self.recoveryCount
          : recoveryCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastModeChange: freezed == lastModeChange
          ? _self.lastModeChange
          : lastModeChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DegradationMetrics].
extension DegradationMetricsPatterns on DegradationMetrics {
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
    TResult Function(_DegradationMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics() when $default != null:
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
    TResult Function(_DegradationMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics():
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
    TResult? Function(_DegradationMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics() when $default != null:
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
    TResult Function(DegradationMode mode, DateTime timestamp,
            int degradationCount, int recoveryCount, DateTime? lastModeChange)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics() when $default != null:
        return $default(_that.mode, _that.timestamp, _that.degradationCount,
            _that.recoveryCount, _that.lastModeChange);
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
    TResult Function(DegradationMode mode, DateTime timestamp,
            int degradationCount, int recoveryCount, DateTime? lastModeChange)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics():
        return $default(_that.mode, _that.timestamp, _that.degradationCount,
            _that.recoveryCount, _that.lastModeChange);
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
    TResult? Function(DegradationMode mode, DateTime timestamp,
            int degradationCount, int recoveryCount, DateTime? lastModeChange)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DegradationMetrics() when $default != null:
        return $default(_that.mode, _that.timestamp, _that.degradationCount,
            _that.recoveryCount, _that.lastModeChange);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DegradationMetrics extends DegradationMetrics {
  const _DegradationMetrics(
      {required this.mode,
      required this.timestamp,
      this.degradationCount = 0,
      this.recoveryCount = 0,
      this.lastModeChange})
      : super._();

  /// Current degradation mode.
  @override
  final DegradationMode mode;

  /// Timestamp when this snapshot was taken.
  @override
  final DateTime timestamp;

  /// Number of times the system has degraded.
  @override
  @JsonKey()
  final int degradationCount;

  /// Number of times the system has recovered.
  @override
  @JsonKey()
  final int recoveryCount;

  /// Timestamp of the last mode change.
  @override
  final DateTime? lastModeChange;

  /// Create a copy of DegradationMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DegradationMetricsCopyWith<_DegradationMetrics> get copyWith =>
      __$DegradationMetricsCopyWithImpl<_DegradationMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DegradationMetrics &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.degradationCount, degradationCount) ||
                other.degradationCount == degradationCount) &&
            (identical(other.recoveryCount, recoveryCount) ||
                other.recoveryCount == recoveryCount) &&
            (identical(other.lastModeChange, lastModeChange) ||
                other.lastModeChange == lastModeChange));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mode, timestamp,
      degradationCount, recoveryCount, lastModeChange);

  @override
  String toString() {
    return 'DegradationMetrics(mode: $mode, timestamp: $timestamp, degradationCount: $degradationCount, recoveryCount: $recoveryCount, lastModeChange: $lastModeChange)';
  }
}

/// @nodoc
abstract mixin class _$DegradationMetricsCopyWith<$Res>
    implements $DegradationMetricsCopyWith<$Res> {
  factory _$DegradationMetricsCopyWith(
          _DegradationMetrics value, $Res Function(_DegradationMetrics) _then) =
      __$DegradationMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DegradationMode mode,
      DateTime timestamp,
      int degradationCount,
      int recoveryCount,
      DateTime? lastModeChange});
}

/// @nodoc
class __$DegradationMetricsCopyWithImpl<$Res>
    implements _$DegradationMetricsCopyWith<$Res> {
  __$DegradationMetricsCopyWithImpl(this._self, this._then);

  final _DegradationMetrics _self;
  final $Res Function(_DegradationMetrics) _then;

  /// Create a copy of DegradationMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? timestamp = null,
    Object? degradationCount = null,
    Object? recoveryCount = null,
    Object? lastModeChange = freezed,
  }) {
    return _then(_DegradationMetrics(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as DegradationMode,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      degradationCount: null == degradationCount
          ? _self.degradationCount
          : degradationCount // ignore: cast_nullable_to_non_nullable
              as int,
      recoveryCount: null == recoveryCount
          ? _self.recoveryCount
          : recoveryCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastModeChange: freezed == lastModeChange
          ? _self.lastModeChange
          : lastModeChange // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
