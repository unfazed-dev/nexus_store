// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lazy_load_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LazyLoadConfig {
  /// Fields to load lazily.
  ///
  /// These fields will not be loaded with the entity by default and must
  /// be explicitly loaded via [NexusStore.loadField] or similar methods.
  Set<String> get lazyFields;

  /// Maximum number of field load requests to batch together.
  ///
  /// When multiple field load requests are made within [batchDelay],
  /// they are combined into a single backend call up to this limit.
  int get batchSize;

  /// Duration to wait before executing a batch of field loads.
  ///
  /// Requests made within this window are batched together.
  Duration get batchDelay;

  /// Whether to preload lazy fields when watching an entity.
  ///
  /// When true, lazy fields are automatically loaded when an entity
  /// is watched via [NexusStore.watch] or [NexusStore.watchAll].
  bool get preloadOnWatch;

  /// Default placeholder values per field.
  ///
  /// When a lazy field is not loaded, [getPlaceholder] returns the
  /// value configured here, or null if not specified.
  Map<String, dynamic> get placeholders;

  /// Create a copy of LazyLoadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LazyLoadConfigCopyWith<LazyLoadConfig> get copyWith =>
      _$LazyLoadConfigCopyWithImpl<LazyLoadConfig>(
          this as LazyLoadConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LazyLoadConfig &&
            const DeepCollectionEquality()
                .equals(other.lazyFields, lazyFields) &&
            (identical(other.batchSize, batchSize) ||
                other.batchSize == batchSize) &&
            (identical(other.batchDelay, batchDelay) ||
                other.batchDelay == batchDelay) &&
            (identical(other.preloadOnWatch, preloadOnWatch) ||
                other.preloadOnWatch == preloadOnWatch) &&
            const DeepCollectionEquality()
                .equals(other.placeholders, placeholders));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(lazyFields),
      batchSize,
      batchDelay,
      preloadOnWatch,
      const DeepCollectionEquality().hash(placeholders));

  @override
  String toString() {
    return 'LazyLoadConfig(lazyFields: $lazyFields, batchSize: $batchSize, batchDelay: $batchDelay, preloadOnWatch: $preloadOnWatch, placeholders: $placeholders)';
  }
}

/// @nodoc
abstract mixin class $LazyLoadConfigCopyWith<$Res> {
  factory $LazyLoadConfigCopyWith(
          LazyLoadConfig value, $Res Function(LazyLoadConfig) _then) =
      _$LazyLoadConfigCopyWithImpl;
  @useResult
  $Res call(
      {Set<String> lazyFields,
      int batchSize,
      Duration batchDelay,
      bool preloadOnWatch,
      Map<String, dynamic> placeholders});
}

