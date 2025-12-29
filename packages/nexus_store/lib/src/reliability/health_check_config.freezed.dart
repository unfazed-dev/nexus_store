// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_check_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthCheckConfig {
  /// Interval between health checks.
  ///
  /// How often the health check service should check component health.
  /// Defaults to 30 seconds.
  Duration get checkInterval;

  /// Timeout for individual health checks.
  ///
  /// Maximum time to wait for a health check to complete before
  /// considering it failed. Defaults to 10 seconds.
  Duration get timeout;

  /// Number of consecutive failures before marking unhealthy.
  ///
  /// A component must fail this many consecutive checks before
  /// transitioning to unhealthy status. Defaults to 3.
  int get failureThreshold;

  /// Number of consecutive successes before marking healthy.
  ///
  /// A component must pass this many consecutive checks after
  /// being unhealthy before transitioning back to healthy. Defaults to 2.
  int get recoveryThreshold;

  /// Whether health checks are enabled.
  ///
  /// When false, no health checks are performed. Defaults to true.
  bool get enabled;

  /// Whether to start health checks automatically.
  ///
  /// When true, health checks begin when the service is initialized.
  /// Defaults to true.
  bool get autoStart;

  /// Create a copy of HealthCheckConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HealthCheckConfigCopyWith<HealthCheckConfig> get copyWith =>
      _$HealthCheckConfigCopyWithImpl<HealthCheckConfig>(
          this as HealthCheckConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HealthCheckConfig &&
            (identical(other.checkInterval, checkInterval) ||
                other.checkInterval == checkInterval) &&
            (identical(other.timeout, timeout) || other.timeout == timeout) &&
            (identical(other.failureThreshold, failureThreshold) ||
                other.failureThreshold == failureThreshold) &&
            (identical(other.recoveryThreshold, recoveryThreshold) ||
                other.recoveryThreshold == recoveryThreshold) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.autoStart, autoStart) ||
                other.autoStart == autoStart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, checkInterval, timeout,
      failureThreshold, recoveryThreshold, enabled, autoStart);

  @override
  String toString() {
    return 'HealthCheckConfig(checkInterval: $checkInterval, timeout: $timeout, failureThreshold: $failureThreshold, recoveryThreshold: $recoveryThreshold, enabled: $enabled, autoStart: $autoStart)';
  }
}

/// @nodoc
abstract mixin class $HealthCheckConfigCopyWith<$Res> {
  factory $HealthCheckConfigCopyWith(
          HealthCheckConfig value, $Res Function(HealthCheckConfig) _then) =
      _$HealthCheckConfigCopyWithImpl;
  @useResult
  $Res call(
      {Duration checkInterval,
      Duration timeout,
      int failureThreshold,
      int recoveryThreshold,
      bool enabled,
      bool autoStart});
}

