// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gdpr_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GdprConfig {
  /// Whether GDPR compliance is enabled.
  bool get enabled;

  /// Fields to pseudonymize instead of delete (for analytics).
  List<String> get pseudonymizeFields;

  /// Fields to retain even after erasure (for legal compliance).
  List<String> get retainedFields; // Data Minimization (REQ-026)
  /// Retention policies for automatic data minimization.
  List<RetentionPolicy> get retentionPolicies;

  /// Whether to automatically process retention policies.
  bool get autoProcessRetention;

  /// Interval between automatic retention checks.
  Duration? get retentionCheckInterval; // Consent Tracking (REQ-027)
  /// Whether consent tracking is enabled.
  bool get consentTracking;

  /// Required consent purposes that must be granted.
  Set<String> get requiredPurposes; // Breach Support (REQ-028)
  /// Whether breach notification support is enabled.
  bool get breachSupport;

  /// Webhook URLs for breach notifications.
  List<String>? get notificationWebhooks;

  /// Create a copy of GdprConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GdprConfigCopyWith<GdprConfig> get copyWith =>
      _$GdprConfigCopyWithImpl<GdprConfig>(this as GdprConfig, _$identity);

  /// Serializes this GdprConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GdprConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality()
                .equals(other.pseudonymizeFields, pseudonymizeFields) &&
            const DeepCollectionEquality()
                .equals(other.retainedFields, retainedFields) &&
            const DeepCollectionEquality()
                .equals(other.retentionPolicies, retentionPolicies) &&
            (identical(other.autoProcessRetention, autoProcessRetention) ||
                other.autoProcessRetention == autoProcessRetention) &&
            (identical(other.retentionCheckInterval, retentionCheckInterval) ||
                other.retentionCheckInterval == retentionCheckInterval) &&
            (identical(other.consentTracking, consentTracking) ||
                other.consentTracking == consentTracking) &&
            const DeepCollectionEquality()
                .equals(other.requiredPurposes, requiredPurposes) &&
            (identical(other.breachSupport, breachSupport) ||
                other.breachSupport == breachSupport) &&
            const DeepCollectionEquality()
                .equals(other.notificationWebhooks, notificationWebhooks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enabled,
      const DeepCollectionEquality().hash(pseudonymizeFields),
      const DeepCollectionEquality().hash(retainedFields),
      const DeepCollectionEquality().hash(retentionPolicies),
      autoProcessRetention,
      retentionCheckInterval,
      consentTracking,
      const DeepCollectionEquality().hash(requiredPurposes),
      breachSupport,
      const DeepCollectionEquality().hash(notificationWebhooks));

  @override
  String toString() {
    return 'GdprConfig(enabled: $enabled, pseudonymizeFields: $pseudonymizeFields, retainedFields: $retainedFields, retentionPolicies: $retentionPolicies, autoProcessRetention: $autoProcessRetention, retentionCheckInterval: $retentionCheckInterval, consentTracking: $consentTracking, requiredPurposes: $requiredPurposes, breachSupport: $breachSupport, notificationWebhooks: $notificationWebhooks)';
  }
}

/// @nodoc
abstract mixin class $GdprConfigCopyWith<$Res> {
  factory $GdprConfigCopyWith(
          GdprConfig value, $Res Function(GdprConfig) _then) =
      _$GdprConfigCopyWithImpl;
  @useResult
  $Res call(
      {bool enabled,
      List<String> pseudonymizeFields,
      List<String> retainedFields,
      List<RetentionPolicy> retentionPolicies,
      bool autoProcessRetention,
      Duration? retentionCheckInterval,
      bool consentTracking,
      Set<String> requiredPurposes,
      bool breachSupport,
      List<String>? notificationWebhooks});
}

/// @nodoc
class _$GdprConfigCopyWithImpl<$Res> implements $GdprConfigCopyWith<$Res> {
  _$GdprConfigCopyWithImpl(this._self, this._then);

