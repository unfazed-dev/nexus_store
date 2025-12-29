// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'component_health.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComponentHealth {
  /// Name of the component (e.g., 'backend', 'cache', 'sync').
  String get name;

  /// Health status of the component.
  HealthStatus get status;

  /// Time when this health check was performed.
  DateTime get checkedAt;

  /// Optional message describing the health state.
  String? get message;

  /// Time taken to perform the health check.
  Duration? get responseTime;

  /// Additional details about the component's health.
  Map<String, dynamic>? get details;

  /// Create a copy of ComponentHealth
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ComponentHealthCopyWith<ComponentHealth> get copyWith =>
      _$ComponentHealthCopyWithImpl<ComponentHealth>(
          this as ComponentHealth, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ComponentHealth &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.responseTime, responseTime) ||
                other.responseTime == responseTime) &&
            const DeepCollectionEquality().equals(other.details, details));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, status, checkedAt, message,
      responseTime, const DeepCollectionEquality().hash(details));

  @override
  String toString() {
    return 'ComponentHealth(name: $name, status: $status, checkedAt: $checkedAt, message: $message, responseTime: $responseTime, details: $details)';
  }
}

/// @nodoc
abstract mixin class $ComponentHealthCopyWith<$Res> {
  factory $ComponentHealthCopyWith(
          ComponentHealth value, $Res Function(ComponentHealth) _then) =
      _$ComponentHealthCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      HealthStatus status,
      DateTime checkedAt,
      String? message,
      Duration? responseTime,
      Map<String, dynamic>? details});
}

/// @nodoc
class _$ComponentHealthCopyWithImpl<$Res>
    implements $ComponentHealthCopyWith<$Res> {
  _$ComponentHealthCopyWithImpl(this._self, this._then);

  final ComponentHealth _self;
  final $Res Function(ComponentHealth) _then;

  /// Create a copy of ComponentHealth
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? status = null,
    Object? checkedAt = null,
    Object? message = freezed,
    Object? responseTime = freezed,
    Object? details = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as HealthStatus,
      checkedAt: null == checkedAt
          ? _self.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      responseTime: freezed == responseTime
          ? _self.responseTime
          : responseTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      details: freezed == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ComponentHealth].
extension ComponentHealthPatterns on ComponentHealth {
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
    TResult Function(_ComponentHealth value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth() when $default != null:
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
    TResult Function(_ComponentHealth value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth():
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
    TResult? Function(_ComponentHealth value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth() when $default != null:
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
            String name,
            HealthStatus status,
            DateTime checkedAt,
            String? message,
            Duration? responseTime,
            Map<String, dynamic>? details)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth() when $default != null:
        return $default(_that.name, _that.status, _that.checkedAt,
            _that.message, _that.responseTime, _that.details);
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
            String name,
            HealthStatus status,
            DateTime checkedAt,
            String? message,
            Duration? responseTime,
            Map<String, dynamic>? details)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth():
        return $default(_that.name, _that.status, _that.checkedAt,
            _that.message, _that.responseTime, _that.details);
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
            String name,
            HealthStatus status,
            DateTime checkedAt,
            String? message,
            Duration? responseTime,
            Map<String, dynamic>? details)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ComponentHealth() when $default != null:
        return $default(_that.name, _that.status, _that.checkedAt,
            _that.message, _that.responseTime, _that.details);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ComponentHealth extends ComponentHealth {
  const _ComponentHealth(
      {required this.name,
      required this.status,
      required this.checkedAt,
      this.message,
      this.responseTime,
      final Map<String, dynamic>? details})
      : _details = details,
        super._();

  /// Name of the component (e.g., 'backend', 'cache', 'sync').
  @override
  final String name;

  /// Health status of the component.
  @override
  final HealthStatus status;

  /// Time when this health check was performed.
  @override
  final DateTime checkedAt;

  /// Optional message describing the health state.
  @override
  final String? message;

  /// Time taken to perform the health check.
  @override
  final Duration? responseTime;

  /// Additional details about the component's health.
  final Map<String, dynamic>? _details;

  /// Additional details about the component's health.
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of ComponentHealth
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ComponentHealthCopyWith<_ComponentHealth> get copyWith =>
      __$ComponentHealthCopyWithImpl<_ComponentHealth>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ComponentHealth &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.responseTime, responseTime) ||
                other.responseTime == responseTime) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, status, checkedAt, message,
      responseTime, const DeepCollectionEquality().hash(_details));

  @override
  String toString() {
    return 'ComponentHealth(name: $name, status: $status, checkedAt: $checkedAt, message: $message, responseTime: $responseTime, details: $details)';
  }
}