/// @nodoc
class _$HealthCheckConfigCopyWithImpl<$Res>
    implements $HealthCheckConfigCopyWith<$Res> {
  _$HealthCheckConfigCopyWithImpl(this._self, this._then);

  final HealthCheckConfig _self;
  final $Res Function(HealthCheckConfig) _then;

  /// Create a copy of HealthCheckConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkInterval = null,
    Object? timeout = null,
    Object? failureThreshold = null,
    Object? recoveryThreshold = null,
    Object? enabled = null,
    Object? autoStart = null,
  }) {
    return _then(_self.copyWith(
      checkInterval: null == checkInterval
          ? _self.checkInterval
          : checkInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      timeout: null == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      failureThreshold: null == failureThreshold
          ? _self.failureThreshold
          : failureThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      recoveryThreshold: null == recoveryThreshold
          ? _self.recoveryThreshold
          : recoveryThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoStart: null == autoStart
          ? _self.autoStart
          : autoStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [HealthCheckConfig].
extension HealthCheckConfigPatterns on HealthCheckConfig {
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
    TResult Function(_HealthCheckConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig() when $default != null:
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
    TResult Function(_HealthCheckConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig():
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
    TResult? Function(_HealthCheckConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig() when $default != null:
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
            Duration checkInterval,
            Duration timeout,
            int failureThreshold,
            int recoveryThreshold,
            bool enabled,
            bool autoStart)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig() when $default != null:
        return $default(
            _that.checkInterval,
            _that.timeout,
            _that.failureThreshold,
            _that.recoveryThreshold,
            _that.enabled,
            _that.autoStart);
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
            Duration checkInterval,
            Duration timeout,
            int failureThreshold,
            int recoveryThreshold,
            bool enabled,
            bool autoStart)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig():
        return $default(
            _that.checkInterval,
            _that.timeout,
            _that.failureThreshold,
            _that.recoveryThreshold,
            _that.enabled,
            _that.autoStart);
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
            Duration checkInterval,
            Duration timeout,
            int failureThreshold,
            int recoveryThreshold,
            bool enabled,
            bool autoStart)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthCheckConfig() when $default != null:
        return $default(
            _that.checkInterval,
            _that.timeout,
            _that.failureThreshold,
            _that.recoveryThreshold,
            _that.enabled,
            _that.autoStart);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HealthCheckConfig extends HealthCheckConfig {
  const _HealthCheckConfig(
      {this.checkInterval = const Duration(seconds: 30),
      this.timeout = const Duration(seconds: 10),
      this.failureThreshold = 3,
      this.recoveryThreshold = 2,
      this.enabled = true,
      this.autoStart = true})
      : super._();

  /// Interval between health checks.
  ///
  /// How often the health check service should check component health.
  /// Defaults to 30 seconds.
  @override
  @JsonKey()
  final Duration checkInterval;

  /// Timeout for individual health checks.
  ///
  /// Maximum time to wait for a health check to complete before
  /// considering it failed. Defaults to 10 seconds.
  @override
  @JsonKey()
  final Duration timeout;

  /// Number of consecutive failures before marking unhealthy.
  ///
  /// A component must fail this many consecutive checks before
  /// transitioning to unhealthy status. Defaults to 3.
  @override
  @JsonKey()
  final int failureThreshold;

  /// Number of consecutive successes before marking healthy.
  ///
  /// A component must pass this many consecutive checks after
  /// being unhealthy before transitioning back to healthy. Defaults to 2.
  @override
  @JsonKey()
  final int recoveryThreshold;

  /// Whether health checks are enabled.
  ///
  /// When false, no health checks are performed. Defaults to true.
  @override
  @JsonKey()
  final bool enabled;

  /// Whether to start health checks automatically.
  ///
  /// When true, health checks begin when the service is initialized.
  /// Defaults to true.
  @override
  @JsonKey()
  final bool autoStart;

  /// Create a copy of HealthCheckConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HealthCheckConfigCopyWith<_HealthCheckConfig> get copyWith =>
      __$HealthCheckConfigCopyWithImpl<_HealthCheckConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HealthCheckConfig &&
            (identical(other.checkInterval, checkInterval) ||
                other.checkInterval == checkInterval) &&
            (identical(other.timeout, timeout) || other.timeout == timeout) &&
            (identical(other.failureThreshold, failureThreshold) ||
                other.failureThreshold == failureThreshold) &&
            (identical(other.recoveryThreshold, recoveryThreshold) ||
                other.recoveryThreshold == recoveryThreshold) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.autoStart, autoStart) ||
                other.autoStart == autoStart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, checkInterval, timeout,
      failureThreshold, recoveryThreshold, enabled, autoStart);

  @override
  String toString() {
    return 'HealthCheckConfig(checkInterval: $checkInterval, timeout: $timeout, failureThreshold: $failureThreshold, recoveryThreshold: $recoveryThreshold, enabled: $enabled, autoStart: $autoStart)';
  }
}

/// @nodoc
abstract mixin class _$HealthCheckConfigCopyWith<$Res>
    implements $HealthCheckConfigCopyWith<$Res> {
  factory _$HealthCheckConfigCopyWith(
          _HealthCheckConfig value, $Res Function(_HealthCheckConfig) _then) =
      __$HealthCheckConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Duration checkInterval,
      Duration timeout,
      int failureThreshold,
      int recoveryThreshold,
      bool enabled,
      bool autoStart});
}

/// @nodoc
class __$HealthCheckConfigCopyWithImpl<$Res>
    implements _$HealthCheckConfigCopyWith<$Res> {
  __$HealthCheckConfigCopyWithImpl(this._self, this._then);

  final _HealthCheckConfig _self;
  final $Res Function(_HealthCheckConfig) _then;

  /// Create a copy of HealthCheckConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? checkInterval = null,
    Object? timeout = null,
    Object? failureThreshold = null,
    Object? recoveryThreshold = null,
    Object? enabled = null,
    Object? autoStart = null,
  }) {
    return _then(_HealthCheckConfig(
      checkInterval: null == checkInterval
          ? _self.checkInterval
          : checkInterval // ignore: cast_nullable_to_non_nullable
              as Duration,
      timeout: null == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      failureThreshold: null == failureThreshold
          ? _self.failureThreshold
          : failureThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      recoveryThreshold: null == recoveryThreshold
          ? _self.recoveryThreshold
          : recoveryThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      autoStart: null == autoStart
          ? _self.autoStart
          : autoStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
