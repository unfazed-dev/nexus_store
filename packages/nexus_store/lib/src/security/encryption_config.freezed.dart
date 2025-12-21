// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'encryption_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EncryptionConfig {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is EncryptionConfig);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EncryptionConfig()';
  }
}

/// @nodoc
class $EncryptionConfigCopyWith<$Res> {
  $EncryptionConfigCopyWith(
      EncryptionConfig _, $Res Function(EncryptionConfig) __);
}

/// Adds pattern-matching-related methods to [EncryptionConfig].
extension EncryptionConfigPatterns on EncryptionConfig {
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
    TResult Function(EncryptionNone value)? none,
    TResult Function(EncryptionSqlCipher value)? sqlCipher,
    TResult Function(EncryptionFieldLevel value)? fieldLevel,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone() when none != null:
        return none(_that);
      case EncryptionSqlCipher() when sqlCipher != null:
        return sqlCipher(_that);
      case EncryptionFieldLevel() when fieldLevel != null:
        return fieldLevel(_that);
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
    required TResult Function(EncryptionNone value) none,
    required TResult Function(EncryptionSqlCipher value) sqlCipher,
    required TResult Function(EncryptionFieldLevel value) fieldLevel,
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone():
        return none(_that);
      case EncryptionSqlCipher():
        return sqlCipher(_that);
      case EncryptionFieldLevel():
        return fieldLevel(_that);
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
    TResult? Function(EncryptionNone value)? none,
    TResult? Function(EncryptionSqlCipher value)? sqlCipher,
    TResult? Function(EncryptionFieldLevel value)? fieldLevel,
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone() when none != null:
        return none(_that);
      case EncryptionSqlCipher() when sqlCipher != null:
        return sqlCipher(_that);
      case EncryptionFieldLevel() when fieldLevel != null:
        return fieldLevel(_that);
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
    TResult Function()? none,
    TResult Function(Future<String> Function() keyProvider, int kdfIterations)?
        sqlCipher,
    TResult Function(
            Set<String> encryptedFields,
            Future<String> Function() keyProvider,
            EncryptionAlgorithm algorithm,
            String version,
            KeyDerivationConfig? keyDerivation,
            SaltStorage? saltStorage)?
        fieldLevel,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone() when none != null:
        return none();
      case EncryptionSqlCipher() when sqlCipher != null:
        return sqlCipher(_that.keyProvider, _that.kdfIterations);
      case EncryptionFieldLevel() when fieldLevel != null:
        return fieldLevel(
            _that.encryptedFields,
            _that.keyProvider,
            _that.algorithm,
            _that.version,
            _that.keyDerivation,
            _that.saltStorage);
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
    required TResult Function() none,
    required TResult Function(
            Future<String> Function() keyProvider, int kdfIterations)
        sqlCipher,
    required TResult Function(
            Set<String> encryptedFields,
            Future<String> Function() keyProvider,
            EncryptionAlgorithm algorithm,
            String version,
            KeyDerivationConfig? keyDerivation,
            SaltStorage? saltStorage)
        fieldLevel,
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone():
        return none();
      case EncryptionSqlCipher():
        return sqlCipher(_that.keyProvider, _that.kdfIterations);
      case EncryptionFieldLevel():
        return fieldLevel(
            _that.encryptedFields,
            _that.keyProvider,
            _that.algorithm,
            _that.version,
            _that.keyDerivation,
            _that.saltStorage);
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
    TResult? Function()? none,
    TResult? Function(Future<String> Function() keyProvider, int kdfIterations)?
        sqlCipher,
    TResult? Function(
            Set<String> encryptedFields,
            Future<String> Function() keyProvider,
            EncryptionAlgorithm algorithm,
            String version,
            KeyDerivationConfig? keyDerivation,
            SaltStorage? saltStorage)?
        fieldLevel,
  }) {
    final _that = this;
    switch (_that) {
      case EncryptionNone() when none != null:
        return none();
      case EncryptionSqlCipher() when sqlCipher != null:
        return sqlCipher(_that.keyProvider, _that.kdfIterations);
      case EncryptionFieldLevel() when fieldLevel != null:
        return fieldLevel(
            _that.encryptedFields,
            _that.keyProvider,
            _that.algorithm,
            _that.version,
            _that.keyDerivation,
            _that.saltStorage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class EncryptionNone extends EncryptionConfig {
  const EncryptionNone() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is EncryptionNone);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EncryptionConfig.none()';
  }
}

/// @nodoc

class EncryptionSqlCipher extends EncryptionConfig {
  const EncryptionSqlCipher(
      {required this.keyProvider, this.kdfIterations = 256000})
      : super._();

  /// Callback to retrieve the encryption key.
  final Future<String> Function() keyProvider;

  /// PBKDF2 iterations for key derivation.
  @JsonKey()
  final int kdfIterations;

  /// Create a copy of EncryptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EncryptionSqlCipherCopyWith<EncryptionSqlCipher> get copyWith =>
      _$EncryptionSqlCipherCopyWithImpl<EncryptionSqlCipher>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EncryptionSqlCipher &&
            (identical(other.keyProvider, keyProvider) ||
                other.keyProvider == keyProvider) &&
            (identical(other.kdfIterations, kdfIterations) ||
                other.kdfIterations == kdfIterations));
  }

  @override
  int get hashCode => Object.hash(runtimeType, keyProvider, kdfIterations);

  @override
  String toString() {
    return 'EncryptionConfig.sqlCipher(keyProvider: $keyProvider, kdfIterations: $kdfIterations)';
  }
}

/// @nodoc
abstract mixin class $EncryptionSqlCipherCopyWith<$Res>
    implements $EncryptionConfigCopyWith<$Res> {
  factory $EncryptionSqlCipherCopyWith(
          EncryptionSqlCipher value, $Res Function(EncryptionSqlCipher) _then) =
      _$EncryptionSqlCipherCopyWithImpl;
  @useResult
  $Res call({Future<String> Function() keyProvider, int kdfIterations});
}

