// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retention_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RetentionPolicy {
  /// The field name to apply this policy to.
  String get field;

  /// How long to retain the data.
  Duration get duration;

  /// What action to take when the retention period expires.
  RetentionAction get action;

  /// Optional condition expression for when to apply this policy.
  /// If null, the policy applies unconditionally.
  String? get condition;

  /// Create a copy of RetentionPolicy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RetentionPolicyCopyWith<RetentionPolicy> get copyWith =>
      _$RetentionPolicyCopyWithImpl<RetentionPolicy>(
          this as RetentionPolicy, _$identity);

  /// Serializes this RetentionPolicy to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RetentionPolicy &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.condition, condition) ||
                other.condition == condition));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, field, duration, action, condition);

  @override
  String toString() {
    return 'RetentionPolicy(field: $field, duration: $duration, action: $action, condition: $condition)';
  }
}

/// @nodoc
abstract mixin class $RetentionPolicyCopyWith<$Res> {
  factory $RetentionPolicyCopyWith(
          RetentionPolicy value, $Res Function(RetentionPolicy) _then) =
      _$RetentionPolicyCopyWithImpl;
  @useResult
  $Res call(
      {String field,
      Duration duration,
      RetentionAction action,
      String? condition});
}

/// @nodoc
class _$RetentionPolicyCopyWithImpl<$Res>
    implements $RetentionPolicyCopyWith<$Res> {
  _$RetentionPolicyCopyWithImpl(this._self, this._then);

  final RetentionPolicy _self;
  final $Res Function(RetentionPolicy) _then;

  /// Create a copy of RetentionPolicy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? duration = null,
    Object? action = null,
    Object? condition = freezed,
  }) {
    return _then(_self.copyWith(
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as RetentionAction,
      condition: freezed == condition
          ? _self.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RetentionPolicy].
extension RetentionPolicyPatterns on RetentionPolicy {
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
    TResult Function(_RetentionPolicy value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy() when $default != null:
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
    TResult Function(_RetentionPolicy value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy():
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
    TResult? Function(_RetentionPolicy value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy() when $default != null:
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
    TResult Function(String field, Duration duration, RetentionAction action,
            String? condition)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy() when $default != null:
        return $default(
            _that.field, _that.duration, _that.action, _that.condition);
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
    TResult Function(String field, Duration duration, RetentionAction action,
            String? condition)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy():
        return $default(
            _that.field, _that.duration, _that.action, _that.condition);
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
    TResult? Function(String field, Duration duration, RetentionAction action,
            String? condition)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionPolicy() when $default != null:
        return $default(
            _that.field, _that.duration, _that.action, _that.condition);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RetentionPolicy extends RetentionPolicy {
  const _RetentionPolicy(
      {required this.field,
      required this.duration,
      required this.action,
      this.condition})
      : super._();
  factory _RetentionPolicy.fromJson(Map<String, dynamic> json) =>
      _$RetentionPolicyFromJson(json);

  /// The field name to apply this policy to.
  @override
  final String field;

  /// How long to retain the data.
  @override
  final Duration duration;

  /// What action to take when the retention period expires.
  @override
  final RetentionAction action;

  /// Optional condition expression for when to apply this policy.
  /// If null, the policy applies unconditionally.
  @override
  final String? condition;

  /// Create a copy of RetentionPolicy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RetentionPolicyCopyWith<_RetentionPolicy> get copyWith =>
      __$RetentionPolicyCopyWithImpl<_RetentionPolicy>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RetentionPolicyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RetentionPolicy &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.condition, condition) ||
                other.condition == condition));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, field, duration, action, condition);

  @override
  String toString() {
    return 'RetentionPolicy(field: $field, duration: $duration, action: $action, condition: $condition)';
  }
}

/// @nodoc
abstract mixin class _$RetentionPolicyCopyWith<$Res>
    implements $RetentionPolicyCopyWith<$Res> {
  factory _$RetentionPolicyCopyWith(
          _RetentionPolicy value, $Res Function(_RetentionPolicy) _then) =
      __$RetentionPolicyCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String field,
      Duration duration,
      RetentionAction action,
      String? condition});
}

