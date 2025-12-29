// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'circuit_breaker_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CircuitBreakerConfig {
  /// Number of consecutive failures before opening the circuit.
  ///
  /// When this many failures occur, the circuit breaker transitions from
  /// closed to open, blocking all subsequent requests. Defaults to 5.
  int get failureThreshold;

  /// Number of consecutive successes needed to close the circuit.
  ///
  /// When in half-open state, this many successful requests must occur
  /// before transitioning back to closed. Defaults to 3.
  int get successThreshold;

  /// Duration the circuit stays open before transitioning to half-open.
  ///
  /// After this cooldown period, the circuit breaker allows a limited
  /// number of test requests. Defaults to 30 seconds.
  Duration get openDuration;

  /// Maximum concurrent requests allowed in half-open state.
  ///
  /// Limits the number of test requests during recovery to prevent
  /// overwhelming a recovering service. Defaults to 3.
  int get halfOpenMaxRequests;

  /// Whether the circuit breaker is enabled.
  ///
  /// When false, all requests pass through without circuit breaker
  /// protection. Defaults to true.
  bool get enabled;

  /// Create a copy of CircuitBreakerConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CircuitBreakerConfigCopyWith<CircuitBreakerConfig> get copyWith =>
      _$CircuitBreakerConfigCopyWithImpl<CircuitBreakerConfig>(
          this as CircuitBreakerConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CircuitBreakerConfig &&
            (identical(other.failureThreshold, failureThreshold) ||
                other.failureThreshold == failureThreshold) &&
            (identical(other.successThreshold, successThreshold) ||
                other.successThreshold == successThreshold) &&
            (identical(other.openDuration, openDuration) ||
                other.openDuration == openDuration) &&
            (identical(other.halfOpenMaxRequests, halfOpenMaxRequests) ||
                other.halfOpenMaxRequests == halfOpenMaxRequests) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failureThreshold,
      successThreshold, openDuration, halfOpenMaxRequests, enabled);

  @override
  String toString() {
    return 'CircuitBreakerConfig(failureThreshold: $failureThreshold, successThreshold: $successThreshold, openDuration: $openDuration, halfOpenMaxRequests: $halfOpenMaxRequests, enabled: $enabled)';
  }
}

/// @nodoc
abstract mixin class $CircuitBreakerConfigCopyWith<$Res> {
  factory $CircuitBreakerConfigCopyWith(CircuitBreakerConfig value,
          $Res Function(CircuitBreakerConfig) _then) =
      _$CircuitBreakerConfigCopyWithImpl;
  @useResult
  $Res call(
      {int failureThreshold,
      int successThreshold,
      Duration openDuration,
      int halfOpenMaxRequests,
      bool enabled});
}

