// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delta_sync_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeltaSyncConfig {
  /// Whether delta sync is enabled.
  ///
  /// When enabled, only changed fields are synced instead of entire entities.
  bool get enabled;

  /// Fields to exclude from delta tracking.
  ///
  /// These fields will always be synced in full, not as deltas.
  /// Useful for fields like `updatedAt` that change frequently.
  Set<String> get excludeFields;

  /// Strategy for merging conflicting changes.
  DeltaMergeStrategy get mergeStrategy;

  /// Custom callback for resolving merge conflicts.
  ///
  /// Only used when [mergeStrategy] is [DeltaMergeStrategy.custom].
  MergeConflictCallback? get onMergeConflict;

  /// Create a copy of DeltaSyncConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeltaSyncConfigCopyWith<DeltaSyncConfig> get copyWith =>
      _$DeltaSyncConfigCopyWithImpl<DeltaSyncConfig>(
          this as DeltaSyncConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeltaSyncConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality()
                .equals(other.excludeFields, excludeFields) &&
            (identical(other.mergeStrategy, mergeStrategy) ||
                other.mergeStrategy == mergeStrategy) &&
            (identical(other.onMergeConflict, onMergeConflict) ||
                other.onMergeConflict == onMergeConflict));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      enabled,
      const DeepCollectionEquality().hash(excludeFields),
      mergeStrategy,
      onMergeConflict);

  @override
  String toString() {
    return 'DeltaSyncConfig(enabled: $enabled, excludeFields: $excludeFields, mergeStrategy: $mergeStrategy, onMergeConflict: $onMergeConflict)';
  }
}

/// @nodoc
abstract mixin class $DeltaSyncConfigCopyWith<$Res> {
  factory $DeltaSyncConfigCopyWith(
          DeltaSyncConfig value, $Res Function(DeltaSyncConfig) _then) =
      _$DeltaSyncConfigCopyWithImpl;
  @useResult
  $Res call(
      {bool enabled,
      Set<String> excludeFields,
      DeltaMergeStrategy mergeStrategy,
      MergeConflictCallback? onMergeConflict});
}