/// @nodoc
class _$LazyLoadConfigCopyWithImpl<$Res>
    implements $LazyLoadConfigCopyWith<$Res> {
  _$LazyLoadConfigCopyWithImpl(this._self, this._then);

  final LazyLoadConfig _self;
  final $Res Function(LazyLoadConfig) _then;

  /// Create a copy of LazyLoadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lazyFields = null,
    Object? batchSize = null,
    Object? batchDelay = null,
    Object? preloadOnWatch = null,
    Object? placeholders = null,
  }) {
    return _then(_self.copyWith(
      lazyFields: null == lazyFields
          ? _self.lazyFields
          : lazyFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      batchSize: null == batchSize
          ? _self.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      batchDelay: null == batchDelay
          ? _self.batchDelay
          : batchDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      preloadOnWatch: null == preloadOnWatch
          ? _self.preloadOnWatch
          : preloadOnWatch // ignore: cast_nullable_to_non_nullable
              as bool,
      placeholders: null == placeholders
          ? _self.placeholders
          : placeholders // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [LazyLoadConfig].
extension LazyLoadConfigPatterns on LazyLoadConfig {
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
    TResult Function(_LazyLoadConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig() when $default != null:
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
    TResult Function(_LazyLoadConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig():
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
    TResult? Function(_LazyLoadConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig() when $default != null:
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
    TResult Function(Set<String> lazyFields, int batchSize, Duration batchDelay,
            bool preloadOnWatch, Map<String, dynamic> placeholders)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig() when $default != null:
        return $default(_that.lazyFields, _that.batchSize, _that.batchDelay,
            _that.preloadOnWatch, _that.placeholders);
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
    TResult Function(Set<String> lazyFields, int batchSize, Duration batchDelay,
            bool preloadOnWatch, Map<String, dynamic> placeholders)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig():
        return $default(_that.lazyFields, _that.batchSize, _that.batchDelay,
            _that.preloadOnWatch, _that.placeholders);
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
            Set<String> lazyFields,
            int batchSize,
            Duration batchDelay,
            bool preloadOnWatch,
            Map<String, dynamic> placeholders)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LazyLoadConfig() when $default != null:
        return $default(_that.lazyFields, _that.batchSize, _that.batchDelay,
            _that.preloadOnWatch, _that.placeholders);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LazyLoadConfig extends LazyLoadConfig {
  const _LazyLoadConfig(
      {final Set<String> lazyFields = const {},
      this.batchSize = 10,
      this.batchDelay = const Duration(milliseconds: 50),
      this.preloadOnWatch = false,
      final Map<String, dynamic> placeholders = const {}})
      : _lazyFields = lazyFields,
        _placeholders = placeholders,
        super._();

  /// Fields to load lazily.
  ///
  /// These fields will not be loaded with the entity by default and must
  /// be explicitly loaded via [NexusStore.loadField] or similar methods.
  final Set<String> _lazyFields;

  /// Fields to load lazily.
  ///
  /// These fields will not be loaded with the entity by default and must
  /// be explicitly loaded via [NexusStore.loadField] or similar methods.
  @override
  @JsonKey()
  Set<String> get lazyFields {
    if (_lazyFields is EqualUnmodifiableSetView) return _lazyFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_lazyFields);
  }

  /// Maximum number of field load requests to batch together.
  ///
  /// When multiple field load requests are made within [batchDelay],
  /// they are combined into a single backend call up to this limit.
  @override
  @JsonKey()
  final int batchSize;

  /// Duration to wait before executing a batch of field loads.
  ///
  /// Requests made within this window are batched together.
  @override
  @JsonKey()
  final Duration batchDelay;

  /// Whether to preload lazy fields when watching an entity.
  ///
  /// When true, lazy fields are automatically loaded when an entity
  /// is watched via [NexusStore.watch] or [NexusStore.watchAll].
  @override
  @JsonKey()
  final bool preloadOnWatch;

  /// Default placeholder values per field.
  ///
  /// When a lazy field is not loaded, [getPlaceholder] returns the
  /// value configured here, or null if not specified.
  final Map<String, dynamic> _placeholders;

  /// Default placeholder values per field.
  ///
  /// When a lazy field is not loaded, [getPlaceholder] returns the
  /// value configured here, or null if not specified.
  @override
  @JsonKey()
  Map<String, dynamic> get placeholders {
    if (_placeholders is EqualUnmodifiableMapView) return _placeholders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_placeholders);
  }

  /// Create a copy of LazyLoadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LazyLoadConfigCopyWith<_LazyLoadConfig> get copyWith =>
      __$LazyLoadConfigCopyWithImpl<_LazyLoadConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LazyLoadConfig &&
            const DeepCollectionEquality()
                .equals(other._lazyFields, _lazyFields) &&
            (identical(other.batchSize, batchSize) ||
                other.batchSize == batchSize) &&
            (identical(other.batchDelay, batchDelay) ||
                other.batchDelay == batchDelay) &&
            (identical(other.preloadOnWatch, preloadOnWatch) ||
                other.preloadOnWatch == preloadOnWatch) &&
            const DeepCollectionEquality()
                .equals(other._placeholders, _placeholders));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_lazyFields),
      batchSize,
      batchDelay,
      preloadOnWatch,
      const DeepCollectionEquality().hash(_placeholders));

  @override
  String toString() {
    return 'LazyLoadConfig(lazyFields: $lazyFields, batchSize: $batchSize, batchDelay: $batchDelay, preloadOnWatch: $preloadOnWatch, placeholders: $placeholders)';
  }
}

/// @nodoc
abstract mixin class _$LazyLoadConfigCopyWith<$Res>
    implements $LazyLoadConfigCopyWith<$Res> {
  factory _$LazyLoadConfigCopyWith(
          _LazyLoadConfig value, $Res Function(_LazyLoadConfig) _then) =
      __$LazyLoadConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Set<String> lazyFields,
      int batchSize,
      Duration batchDelay,
      bool preloadOnWatch,
      Map<String, dynamic> placeholders});
}

/// @nodoc
class __$LazyLoadConfigCopyWithImpl<$Res>
    implements _$LazyLoadConfigCopyWith<$Res> {
  __$LazyLoadConfigCopyWithImpl(this._self, this._then);

  final _LazyLoadConfig _self;
  final $Res Function(_LazyLoadConfig) _then;

  /// Create a copy of LazyLoadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? lazyFields = null,
    Object? batchSize = null,
    Object? batchDelay = null,
    Object? preloadOnWatch = null,
    Object? placeholders = null,
  }) {
    return _then(_LazyLoadConfig(
      lazyFields: null == lazyFields
          ? _self._lazyFields
          : lazyFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      batchSize: null == batchSize
          ? _self.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      batchDelay: null == batchDelay
          ? _self.batchDelay
          : batchDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      preloadOnWatch: null == preloadOnWatch
          ? _self.preloadOnWatch
          : preloadOnWatch // ignore: cast_nullable_to_non_nullable
              as bool,
      placeholders: null == placeholders
          ? _self._placeholders
          : placeholders // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

// dart format on