/// @nodoc
class _$EncryptionSqlCipherCopyWithImpl<$Res>
    implements $EncryptionSqlCipherCopyWith<$Res> {
  _$EncryptionSqlCipherCopyWithImpl(this._self, this._then);

  final EncryptionSqlCipher _self;
  final $Res Function(EncryptionSqlCipher) _then;

  /// Create a copy of EncryptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? keyProvider = null,
    Object? kdfIterations = null,
  }) {
    return _then(EncryptionSqlCipher(
      keyProvider: null == keyProvider
          ? _self.keyProvider
          : keyProvider // ignore: cast_nullable_to_non_nullable
              as Future<String> Function(),
      kdfIterations: null == kdfIterations
          ? _self.kdfIterations
          : kdfIterations // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class EncryptionFieldLevel extends EncryptionConfig {
  const EncryptionFieldLevel(
      {required final Set<String> encryptedFields,
      required this.keyProvider,
      this.algorithm = EncryptionAlgorithm.aes256Gcm,
      this.version = 'v1',
      this.keyDerivation,
      this.saltStorage})
      : _encryptedFields = encryptedFields,
        super._();

  /// Set of field names to encrypt.
  final Set<String> _encryptedFields;

  /// Set of field names to encrypt.
  Set<String> get encryptedFields {
    if (_encryptedFields is EqualUnmodifiableSetView) return _encryptedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_encryptedFields);
  }

  /// Callback to retrieve the encryption key (or password if using key derivation).
  final Future<String> Function() keyProvider;

  /// Encryption algorithm (default: AES-256-GCM).
  @JsonKey()
  final EncryptionAlgorithm algorithm;

  /// Version prefix for encrypted values (for key rotation).
  @JsonKey()
  final String version;

  /// Optional key derivation configuration.
  /// When set, the keyProvider returns a password which is derived
  /// into an encryption key using the specified algorithm (e.g., PBKDF2).
  final KeyDerivationConfig? keyDerivation;

  /// Optional salt storage for persisting salts.
  /// Required when using key derivation to ensure consistent key derivation.
  final SaltStorage? saltStorage;

  /// Create a copy of EncryptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EncryptionFieldLevelCopyWith<EncryptionFieldLevel> get copyWith =>
      _$EncryptionFieldLevelCopyWithImpl<EncryptionFieldLevel>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EncryptionFieldLevel &&
            const DeepCollectionEquality()
                .equals(other._encryptedFields, _encryptedFields) &&
            (identical(other.keyProvider, keyProvider) ||
                other.keyProvider == keyProvider) &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.keyDerivation, keyDerivation) ||
                other.keyDerivation == keyDerivation) &&
            (identical(other.saltStorage, saltStorage) ||
                other.saltStorage == saltStorage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_encryptedFields),
      keyProvider,
      algorithm,
      version,
      keyDerivation,
      saltStorage);

  @override
  String toString() {
    return 'EncryptionConfig.fieldLevel(encryptedFields: $encryptedFields, keyProvider: $keyProvider, algorithm: $algorithm, version: $version, keyDerivation: $keyDerivation, saltStorage: $saltStorage)';
  }
}

/// @nodoc
abstract mixin class $EncryptionFieldLevelCopyWith<$Res>
    implements $EncryptionConfigCopyWith<$Res> {
  factory $EncryptionFieldLevelCopyWith(EncryptionFieldLevel value,
          $Res Function(EncryptionFieldLevel) _then) =
      _$EncryptionFieldLevelCopyWithImpl;
  @useResult
  $Res call(
      {Set<String> encryptedFields,
      Future<String> Function() keyProvider,
      EncryptionAlgorithm algorithm,
      String version,
      KeyDerivationConfig? keyDerivation,
      SaltStorage? saltStorage});

  $KeyDerivationConfigCopyWith<$Res>? get keyDerivation;
}

/// @nodoc
class _$EncryptionFieldLevelCopyWithImpl<$Res>
    implements $EncryptionFieldLevelCopyWith<$Res> {
  _$EncryptionFieldLevelCopyWithImpl(this._self, this._then);

  final EncryptionFieldLevel _self;
  final $Res Function(EncryptionFieldLevel) _then;

  /// Create a copy of EncryptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? encryptedFields = null,
    Object? keyProvider = null,
    Object? algorithm = null,
    Object? version = null,
    Object? keyDerivation = freezed,
    Object? saltStorage = freezed,
  }) {
    return _then(EncryptionFieldLevel(
      encryptedFields: null == encryptedFields
          ? _self._encryptedFields
          : encryptedFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      keyProvider: null == keyProvider
          ? _self.keyProvider
          : keyProvider // ignore: cast_nullable_to_non_nullable
              as Future<String> Function(),
      algorithm: null == algorithm
          ? _self.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as EncryptionAlgorithm,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      keyDerivation: freezed == keyDerivation
          ? _self.keyDerivation
          : keyDerivation // ignore: cast_nullable_to_non_nullable
              as KeyDerivationConfig?,
      saltStorage: freezed == saltStorage
          ? _self.saltStorage
          : saltStorage // ignore: cast_nullable_to_non_nullable
              as SaltStorage?,
    ));
  }

  /// Create a copy of EncryptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $KeyDerivationConfigCopyWith<$Res>? get keyDerivation {
    if (_self.keyDerivation == null) {
      return null;
    }

    return $KeyDerivationConfigCopyWith<$Res>(_self.keyDerivation!, (value) {
      return _then(_self.copyWith(keyDerivation: value));
    });
  }
}

// dart format on
