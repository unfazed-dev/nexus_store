// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_derivation_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KeyDerivationConfig {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is KeyDerivationConfig);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'KeyDerivationConfig()';
  }
}

/// @nodoc
class $KeyDerivationConfigCopyWith<$Res> {
  $KeyDerivationConfigCopyWith(
      KeyDerivationConfig _, $Res Function(KeyDerivationConfig) __);
}

/// Adds pattern-matching-related methods to [KeyDerivationConfig].
extension KeyDerivationConfigPatterns on KeyDerivationConfig {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(KeyDerivationPbkdf2 value)? pbkdf2,
    TResult Function(KeyDerivationRaw value)? raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2() when pbkdf2 != null:
        return pbkdf2(_that);
      case KeyDerivationRaw() when raw != null:
        return raw(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(KeyDerivationPbkdf2 value) pbkdf2,
    required TResult Function(KeyDerivationRaw value) raw,
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2():
        return pbkdf2(_that);
      case KeyDerivationRaw():
        return raw(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(KeyDerivationPbkdf2 value)? pbkdf2,
    TResult? Function(KeyDerivationRaw value)? raw,
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2() when pbkdf2 != null:
        return pbkdf2(_that);
      case KeyDerivationRaw() when raw != null:
        return raw(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int iterations, KdfHashAlgorithm hashAlgorithm,
            int keyLength, int saltLength)?
        pbkdf2,
    TResult Function()? raw,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2() when pbkdf2 != null:
        return pbkdf2(_that.iterations, _that.hashAlgorithm, _that.keyLength,
            _that.saltLength);
      case KeyDerivationRaw() when raw != null:
        return raw();
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
  TResult when<TResult extends Object?>({
    required TResult Function(int iterations, KdfHashAlgorithm hashAlgorithm,
            int keyLength, int saltLength)
        pbkdf2,
    required TResult Function() raw,
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2():
        return pbkdf2(_that.iterations, _that.hashAlgorithm, _that.keyLength,
            _that.saltLength);
      case KeyDerivationRaw():
        return raw();
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int iterations, KdfHashAlgorithm hashAlgorithm,
            int keyLength, int saltLength)?
        pbkdf2,
    TResult? Function()? raw,
  }) {
    final _that = this;
    switch (_that) {
      case KeyDerivationPbkdf2() when pbkdf2 != null:
        return pbkdf2(_that.iterations, _that.hashAlgorithm, _that.keyLength,
            _that.saltLength);
      case KeyDerivationRaw() when raw != null:
        return raw();
      case _:
        return null;
    }
  }
}

/// @nodoc

class KeyDerivationPbkdf2 extends KeyDerivationConfig {
  const KeyDerivationPbkdf2(
      {this.iterations = 310000,
      this.hashAlgorithm = KdfHashAlgorithm.sha256,
      this.keyLength = 32,
      this.saltLength = 16})
      : super._();

  /// Number of PBKDF2 iterations.
  /// OWASP 2023 recommends 310,000 for HMAC-SHA256.
  @JsonKey()
  final int iterations;

  /// Hash algorithm for HMAC (SHA-256 or SHA-512).
  @JsonKey()
  final KdfHashAlgorithm hashAlgorithm;

  /// Output key length in bytes. Default: 32 (256 bits for AES-256).
  @JsonKey()
  final int keyLength;

  /// Salt length in bytes. Minimum recommended: 16 (128 bits).
  @JsonKey()
  final int saltLength;

  /// Create a copy of KeyDerivationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $KeyDerivationPbkdf2CopyWith<KeyDerivationPbkdf2> get copyWith =>
      _$KeyDerivationPbkdf2CopyWithImpl<KeyDerivationPbkdf2>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is KeyDerivationPbkdf2 &&
            (identical(other.iterations, iterations) ||
                other.iterations == iterations) &&
            (identical(other.hashAlgorithm, hashAlgorithm) ||
                other.hashAlgorithm == hashAlgorithm) &&
            (identical(other.keyLength, keyLength) ||
                other.keyLength == keyLength) &&
            (identical(other.saltLength, saltLength) ||
                other.saltLength == saltLength));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, iterations, hashAlgorithm, keyLength, saltLength);

  @override
  String toString() {
    return 'KeyDerivationConfig.pbkdf2(iterations: $iterations, hashAlgorithm: $hashAlgorithm, keyLength: $keyLength, saltLength: $saltLength)';
  }
}

/// @nodoc
abstract mixin class $KeyDerivationPbkdf2CopyWith<$Res>
    implements $KeyDerivationConfigCopyWith<$Res> {
  factory $KeyDerivationPbkdf2CopyWith(
          KeyDerivationPbkdf2 value, $Res Function(KeyDerivationPbkdf2) _then) =
      _$KeyDerivationPbkdf2CopyWithImpl;
  @useResult
  $Res call(
      {int iterations,
      KdfHashAlgorithm hashAlgorithm,
      int keyLength,
      int saltLength});
}

/// @nodoc
class _$KeyDerivationPbkdf2CopyWithImpl<$Res>
    implements $KeyDerivationPbkdf2CopyWith<$Res> {
  _$KeyDerivationPbkdf2CopyWithImpl(this._self, this._then);

  final KeyDerivationPbkdf2 _self;
  final $Res Function(KeyDerivationPbkdf2) _then;

  /// Create a copy of KeyDerivationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? iterations = null,
    Object? hashAlgorithm = null,
    Object? keyLength = null,
    Object? saltLength = null,
  }) {
    return _then(KeyDerivationPbkdf2(
      iterations: null == iterations
          ? _self.iterations
          : iterations // ignore: cast_nullable_to_non_nullable
              as int,
      hashAlgorithm: null == hashAlgorithm
          ? _self.hashAlgorithm
          : hashAlgorithm // ignore: cast_nullable_to_non_nullable
              as KdfHashAlgorithm,
      keyLength: null == keyLength
          ? _self.keyLength
          : keyLength // ignore: cast_nullable_to_non_nullable
              as int,
      saltLength: null == saltLength
          ? _self.saltLength
          : saltLength // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class KeyDerivationRaw extends KeyDerivationConfig {
  const KeyDerivationRaw() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is KeyDerivationRaw);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'KeyDerivationConfig.raw()';
  }
}

// dart format on