  final GdprConfig _self;
  final $Res Function(GdprConfig) _then;

  /// Create a copy of GdprConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? pseudonymizeFields = null,
    Object? retainedFields = null,
    Object? retentionPolicies = null,
    Object? autoProcessRetention = null,
    Object? retentionCheckInterval = freezed,
    Object? consentTracking = null,
    Object? requiredPurposes = null,
    Object? breachSupport = null,
    Object? notificationWebhooks = freezed,
  }) {
    return _then(_self.copyWith(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      pseudonymizeFields: null == pseudonymizeFields
          ? _self.pseudonymizeFields
          : pseudonymizeFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      retainedFields: null == retainedFields
          ? _self.retainedFields
          : retainedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      retentionPolicies: null == retentionPolicies
          ? _self.retentionPolicies
          : retentionPolicies // ignore: cast_nullable_to_non_nullable
              as List<RetentionPolicy>,
      autoProcessRetention: null == autoProcessRetention
          ? _self.autoProcessRetention
          : autoProcessRetention // ignore: cast_nullable_to_non_nullable
              as bool,
      retentionCheckInterval: freezed == retentionCheckInterval
          ? _self.retentionCheckInterval
          : retentionCheckInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      consentTracking: null == consentTracking
          ? _self.consentTracking
          : consentTracking // ignore: cast_nullable_to_non_nullable
              as bool,
      requiredPurposes: null == requiredPurposes
          ? _self.requiredPurposes
          : requiredPurposes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      breachSupport: null == breachSupport
          ? _self.breachSupport
          : breachSupport // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationWebhooks: freezed == notificationWebhooks
          ? _self.notificationWebhooks
          : notificationWebhooks // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GdprConfig].
extension GdprConfigPatterns on GdprConfig {
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
    TResult Function(_GdprConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GdprConfig() when $default != null:
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
    TResult Function(_GdprConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GdprConfig():
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
    TResult? Function(_GdprConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GdprConfig() when $default != null:
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
            List<String> pseudonymizeFields,
            List<String> retainedFields,
            List<RetentionPolicy> retentionPolicies,
            bool autoProcessRetention,
            Duration? retentionCheckInterval,
            bool consentTracking,
            Set<String> requiredPurposes,
            bool breachSupport,
            List<String>? notificationWebhooks)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GdprConfig() when $default != null:
        return $default(
            _that.enabled,
            _that.pseudonymizeFields,
            _that.retainedFields,
            _that.retentionPolicies,
            _that.autoProcessRetention,
            _that.retentionCheckInterval,
            _that.consentTracking,
            _that.requiredPurposes,
            _that.breachSupport,
            _that.notificationWebhooks);
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
            List<String> pseudonymizeFields,
            List<String> retainedFields,
            List<RetentionPolicy> retentionPolicies,
            bool autoProcessRetention,
            Duration? retentionCheckInterval,
            bool consentTracking,
            Set<String> requiredPurposes,
            bool breachSupport,
            List<String>? notificationWebhooks)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GdprConfig():
        return $default(
            _that.enabled,
            _that.pseudonymizeFields,
            _that.retainedFields,
            _that.retentionPolicies,
            _that.autoProcessRetention,
            _that.retentionCheckInterval,
            _that.consentTracking,
            _that.requiredPurposes,
            _that.breachSupport,
            _that.notificationWebhooks);
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
            List<String> pseudonymizeFields,
            List<String> retainedFields,
            List<RetentionPolicy> retentionPolicies,
            bool autoProcessRetention,
            Duration? retentionCheckInterval,
            bool consentTracking,
            Set<String> requiredPurposes,
            bool breachSupport,
            List<String>? notificationWebhooks)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GdprConfig() when $default != null:
        return $default(
            _that.enabled,
            _that.pseudonymizeFields,
            _that.retainedFields,
            _that.retentionPolicies,
            _that.autoProcessRetention,
            _that.retentionCheckInterval,
            _that.consentTracking,
            _that.requiredPurposes,
            _that.breachSupport,
            _that.notificationWebhooks);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GdprConfig extends GdprConfig {
  const _GdprConfig(
      {this.enabled = true,
      final List<String> pseudonymizeFields = const [],
      final List<String> retainedFields = const [],
      final List<RetentionPolicy> retentionPolicies = const [],
      this.autoProcessRetention = false,
      this.retentionCheckInterval,
      this.consentTracking = false,
      final Set<String> requiredPurposes = const {},
      this.breachSupport = false,
      final List<String>? notificationWebhooks})
      : _pseudonymizeFields = pseudonymizeFields,
        _retainedFields = retainedFields,
        _retentionPolicies = retentionPolicies,
        _requiredPurposes = requiredPurposes,
        _notificationWebhooks = notificationWebhooks,
        super._();
  factory _GdprConfig.fromJson(Map<String, dynamic> json) =>
      _$GdprConfigFromJson(json);

  /// Whether GDPR compliance is enabled.
  @override
  @JsonKey()
  final bool enabled;

  /// Fields to pseudonymize instead of delete (for analytics).
  final List<String> _pseudonymizeFields;

  /// Fields to pseudonymize instead of delete (for analytics).
  @override
  @JsonKey()
  List<String> get pseudonymizeFields {
    if (_pseudonymizeFields is EqualUnmodifiableListView)
      return _pseudonymizeFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pseudonymizeFields);
  }

  /// Fields to retain even after erasure (for legal compliance).
  final List<String> _retainedFields;

  /// Fields to retain even after erasure (for legal compliance).
  @override
  @JsonKey()
  List<String> get retainedFields {
    if (_retainedFields is EqualUnmodifiableListView) return _retainedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_retainedFields);
  }

// Data Minimization (REQ-026)
  /// Retention policies for automatic data minimization.
  final List<RetentionPolicy> _retentionPolicies;
// Data Minimization (REQ-026)
  /// Retention policies for automatic data minimization.
  @override
  @JsonKey()
  List<RetentionPolicy> get retentionPolicies {
    if (_retentionPolicies is EqualUnmodifiableListView)
      return _retentionPolicies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_retentionPolicies);
  }

  /// Whether to automatically process retention policies.
  @override
  @JsonKey()
  final bool autoProcessRetention;

  /// Interval between automatic retention checks.
  @override
  final Duration? retentionCheckInterval;
// Consent Tracking (REQ-027)
  /// Whether consent tracking is enabled.
  @override
  @JsonKey()
  final bool consentTracking;

  /// Required consent purposes that must be granted.
  final Set<String> _requiredPurposes;

  /// Required consent purposes that must be granted.
  @override
  @JsonKey()
  Set<String> get requiredPurposes {
    if (_requiredPurposes is EqualUnmodifiableSetView) return _requiredPurposes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_requiredPurposes);
  }

// Breach Support (REQ-028)
  /// Whether breach notification support is enabled.
  @override
  @JsonKey()
  final bool breachSupport;

  /// Webhook URLs for breach notifications.
  final List<String>? _notificationWebhooks;

  /// Webhook URLs for breach notifications.
  @override
  List<String>? get notificationWebhooks {
    final value = _notificationWebhooks;
    if (value == null) return null;
    if (_notificationWebhooks is EqualUnmodifiableListView)
      return _notificationWebhooks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of GdprConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GdprConfigCopyWith<_GdprConfig> get copyWith =>
      __$GdprConfigCopyWithImpl<_GdprConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GdprConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GdprConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality()
                .equals(other._pseudonymizeFields, _pseudonymizeFields) &&
            const DeepCollectionEquality()
                .equals(other._retainedFields, _retainedFields) &&
            const DeepCollectionEquality()
                .equals(other._retentionPolicies, _retentionPolicies) &&
            (identical(other.autoProcessRetention, autoProcessRetention) ||
                other.autoProcessRetention == autoProcessRetention) &&
            (identical(other.retentionCheckInterval, retentionCheckInterval) ||
                other.retentionCheckInterval == retentionCheckInterval) &&
            (identical(other.consentTracking, consentTracking) ||
                other.consentTracking == consentTracking) &&
            const DeepCollectionEquality()
                .equals(other._requiredPurposes, _requiredPurposes) &&
            (identical(other.breachSupport, breachSupport) ||
                other.breachSupport == breachSupport) &&
            const DeepCollectionEquality()
                .equals(other._notificationWebhooks, _notificationWebhooks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enabled,
      const DeepCollectionEquality().hash(_pseudonymizeFields),
      const DeepCollectionEquality().hash(_retainedFields),
      const DeepCollectionEquality().hash(_retentionPolicies),
      autoProcessRetention,
      retentionCheckInterval,
      consentTracking,
      const DeepCollectionEquality().hash(_requiredPurposes),
      breachSupport,
      const DeepCollectionEquality().hash(_notificationWebhooks));

  @override
  String toString() {
    return 'GdprConfig(enabled: $enabled, pseudonymizeFields: $pseudonymizeFields, retainedFields: $retainedFields, retentionPolicies: $retentionPolicies, autoProcessRetention: $autoProcessRetention, retentionCheckInterval: $retentionCheckInterval, consentTracking: $consentTracking, requiredPurposes: $requiredPurposes, breachSupport: $breachSupport, notificationWebhooks: $notificationWebhooks)';
  }
}

/// @nodoc
abstract mixin class _$GdprConfigCopyWith<$Res>
    implements $GdprConfigCopyWith<$Res> {
  factory _$GdprConfigCopyWith(
          _GdprConfig value, $Res Function(_GdprConfig) _then) =
      __$GdprConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enabled,
      List<String> pseudonymizeFields,
      List<String> retainedFields,
      List<RetentionPolicy> retentionPolicies,
      bool autoProcessRetention,
      Duration? retentionCheckInterval,
      bool consentTracking,
      Set<String> requiredPurposes,
      bool breachSupport,
      List<String>? notificationWebhooks});
}