/// @nodoc
class _$CircuitBreakerConfigCopyWithImpl<$Res>
    implements $CircuitBreakerConfigCopyWith<$Res> {
  _$CircuitBreakerConfigCopyWithImpl(this._self, this._then);

  final CircuitBreakerConfig _self;
  final $Res Function(CircuitBreakerConfig) _then;

  /// Create a copy of CircuitBreakerConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? failureThreshold = null,
    Object? successThreshold = null,
    Object? openDuration = null,
    Object? halfOpenMaxRequests = null,
    Object? enabled = null,
  }) {
    return _then(_self.copyWith(
      failureThreshold: null == failureThreshold
          ? _self.failureThreshold
          : failureThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      successThreshold: null == successThreshold
          ? _self.successThreshold
          : successThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      openDuration: null == openDuration
          ? _self.openDuration
          : openDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      halfOpenMaxRequests: null == halfOpenMaxRequests
          ? _self.halfOpenMaxRequests
          : halfOpenMaxRequests // ignore: cast_nullable_to_non_nullable
              as int,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [CircuitBreakerConfig].
extension CircuitBreakerConfigPatterns on CircuitBreakerConfig {
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
    TResult Function(_CircuitBreakerConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig() when $default != null:
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
    TResult Function(_CircuitBreakerConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig():
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
    TResult? Function(_CircuitBreakerConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig() when $default != null:
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
    TResult Function(int failureThreshold, int successThreshold,
            Duration openDuration, int halfOpenMaxRequests, bool enabled)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig() when $default != null:
        return $default(_that.failureThreshold, _that.successThreshold,
            _that.openDuration, _that.halfOpenMaxRequests, _that.enabled);
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
    TResult Function(int failureThreshold, int successThreshold,
            Duration openDuration, int halfOpenMaxRequests, bool enabled)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig():
        return $default(_that.failureThreshold, _that.successThreshold,
            _that.openDuration, _that.halfOpenMaxRequests, _that.enabled);
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
    TResult? Function(int failureThreshold, int successThreshold,
            Duration openDuration, int halfOpenMaxRequests, bool enabled)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CircuitBreakerConfig() when $default != null:
        return $default(_that.failureThreshold, _that.successThreshold,
            _that.openDuration, _that.halfOpenMaxRequests, _that.enabled);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CircuitBreakerConfig extends CircuitBreakerConfig {
  const _CircuitBreakerConfig(
      {this.failureThreshold = 5,
      this.successThreshold = 3,
      this.openDuration = const Duration(seconds: 30),
      this.halfOpenMaxRequests = 3,
      this.enabled = true})
      : super._();

  /// Number of consecutive failures before opening the circuit.
  ///
  /// When this many failures occur, the circuit breaker transitions from
  /// closed to open, blocking all subsequent requests. Defaults to 5.
  @override
  @JsonKey()
  final int failureThreshold;

  /// Number of consecutive successes needed to close the circuit.
  ///
  /// When in half-open state, this many successful requests must occur
  /// before transitioning back to closed. Defaults to 3.
  @override
  @JsonKey()
  final int successThreshold;

  /// Duration the circuit stays open before transitioning to half-open.
  ///
  /// After this cooldown period, the circuit breaker allows a limited
  /// number of test requests. Defaults to 30 seconds.
  @override
  @JsonKey()
  final Duration openDuration;

  /// Maximum concurrent requests allowed in half-open state.
  ///
  /// Limits the number of test requests during recovery to prevent
  /// overwhelming a recovering service. Defaults to 3.
  @override
  @JsonKey()
  final int halfOpenMaxRequests;

  /// Whether the circuit breaker is enabled.
  ///
  /// When false, all requests pass through without circuit breaker
  /// protection. Defaults to true.
  @override
  @JsonKey()
  final bool enabled;

  /// Create a copy of CircuitBreakerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CircuitBreakerConfigCopyWith<_CircuitBreakerConfig> get copyWith =>
      __$CircuitBreakerConfigCopyWithImpl<_CircuitBreakerConfig>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CircuitBreakerConfig &&
            (identical(other.failureThreshold, failureThreshold) ||
                other.failureThreshold == failureThreshold) &&
            (identical(other.successThreshold, successThreshold) ||
                other.successThreshold == successThreshold) &&
            (identical(other.openDuration, openDuration) ||
                other.openDuration == openDuration) &&
            (identical(other.halfOpenMaxRequests, halfOpenMaxRequests) ||
                other.halfOpenMaxRequests == halfOpenMaxRequests) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failureThreshold,
      successThreshold, openDuration, halfOpenMaxRequests, enabled);

  @override
  String toString() {
    return 'CircuitBreakerConfig(failureThreshold: $failureThreshold, successThreshold: $successThreshold, openDuration: $openDuration, halfOpenMaxRequests: $halfOpenMaxRequests, enabled: $enabled)';
  }
}

/// @nodoc
abstract mixin class _$CircuitBreakerConfigCopyWith<$Res>
    implements $CircuitBreakerConfigCopyWith<$Res> {
  factory _$CircuitBreakerConfigCopyWith(_CircuitBreakerConfig value,
          $Res Function(_CircuitBreakerConfig) _then) =
      __$CircuitBreakerConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int failureThreshold,
      int successThreshold,
      Duration openDuration,
      int halfOpenMaxRequests,
      bool enabled});
}

/// @nodoc
class __$CircuitBreakerConfigCopyWithImpl<$Res>
    implements _$CircuitBreakerConfigCopyWith<$Res> {
  __$CircuitBreakerConfigCopyWithImpl(this._self, this._then);

  final _CircuitBreakerConfig _self;
  final $Res Function(_CircuitBreakerConfig) _then;

  /// Create a copy of CircuitBreakerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? failureThreshold = null,
    Object? successThreshold = null,
    Object? openDuration = null,
    Object? halfOpenMaxRequests = null,
    Object? enabled = null,
  }) {
    return _then(_CircuitBreakerConfig(
      failureThreshold: null == failureThreshold
          ? _self.failureThreshold
          : failureThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      successThreshold: null == successThreshold
          ? _self.successThreshold
          : successThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      openDuration: null == openDuration
          ? _self.openDuration
          : openDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      halfOpenMaxRequests: null == halfOpenMaxRequests
          ? _self.halfOpenMaxRequests
          : halfOpenMaxRequests // ignore: cast_nullable_to_non_nullable
              as int,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