/// @nodoc
class __$RetentionPolicyCopyWithImpl<$Res>
    implements _$RetentionPolicyCopyWith<$Res> {
  __$RetentionPolicyCopyWithImpl(this._self, this._then);

  final _RetentionPolicy _self;
  final $Res Function(_RetentionPolicy) _then;

  /// Create a copy of RetentionPolicy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field = null,
    Object? duration = null,
    Object? action = null,
    Object? condition = freezed,
  }) {
    return _then(_RetentionPolicy(
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as RetentionAction,
      condition: freezed == condition
          ? _self.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$RetentionResult {
  /// When the retention processing occurred.
  DateTime get processedAt;

  /// Number of fields that were nullified.
  int get nullifiedCount;

  /// Number of fields that were anonymized.
  int get anonymizedCount;

  /// Number of records that were deleted.
  int get deletedCount;

  /// Number of records that were archived.
  int get archivedCount;

  /// Any errors that occurred during processing.
  List<RetentionError> get errors;

  /// Create a copy of RetentionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RetentionResultCopyWith<RetentionResult> get copyWith =>
      _$RetentionResultCopyWithImpl<RetentionResult>(
          this as RetentionResult, _$identity);

  /// Serializes this RetentionResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RetentionResult &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.nullifiedCount, nullifiedCount) ||
                other.nullifiedCount == nullifiedCount) &&
            (identical(other.anonymizedCount, anonymizedCount) ||
                other.anonymizedCount == anonymizedCount) &&
            (identical(other.deletedCount, deletedCount) ||
                other.deletedCount == deletedCount) &&
            (identical(other.archivedCount, archivedCount) ||
                other.archivedCount == archivedCount) &&
            const DeepCollectionEquality().equals(other.errors, errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      processedAt,
      nullifiedCount,
      anonymizedCount,
      deletedCount,
      archivedCount,
      const DeepCollectionEquality().hash(errors));

  @override
  String toString() {
    return 'RetentionResult(processedAt: $processedAt, nullifiedCount: $nullifiedCount, anonymizedCount: $anonymizedCount, deletedCount: $deletedCount, archivedCount: $archivedCount, errors: $errors)';
  }
}

/// @nodoc
abstract mixin class $RetentionResultCopyWith<$Res> {
  factory $RetentionResultCopyWith(
          RetentionResult value, $Res Function(RetentionResult) _then) =
      _$RetentionResultCopyWithImpl;
  @useResult
  $Res call(
      {DateTime processedAt,
      int nullifiedCount,
      int anonymizedCount,
      int deletedCount,
      int archivedCount,
      List<RetentionError> errors});
}

/// @nodoc
class _$RetentionResultCopyWithImpl<$Res>
    implements $RetentionResultCopyWith<$Res> {
  _$RetentionResultCopyWithImpl(this._self, this._then);

  final RetentionResult _self;
  final $Res Function(RetentionResult) _then;

  /// Create a copy of RetentionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? processedAt = null,
    Object? nullifiedCount = null,
    Object? anonymizedCount = null,
    Object? deletedCount = null,
    Object? archivedCount = null,
    Object? errors = null,
  }) {
    return _then(_self.copyWith(
      processedAt: null == processedAt
          ? _self.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nullifiedCount: null == nullifiedCount
          ? _self.nullifiedCount
          : nullifiedCount // ignore: cast_nullable_to_non_nullable
              as int,
      anonymizedCount: null == anonymizedCount
          ? _self.anonymizedCount
          : anonymizedCount // ignore: cast_nullable_to_non_nullable
              as int,
      deletedCount: null == deletedCount
          ? _self.deletedCount
          : deletedCount // ignore: cast_nullable_to_non_nullable
              as int,
      archivedCount: null == archivedCount
          ? _self.archivedCount
          : archivedCount // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _self.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<RetentionError>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RetentionResult].
extension RetentionResultPatterns on RetentionResult {
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
    TResult Function(_RetentionResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionResult() when $default != null:
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
    TResult Function(_RetentionResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionResult():
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
    TResult? Function(_RetentionResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionResult() when $default != null:
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
            DateTime processedAt,
            int nullifiedCount,
            int anonymizedCount,
            int deletedCount,
            int archivedCount,
            List<RetentionError> errors)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionResult() when $default != null:
        return $default(
            _that.processedAt,
            _that.nullifiedCount,
            _that.anonymizedCount,
            _that.deletedCount,
            _that.archivedCount,
            _that.errors);
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
            DateTime processedAt,
            int nullifiedCount,
            int anonymizedCount,
            int deletedCount,
            int archivedCount,
            List<RetentionError> errors)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionResult():
        return $default(
            _that.processedAt,
            _that.nullifiedCount,
            _that.anonymizedCount,
            _that.deletedCount,
            _that.archivedCount,
            _that.errors);
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
            DateTime processedAt,
            int nullifiedCount,
            int anonymizedCount,
            int deletedCount,
            int archivedCount,
            List<RetentionError> errors)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionResult() when $default != null:
        return $default(
            _that.processedAt,
            _that.nullifiedCount,
            _that.anonymizedCount,
            _that.deletedCount,
            _that.archivedCount,
            _that.errors);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RetentionResult extends RetentionResult {
  const _RetentionResult(
      {required this.processedAt,
      required this.nullifiedCount,
      required this.anonymizedCount,
      required this.deletedCount,
      required this.archivedCount,
      required final List<RetentionError> errors})
      : _errors = errors,
        super._();
  factory _RetentionResult.fromJson(Map<String, dynamic> json) =>
      _$RetentionResultFromJson(json);

  /// When the retention processing occurred.
  @override
  final DateTime processedAt;

  /// Number of fields that were nullified.
  @override
  final int nullifiedCount;

  /// Number of fields that were anonymized.
  @override
  final int anonymizedCount;

  /// Number of records that were deleted.
  @override
  final int deletedCount;

  /// Number of records that were archived.
  @override
  final int archivedCount;

  /// Any errors that occurred during processing.
  final List<RetentionError> _errors;

  /// Any errors that occurred during processing.
  @override
  List<RetentionError> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  /// Create a copy of RetentionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RetentionResultCopyWith<_RetentionResult> get copyWith =>
      __$RetentionResultCopyWithImpl<_RetentionResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RetentionResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RetentionResult &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.nullifiedCount, nullifiedCount) ||
                other.nullifiedCount == nullifiedCount) &&
            (identical(other.anonymizedCount, anonymizedCount) ||
                other.anonymizedCount == anonymizedCount) &&
            (identical(other.deletedCount, deletedCount) ||
                other.deletedCount == deletedCount) &&
            (identical(other.archivedCount, archivedCount) ||
                other.archivedCount == archivedCount) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      processedAt,
      nullifiedCount,
      anonymizedCount,
      deletedCount,
      archivedCount,
      const DeepCollectionEquality().hash(_errors));

  @override
  String toString() {
    return 'RetentionResult(processedAt: $processedAt, nullifiedCount: $nullifiedCount, anonymizedCount: $anonymizedCount, deletedCount: $deletedCount, archivedCount: $archivedCount, errors: $errors)';
  }
}

/// @nodoc
abstract mixin class _$RetentionResultCopyWith<$Res>
    implements $RetentionResultCopyWith<$Res> {
  factory _$RetentionResultCopyWith(
          _RetentionResult value, $Res Function(_RetentionResult) _then) =
      __$RetentionResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime processedAt,
      int nullifiedCount,
      int anonymizedCount,
      int deletedCount,
      int archivedCount,
      List<RetentionError> errors});
}