/// @nodoc
abstract mixin class _$ComponentHealthCopyWith<$Res>
    implements $ComponentHealthCopyWith<$Res> {
  factory _$ComponentHealthCopyWith(
          _ComponentHealth value, $Res Function(_ComponentHealth) _then) =
      __$ComponentHealthCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      HealthStatus status,
      DateTime checkedAt,
      String? message,
      Duration? responseTime,
      Map<String, dynamic>? details});
}

/// @nodoc
class __$ComponentHealthCopyWithImpl<$Res>
    implements _$ComponentHealthCopyWith<$Res> {
  __$ComponentHealthCopyWithImpl(this._self, this._then);

  final _ComponentHealth _self;
  final $Res Function(_ComponentHealth) _then;

  /// Create a copy of ComponentHealth
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? status = null,
    Object? checkedAt = null,
    Object? message = freezed,
    Object? responseTime = freezed,
    Object? details = freezed,
  }) {
    return _then(_ComponentHealth(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as HealthStatus,
      checkedAt: null == checkedAt
          ? _self.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      responseTime: freezed == responseTime
          ? _self.responseTime
          : responseTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      details: freezed == details
          ? _self._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
mixin _$SystemHealth {
  /// Overall health status of the system.
  HealthStatus get overallStatus;

  /// Health status of individual components.
  List<ComponentHealth> get components;

  /// Time when this health check was performed.
  DateTime get checkedAt;

  /// Optional version string of the system.
  String? get version;

  /// Create a copy of SystemHealth
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SystemHealthCopyWith<SystemHealth> get copyWith =>
      _$SystemHealthCopyWithImpl<SystemHealth>(
          this as SystemHealth, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SystemHealth &&
            (identical(other.overallStatus, overallStatus) ||
                other.overallStatus == overallStatus) &&
            const DeepCollectionEquality()
                .equals(other.components, components) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt) &&
            (identical(other.version, version) || other.version == version));
  }

  @override
  int get hashCode => Object.hash(runtimeType, overallStatus,
      const DeepCollectionEquality().hash(components), checkedAt, version);

  @override
  String toString() {
    return 'SystemHealth(overallStatus: $overallStatus, components: $components, checkedAt: $checkedAt, version: $version)';
  }
}

/// @nodoc
abstract mixin class $SystemHealthCopyWith<$Res> {
  factory $SystemHealthCopyWith(
          SystemHealth value, $Res Function(SystemHealth) _then) =
      _$SystemHealthCopyWithImpl;
  @useResult
  $Res call(
      {HealthStatus overallStatus,
      List<ComponentHealth> components,
      DateTime checkedAt,
      String? version});
}

/// @nodoc
class _$SystemHealthCopyWithImpl<$Res> implements $SystemHealthCopyWith<$Res> {
  _$SystemHealthCopyWithImpl(this._self, this._then);

  final SystemHealth _self;
  final $Res Function(SystemHealth) _then;

  /// Create a copy of SystemHealth
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overallStatus = null,
    Object? components = null,
    Object? checkedAt = null,
    Object? version = freezed,
  }) {
    return _then(_self.copyWith(
      overallStatus: null == overallStatus
          ? _self.overallStatus
          : overallStatus // ignore: cast_nullable_to_non_nullable
              as HealthStatus,
      components: null == components
          ? _self.components
          : components // ignore: cast_nullable_to_non_nullable
              as List<ComponentHealth>,
      checkedAt: null == checkedAt
          ? _self.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: freezed == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SystemHealth].
extension SystemHealthPatterns on SystemHealth {
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
    TResult Function(_SystemHealth value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemHealth() when $default != null:
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
    TResult Function(_SystemHealth value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemHealth():
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
    TResult? Function(_SystemHealth value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemHealth() when $default != null:
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
            HealthStatus overallStatus,
            List<ComponentHealth> components,
            DateTime checkedAt,
            String? version)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemHealth() when $default != null:
        return $default(_that.overallStatus, _that.components, _that.checkedAt,
            _that.version);
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
            HealthStatus overallStatus,
            List<ComponentHealth> components,
            DateTime checkedAt,
            String? version)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemHealth():
        return $default(_that.overallStatus, _that.components, _that.checkedAt,
            _that.version);
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
            HealthStatus overallStatus,
            List<ComponentHealth> components,
            DateTime checkedAt,
            String? version)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemHealth() when $default != null:
        return $default(_that.overallStatus, _that.components, _that.checkedAt,
            _that.version);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SystemHealth extends SystemHealth {
  const _SystemHealth(
      {required this.overallStatus,
      required final List<ComponentHealth> components,
      required this.checkedAt,
      this.version})
      : _components = components,
        super._();

  /// Overall health status of the system.
  @override
  final HealthStatus overallStatus;

  /// Health status of individual components.
  final List<ComponentHealth> _components;

  /// Health status of individual components.
  @override
  List<ComponentHealth> get components {
    if (_components is EqualUnmodifiableListView) return _components;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_components);
  }

  /// Time when this health check was performed.
  @override
  final DateTime checkedAt;

  /// Optional version string of the system.
  @override
  final String? version;

  /// Create a copy of SystemHealth
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SystemHealthCopyWith<_SystemHealth> get copyWith =>
      __$SystemHealthCopyWithImpl<_SystemHealth>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SystemHealth &&
            (identical(other.overallStatus, overallStatus) ||
                other.overallStatus == overallStatus) &&
            const DeepCollectionEquality()
                .equals(other._components, _components) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt) &&
            (identical(other.version, version) || other.version == version));
  }

  @override
  int get hashCode => Object.hash(runtimeType, overallStatus,
      const DeepCollectionEquality().hash(_components), checkedAt, version);

  @override
  String toString() {
    return 'SystemHealth(overallStatus: $overallStatus, components: $components, checkedAt: $checkedAt, version: $version)';
  }
}