/// @nodoc
class __$GdprConfigCopyWithImpl<$Res> implements _$GdprConfigCopyWith<$Res> {
  __$GdprConfigCopyWithImpl(this._self, this._then);

  final _GdprConfig _self;
  final $Res Function(_GdprConfig) _then;

  /// Create a copy of GdprConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? pseudonymizeFields = null,
    Object? retainedFields = null,
    Object? retentionPolicies = null,
    Object? autoProcessRetention = null,
    Object? retentionCheckInterval = freezed,
    Object? consentTracking = null,
    Object? requiredPurposes = null,
    Object? breachSupport = null,
    Object? notificationWebhooks = freezed,
  }) {
    return _then(_GdprConfig(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      pseudonymizeFields: null == pseudonymizeFields
          ? _self._pseudonymizeFields
          : pseudonymizeFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      retainedFields: null == retainedFields
          ? _self._retainedFields
          : retainedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      retentionPolicies: null == retentionPolicies
          ? _self._retentionPolicies
          : retentionPolicies // ignore: cast_nullable_to_non_nullable
              as List<RetentionPolicy>,
      autoProcessRetention: null == autoProcessRetention
          ? _self.autoProcessRetention
          : autoProcessRetention // ignore: cast_nullable_to_non_nullable
              as bool,
      retentionCheckInterval: freezed == retentionCheckInterval
          ? _self.retentionCheckInterval
          : retentionCheckInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      consentTracking: null == consentTracking
          ? _self.consentTracking
          : consentTracking // ignore: cast_nullable_to_non_nullable
              as bool,
      requiredPurposes: null == requiredPurposes
          ? _self._requiredPurposes
          : requiredPurposes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      breachSupport: null == breachSupport
          ? _self.breachSupport
          : breachSupport // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationWebhooks: freezed == notificationWebhooks
          ? _self._notificationWebhooks
          : notificationWebhooks // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

// dart format on