/// @nodoc
class __$RetentionResultCopyWithImpl<$Res>
    implements _$RetentionResultCopyWith<$Res> {
  __$RetentionResultCopyWithImpl(this._self, this._then);

  final _RetentionResult _self;
  final $Res Function(_RetentionResult) _then;

  /// Create a copy of RetentionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? processedAt = null,
    Object? nullifiedCount = null,
    Object? anonymizedCount = null,
    Object? deletedCount = null,
    Object? archivedCount = null,
    Object? errors = null,
  }) {
    return _then(_RetentionResult(
      processedAt: null == processedAt
          ? _self.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nullifiedCount: null == nullifiedCount
          ? _self.nullifiedCount
          : nullifiedCount // ignore: cast_nullable_to_non_nullable
              as int,
      anonymizedCount: null == anonymizedCount
          ? _self.anonymizedCount
          : anonymizedCount // ignore: cast_nullable_to_non_nullable
              as int,
      deletedCount: null == deletedCount
          ? _self.deletedCount
          : deletedCount // ignore: cast_nullable_to_non_nullable
              as int,
      archivedCount: null == archivedCount
          ? _self.archivedCount
          : archivedCount // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _self._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<RetentionError>,
    ));
  }
}

/// @nodoc
mixin _$RetentionError {
  /// The ID of the entity that caused the error.
  String get entityId;

  /// The field being processed when the error occurred.
  String get field;

  /// Description of the error.
  String get message;

  /// Create a copy of RetentionError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RetentionErrorCopyWith<RetentionError> get copyWith =>
      _$RetentionErrorCopyWithImpl<RetentionError>(
          this as RetentionError, _$identity);

  /// Serializes this RetentionError to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RetentionError &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, entityId, field, message);

  @override
  String toString() {
    return 'RetentionError(entityId: $entityId, field: $field, message: $message)';
  }
}