/// @nodoc
abstract mixin class _$SystemHealthCopyWith<$Res>
    implements $SystemHealthCopyWith<$Res> {
  factory _$SystemHealthCopyWith(
          _SystemHealth value, $Res Function(_SystemHealth) _then) =
      __$SystemHealthCopyWithImpl;
  @override
  @useResult
  $Res call(
      {HealthStatus overallStatus,
      List<ComponentHealth> components,
      DateTime checkedAt,
      String? version});
}

/// @nodoc
class __$SystemHealthCopyWithImpl<$Res>
    implements _$SystemHealthCopyWith<$Res> {
  __$SystemHealthCopyWithImpl(this._self, this._then);

  final _SystemHealth _self;
  final $Res Function(_SystemHealth) _then;

  /// Create a copy of SystemHealth
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? overallStatus = null,
    Object? components = null,
    Object? checkedAt = null,
    Object? version = freezed,
  }) {
    return _then(_SystemHealth(
      overallStatus: null == overallStatus
          ? _self.overallStatus
          : overallStatus // ignore: cast_nullable_to_non_nullable
              as HealthStatus,
      components: null == components
          ? _self._components
          : components // ignore: cast_nullable_to_non_nullable
              as List<ComponentHealth>,
      checkedAt: null == checkedAt
          ? _self.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: freezed == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