/// @nodoc
class _$DeltaSyncConfigCopyWithImpl<$Res>
    implements $DeltaSyncConfigCopyWith<$Res> {
  _$DeltaSyncConfigCopyWithImpl(this._self, this._then);

  final DeltaSyncConfig _self;
  final $Res Function(DeltaSyncConfig) _then;

  /// Create a copy of DeltaSyncConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? excludeFields = null,
    Object? mergeStrategy = null,
    Object? onMergeConflict = freezed,
  }) {
    return _then(_self.copyWith(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      excludeFields: null == excludeFields
          ? _self.excludeFields
          : excludeFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      mergeStrategy: null == mergeStrategy
          ? _self.mergeStrategy
          : mergeStrategy // ignore: cast_nullable_to_non_nullable
              as DeltaMergeStrategy,
      onMergeConflict: freezed == onMergeConflict
          ? _self.onMergeConflict
          : onMergeConflict // ignore: cast_nullable_to_non_nullable
              as MergeConflictCallback?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DeltaSyncConfig].
extension DeltaSyncConfigPatterns on DeltaSyncConfig {
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
    TResult Function(_DeltaSyncConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig() when $default != null:
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
    TResult Function(_DeltaSyncConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig():
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
    TResult? Function(_DeltaSyncConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig() when $default != null:
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
            Set<String> excludeFields,
            DeltaMergeStrategy mergeStrategy,
            MergeConflictCallback? onMergeConflict)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig() when $default != null:
        return $default(_that.enabled, _that.excludeFields, _that.mergeStrategy,
            _that.onMergeConflict);
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
            Set<String> excludeFields,
            DeltaMergeStrategy mergeStrategy,
            MergeConflictCallback? onMergeConflict)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig():
        return $default(_that.enabled, _that.excludeFields, _that.mergeStrategy,
            _that.onMergeConflict);
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
            Set<String> excludeFields,
            DeltaMergeStrategy mergeStrategy,
            MergeConflictCallback? onMergeConflict)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeltaSyncConfig() when $default != null:
        return $default(_that.enabled, _that.excludeFields, _that.mergeStrategy,
            _that.onMergeConflict);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DeltaSyncConfig extends DeltaSyncConfig {
  const _DeltaSyncConfig(
      {this.enabled = false,
      final Set<String> excludeFields = const {},
      this.mergeStrategy = DeltaMergeStrategy.lastWriteWins,
      this.onMergeConflict})
      : _excludeFields = excludeFields,
        super._();

  /// Whether delta sync is enabled.
  ///
  /// When enabled, only changed fields are synced instead of entire entities.
  @override
  @JsonKey()
  final bool enabled;

  /// Fields to exclude from delta tracking.
  ///
  /// These fields will always be synced in full, not as deltas.
  /// Useful for fields like `updatedAt` that change frequently.
  final Set<String> _excludeFields;

  /// Fields to exclude from delta tracking.
  ///
  /// These fields will always be synced in full, not as deltas.
  /// Useful for fields like `updatedAt` that change frequently.
  @override
  @JsonKey()
  Set<String> get excludeFields {
    if (_excludeFields is EqualUnmodifiableSetView) return _excludeFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_excludeFields);
  }

  /// Strategy for merging conflicting changes.
  @override
  @JsonKey()
  final DeltaMergeStrategy mergeStrategy;

  /// Custom callback for resolving merge conflicts.
  ///
  /// Only used when [mergeStrategy] is [DeltaMergeStrategy.custom].
  @override
  final MergeConflictCallback? onMergeConflict;

  /// Create a copy of DeltaSyncConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DeltaSyncConfigCopyWith<_DeltaSyncConfig> get copyWith =>
      __$DeltaSyncConfigCopyWithImpl<_DeltaSyncConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeltaSyncConfig &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality()
                .equals(other._excludeFields, _excludeFields) &&
            (identical(other.mergeStrategy, mergeStrategy) ||
                other.mergeStrategy == mergeStrategy) &&
            (identical(other.onMergeConflict, onMergeConflict) ||
                other.onMergeConflict == onMergeConflict));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      enabled,
      const DeepCollectionEquality().hash(_excludeFields),
      mergeStrategy,
      onMergeConflict);

  @override
  String toString() {
    return 'DeltaSyncConfig(enabled: $enabled, excludeFields: $excludeFields, mergeStrategy: $mergeStrategy, onMergeConflict: $onMergeConflict)';
  }
}

/// @nodoc
abstract mixin class _$DeltaSyncConfigCopyWith<$Res>
    implements $DeltaSyncConfigCopyWith<$Res> {
  factory _$DeltaSyncConfigCopyWith(
          _DeltaSyncConfig value, $Res Function(_DeltaSyncConfig) _then) =
      __$DeltaSyncConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enabled,
      Set<String> excludeFields,
      DeltaMergeStrategy mergeStrategy,
      MergeConflictCallback? onMergeConflict});
}

/// @nodoc
class __$DeltaSyncConfigCopyWithImpl<$Res>
    implements _$DeltaSyncConfigCopyWith<$Res> {
  __$DeltaSyncConfigCopyWithImpl(this._self, this._then);

  final _DeltaSyncConfig _self;
  final $Res Function(_DeltaSyncConfig) _then;

  /// Create a copy of DeltaSyncConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? excludeFields = null,
    Object? mergeStrategy = null,
    Object? onMergeConflict = freezed,
  }) {
    return _then(_DeltaSyncConfig(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      excludeFields: null == excludeFields
          ? _self._excludeFields
          : excludeFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      mergeStrategy: null == mergeStrategy
          ? _self.mergeStrategy
          : mergeStrategy // ignore: cast_nullable_to_non_nullable
              as DeltaMergeStrategy,
      onMergeConflict: freezed == onMergeConflict
          ? _self.onMergeConflict
          : onMergeConflict // ignore: cast_nullable_to_non_nullable
              as MergeConflictCallback?,
    ));
  }
}

// dart format on