/// @nodoc
abstract mixin class $RetentionErrorCopyWith<$Res> {
  factory $RetentionErrorCopyWith(
          RetentionError value, $Res Function(RetentionError) _then) =
      _$RetentionErrorCopyWithImpl;
  @useResult
  $Res call({String entityId, String field, String message});
}

/// @nodoc
class _$RetentionErrorCopyWithImpl<$Res>
    implements $RetentionErrorCopyWith<$Res> {
  _$RetentionErrorCopyWithImpl(this._self, this._then);

  final RetentionError _self;
  final $Res Function(RetentionError) _then;

  /// Create a copy of RetentionError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityId = null,
    Object? field = null,
    Object? message = null,
  }) {
    return _then(_self.copyWith(
      entityId: null == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [RetentionError].
extension RetentionErrorPatterns on RetentionError {
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
    TResult Function(_RetentionError value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionError() when $default != null:
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
    TResult Function(_RetentionError value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionError():
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
    TResult? Function(_RetentionError value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionError() when $default != null:
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
    TResult Function(String entityId, String field, String message)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetentionError() when $default != null:
        return $default(_that.entityId, _that.field, _that.message);
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
    TResult Function(String entityId, String field, String message) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionError():
        return $default(_that.entityId, _that.field, _that.message);
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
    TResult? Function(String entityId, String field, String message)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetentionError() when $default != null:
        return $default(_that.entityId, _that.field, _that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RetentionError extends RetentionError {
  const _RetentionError(
      {required this.entityId, required this.field, required this.message})
      : super._();
  factory _RetentionError.fromJson(Map<String, dynamic> json) =>
      _$RetentionErrorFromJson(json);

  /// The ID of the entity that caused the error.
  @override
  final String entityId;

  /// The field being processed when the error occurred.
  @override
  final String field;

  /// Description of the error.
  @override
  final String message;

  /// Create a copy of RetentionError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RetentionErrorCopyWith<_RetentionError> get copyWith =>
      __$RetentionErrorCopyWithImpl<_RetentionError>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RetentionErrorToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RetentionError &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, entityId, field, message);

  @override
  String toString() {
    return 'RetentionError(entityId: $entityId, field: $field, message: $message)';
  }
}

/// @nodoc
abstract mixin class _$RetentionErrorCopyWith<$Res>
    implements $RetentionErrorCopyWith<$Res> {
  factory _$RetentionErrorCopyWith(
          _RetentionError value, $Res Function(_RetentionError) _then) =
      __$RetentionErrorCopyWithImpl;
  @override
  @useResult
  $Res call({String entityId, String field, String message});
}

/// @nodoc
class __$RetentionErrorCopyWithImpl<$Res>
    implements _$RetentionErrorCopyWith<$Res> {
  __$RetentionErrorCopyWithImpl(this._self, this._then);

  final _RetentionError _self;
  final $Res Function(_RetentionError) _then;

  /// Create a copy of RetentionError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entityId = null,
    Object? field = null,
    Object? message = null,
  }) {
    return _then(_RetentionError(
      entityId: null == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
