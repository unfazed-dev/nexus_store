// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breach_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BreachEvent {
  /// When this event occurred.
  DateTime get timestamp;

  /// The action taken (e.g., 'detected', 'contained', 'notified').
  String get action;

  /// Who performed this action.
  String get actor;

  /// Additional notes about this event.
  String? get notes;

  /// Create a copy of BreachEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BreachEventCopyWith<BreachEvent> get copyWith =>
      _$BreachEventCopyWithImpl<BreachEvent>(this as BreachEvent, _$identity);

  /// Serializes this BreachEvent to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BreachEvent &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.actor, actor) || other.actor == actor) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp, action, actor, notes);

  @override
  String toString() {
    return 'BreachEvent(timestamp: $timestamp, action: $action, actor: $actor, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $BreachEventCopyWith<$Res> {
  factory $BreachEventCopyWith(
          BreachEvent value, $Res Function(BreachEvent) _then) =
      _$BreachEventCopyWithImpl;
  @useResult
  $Res call({DateTime timestamp, String action, String actor, String? notes});
}

/// @nodoc
class _$BreachEventCopyWithImpl<$Res> implements $BreachEventCopyWith<$Res> {
  _$BreachEventCopyWithImpl(this._self, this._then);

  final BreachEvent _self;
  final $Res Function(BreachEvent) _then;

  /// Create a copy of BreachEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? action = null,
    Object? actor = null,
    Object? notes = freezed,
  }) {
    return _then(_self.copyWith(
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _self.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [BreachEvent].
extension BreachEventPatterns on BreachEvent {
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
    TResult Function(_BreachEvent value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BreachEvent() when $default != null:
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
    TResult Function(_BreachEvent value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachEvent():
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
    TResult? Function(_BreachEvent value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachEvent() when $default != null:
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
            DateTime timestamp, String action, String actor, String? notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BreachEvent() when $default != null:
        return $default(
            _that.timestamp, _that.action, _that.actor, _that.notes);
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
            DateTime timestamp, String action, String actor, String? notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachEvent():
        return $default(
            _that.timestamp, _that.action, _that.actor, _that.notes);
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
            DateTime timestamp, String action, String actor, String? notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachEvent() when $default != null:
        return $default(
            _that.timestamp, _that.action, _that.actor, _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BreachEvent extends BreachEvent {
  const _BreachEvent(
      {required this.timestamp,
      required this.action,
      required this.actor,
      this.notes})
      : super._();
  factory _BreachEvent.fromJson(Map<String, dynamic> json) =>
      _$BreachEventFromJson(json);

  /// When this event occurred.
  @override
  final DateTime timestamp;

  /// The action taken (e.g., 'detected', 'contained', 'notified').
  @override
  final String action;

  /// Who performed this action.
  @override
  final String actor;

  /// Additional notes about this event.
  @override
  final String? notes;

  /// Create a copy of BreachEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BreachEventCopyWith<_BreachEvent> get copyWith =>
      __$BreachEventCopyWithImpl<_BreachEvent>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BreachEventToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BreachEvent &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.actor, actor) || other.actor == actor) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp, action, actor, notes);

  @override
  String toString() {
    return 'BreachEvent(timestamp: $timestamp, action: $action, actor: $actor, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$BreachEventCopyWith<$Res>
    implements $BreachEventCopyWith<$Res> {
  factory _$BreachEventCopyWith(
          _BreachEvent value, $Res Function(_BreachEvent) _then) =
      __$BreachEventCopyWithImpl;
  @override
  @useResult
  $Res call({DateTime timestamp, String action, String actor, String? notes});
}

/// @nodoc
class __$BreachEventCopyWithImpl<$Res> implements _$BreachEventCopyWith<$Res> {
  __$BreachEventCopyWithImpl(this._self, this._then);

  final _BreachEvent _self;
  final $Res Function(_BreachEvent) _then;

  /// Create a copy of BreachEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = null,
    Object? action = null,
    Object? actor = null,
    Object? notes = freezed,
  }) {
    return _then(_BreachEvent(
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _self.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$AffectedUserInfo {
  /// The user's identifier.
  String get userId;

  /// The fields/data categories that were affected.
  Set<String> get affectedFields;

  /// When the user's data was accessed (if known).
  DateTime? get accessedAt;

  /// Whether the user has been notified of the breach.
  bool get notified;

  /// Create a copy of AffectedUserInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AffectedUserInfoCopyWith<AffectedUserInfo> get copyWith =>
      _$AffectedUserInfoCopyWithImpl<AffectedUserInfo>(
          this as AffectedUserInfo, _$identity);

  /// Serializes this AffectedUserInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AffectedUserInfo &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality()
                .equals(other.affectedFields, affectedFields) &&
            (identical(other.accessedAt, accessedAt) ||
                other.accessedAt == accessedAt) &&
            (identical(other.notified, notified) ||
                other.notified == notified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      const DeepCollectionEquality().hash(affectedFields),
      accessedAt,
      notified);

  @override
  String toString() {
    return 'AffectedUserInfo(userId: $userId, affectedFields: $affectedFields, accessedAt: $accessedAt, notified: $notified)';
  }
}

/// @nodoc
abstract mixin class $AffectedUserInfoCopyWith<$Res> {
  factory $AffectedUserInfoCopyWith(
          AffectedUserInfo value, $Res Function(AffectedUserInfo) _then) =
      _$AffectedUserInfoCopyWithImpl;
  @useResult
  $Res call(
      {String userId,
      Set<String> affectedFields,
      DateTime? accessedAt,
      bool notified});
}

/// @nodoc
class _$AffectedUserInfoCopyWithImpl<$Res>
    implements $AffectedUserInfoCopyWith<$Res> {
  _$AffectedUserInfoCopyWithImpl(this._self, this._then);

  final AffectedUserInfo _self;
  final $Res Function(AffectedUserInfo) _then;

  /// Create a copy of AffectedUserInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? affectedFields = null,
    Object? accessedAt = freezed,
    Object? notified = null,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      affectedFields: null == affectedFields
          ? _self.affectedFields
          : affectedFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      accessedAt: freezed == accessedAt
          ? _self.accessedAt
          : accessedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notified: null == notified
          ? _self.notified
          : notified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [AffectedUserInfo].
extension AffectedUserInfoPatterns on AffectedUserInfo {
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
    TResult Function(_AffectedUserInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo() when $default != null:
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
    TResult Function(_AffectedUserInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo():
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
    TResult? Function(_AffectedUserInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo() when $default != null:
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
    TResult Function(String userId, Set<String> affectedFields,
            DateTime? accessedAt, bool notified)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo() when $default != null:
        return $default(_that.userId, _that.affectedFields, _that.accessedAt,
            _that.notified);
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
    TResult Function(String userId, Set<String> affectedFields,
            DateTime? accessedAt, bool notified)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo():
        return $default(_that.userId, _that.affectedFields, _that.accessedAt,
            _that.notified);
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
    TResult? Function(String userId, Set<String> affectedFields,
            DateTime? accessedAt, bool notified)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AffectedUserInfo() when $default != null:
        return $default(_that.userId, _that.affectedFields, _that.accessedAt,
            _that.notified);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AffectedUserInfo extends AffectedUserInfo {
  const _AffectedUserInfo(
      {required this.userId,
      required final Set<String> affectedFields,
      this.accessedAt,
      this.notified = false})
      : _affectedFields = affectedFields,
        super._();
  factory _AffectedUserInfo.fromJson(Map<String, dynamic> json) =>
      _$AffectedUserInfoFromJson(json);

  /// The user's identifier.
  @override
  final String userId;

  /// The fields/data categories that were affected.
  final Set<String> _affectedFields;

  /// The fields/data categories that were affected.
  @override
  Set<String> get affectedFields {
    if (_affectedFields is EqualUnmodifiableSetView) return _affectedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_affectedFields);
  }

  /// When the user's data was accessed (if known).
  @override
  final DateTime? accessedAt;

  /// Whether the user has been notified of the breach.
  @override
  @JsonKey()
  final bool notified;

  /// Create a copy of AffectedUserInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AffectedUserInfoCopyWith<_AffectedUserInfo> get copyWith =>
      __$AffectedUserInfoCopyWithImpl<_AffectedUserInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AffectedUserInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AffectedUserInfo &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality()
                .equals(other._affectedFields, _affectedFields) &&
            (identical(other.accessedAt, accessedAt) ||
                other.accessedAt == accessedAt) &&
            (identical(other.notified, notified) ||
                other.notified == notified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      const DeepCollectionEquality().hash(_affectedFields),
      accessedAt,
      notified);

  @override
  String toString() {
    return 'AffectedUserInfo(userId: $userId, affectedFields: $affectedFields, accessedAt: $accessedAt, notified: $notified)';
  }
}

/// @nodoc
abstract mixin class _$AffectedUserInfoCopyWith<$Res>
    implements $AffectedUserInfoCopyWith<$Res> {
  factory _$AffectedUserInfoCopyWith(
          _AffectedUserInfo value, $Res Function(_AffectedUserInfo) _then) =
      __$AffectedUserInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String userId,
      Set<String> affectedFields,
      DateTime? accessedAt,
      bool notified});
}

/// @nodoc
class __$AffectedUserInfoCopyWithImpl<$Res>
    implements _$AffectedUserInfoCopyWith<$Res> {
  __$AffectedUserInfoCopyWithImpl(this._self, this._then);

  final _AffectedUserInfo _self;
  final $Res Function(_AffectedUserInfo) _then;

  /// Create a copy of AffectedUserInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? affectedFields = null,
    Object? accessedAt = freezed,
    Object? notified = null,
  }) {
    return _then(_AffectedUserInfo(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      affectedFields: null == affectedFields
          ? _self._affectedFields
          : affectedFields // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      accessedAt: freezed == accessedAt
          ? _self.accessedAt
          : accessedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notified: null == notified
          ? _self.notified
          : notified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$BreachReport {
  /// Unique identifier for this breach.
  String get id;

  /// When the breach was detected.
  DateTime get detectedAt;

  /// List of affected user IDs.
  List<String> get affectedUsers;

  /// Categories of data that were affected.
  Set<String> get affectedDataCategories;

  /// Description of the breach.
  String get description;

  /// Timeline of events related to this breach.
  List<BreachEvent> get timeline;

  /// Create a copy of BreachReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BreachReportCopyWith<BreachReport> get copyWith =>
      _$BreachReportCopyWithImpl<BreachReport>(
          this as BreachReport, _$identity);

  /// Serializes this BreachReport to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BreachReport &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.detectedAt, detectedAt) ||
                other.detectedAt == detectedAt) &&
            const DeepCollectionEquality()
                .equals(other.affectedUsers, affectedUsers) &&
            const DeepCollectionEquality()
                .equals(other.affectedDataCategories, affectedDataCategories) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.timeline, timeline));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      detectedAt,
      const DeepCollectionEquality().hash(affectedUsers),
      const DeepCollectionEquality().hash(affectedDataCategories),
      description,
      const DeepCollectionEquality().hash(timeline));

  @override
  String toString() {
    return 'BreachReport(id: $id, detectedAt: $detectedAt, affectedUsers: $affectedUsers, affectedDataCategories: $affectedDataCategories, description: $description, timeline: $timeline)';
  }
}

/// @nodoc
abstract mixin class $BreachReportCopyWith<$Res> {
  factory $BreachReportCopyWith(
          BreachReport value, $Res Function(BreachReport) _then) =
      _$BreachReportCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateTime detectedAt,
      List<String> affectedUsers,
      Set<String> affectedDataCategories,
      String description,
      List<BreachEvent> timeline});
}

/// @nodoc
class _$BreachReportCopyWithImpl<$Res> implements $BreachReportCopyWith<$Res> {
  _$BreachReportCopyWithImpl(this._self, this._then);

  final BreachReport _self;
  final $Res Function(BreachReport) _then;

  /// Create a copy of BreachReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? detectedAt = null,
    Object? affectedUsers = null,
    Object? affectedDataCategories = null,
    Object? description = null,
    Object? timeline = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      detectedAt: null == detectedAt
          ? _self.detectedAt
          : detectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      affectedUsers: null == affectedUsers
          ? _self.affectedUsers
          : affectedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      affectedDataCategories: null == affectedDataCategories
          ? _self.affectedDataCategories
          : affectedDataCategories // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timeline: null == timeline
          ? _self.timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as List<BreachEvent>,
    ));
  }
}

/// Adds pattern-matching-related methods to [BreachReport].
extension BreachReportPatterns on BreachReport {
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
    TResult Function(_BreachReport value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BreachReport() when $default != null:
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
    TResult Function(_BreachReport value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachReport():
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
    TResult? Function(_BreachReport value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachReport() when $default != null:
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
            String id,
            DateTime detectedAt,
            List<String> affectedUsers,
            Set<String> affectedDataCategories,
            String description,
            List<BreachEvent> timeline)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BreachReport() when $default != null:
        return $default(_that.id, _that.detectedAt, _that.affectedUsers,
            _that.affectedDataCategories, _that.description, _that.timeline);
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
            String id,
            DateTime detectedAt,
            List<String> affectedUsers,
            Set<String> affectedDataCategories,
            String description,
            List<BreachEvent> timeline)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachReport():
        return $default(_that.id, _that.detectedAt, _that.affectedUsers,
            _that.affectedDataCategories, _that.description, _that.timeline);
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
            String id,
            DateTime detectedAt,
            List<String> affectedUsers,
            Set<String> affectedDataCategories,
            String description,
            List<BreachEvent> timeline)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BreachReport() when $default != null:
        return $default(_that.id, _that.detectedAt, _that.affectedUsers,
            _that.affectedDataCategories, _that.description, _that.timeline);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BreachReport extends BreachReport {
  const _BreachReport(
      {required this.id,
      required this.detectedAt,
      required final List<String> affectedUsers,
      required final Set<String> affectedDataCategories,
      required this.description,
      final List<BreachEvent> timeline = const []})
      : _affectedUsers = affectedUsers,
        _affectedDataCategories = affectedDataCategories,
        _timeline = timeline,
        super._();
  factory _BreachReport.fromJson(Map<String, dynamic> json) =>
      _$BreachReportFromJson(json);

  /// Unique identifier for this breach.
  @override
  final String id;

  /// When the breach was detected.
  @override
  final DateTime detectedAt;

  /// List of affected user IDs.
  final List<String> _affectedUsers;

  /// List of affected user IDs.
  @override
  List<String> get affectedUsers {
    if (_affectedUsers is EqualUnmodifiableListView) return _affectedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_affectedUsers);
  }

  /// Categories of data that were affected.
  final Set<String> _affectedDataCategories;

  /// Categories of data that were affected.
  @override
  Set<String> get affectedDataCategories {
    if (_affectedDataCategories is EqualUnmodifiableSetView)
      return _affectedDataCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_affectedDataCategories);
  }

  /// Description of the breach.
  @override
  final String description;

  /// Timeline of events related to this breach.
  final List<BreachEvent> _timeline;

  /// Timeline of events related to this breach.
  @override
  @JsonKey()
  List<BreachEvent> get timeline {
    if (_timeline is EqualUnmodifiableListView) return _timeline;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_timeline);
  }

  /// Create a copy of BreachReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BreachReportCopyWith<_BreachReport> get copyWith =>
      __$BreachReportCopyWithImpl<_BreachReport>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BreachReportToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BreachReport &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.detectedAt, detectedAt) ||
                other.detectedAt == detectedAt) &&
            const DeepCollectionEquality()
                .equals(other._affectedUsers, _affectedUsers) &&
            const DeepCollectionEquality().equals(
                other._affectedDataCategories, _affectedDataCategories) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._timeline, _timeline));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      detectedAt,
      const DeepCollectionEquality().hash(_affectedUsers),
      const DeepCollectionEquality().hash(_affectedDataCategories),
      description,
      const DeepCollectionEquality().hash(_timeline));

  @override
  String toString() {
    return 'BreachReport(id: $id, detectedAt: $detectedAt, affectedUsers: $affectedUsers, affectedDataCategories: $affectedDataCategories, description: $description, timeline: $timeline)';
  }
}

/// @nodoc
abstract mixin class _$BreachReportCopyWith<$Res>
    implements $BreachReportCopyWith<$Res> {
  factory _$BreachReportCopyWith(
          _BreachReport value, $Res Function(_BreachReport) _then) =
      __$BreachReportCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime detectedAt,
      List<String> affectedUsers,
      Set<String> affectedDataCategories,
      String description,
      List<BreachEvent> timeline});
}

/// @nodoc
class __$BreachReportCopyWithImpl<$Res>
    implements _$BreachReportCopyWith<$Res> {
  __$BreachReportCopyWithImpl(this._self, this._then);

  final _BreachReport _self;
  final $Res Function(_BreachReport) _then;

  /// Create a copy of BreachReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? detectedAt = null,
    Object? affectedUsers = null,
    Object? affectedDataCategories = null,
    Object? description = null,
    Object? timeline = null,
  }) {
    return _then(_BreachReport(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      detectedAt: null == detectedAt
          ? _self.detectedAt
          : detectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      affectedUsers: null == affectedUsers
          ? _self._affectedUsers
          : affectedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      affectedDataCategories: null == affectedDataCategories
          ? _self._affectedDataCategories
          : affectedDataCategories // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timeline: null == timeline
          ? _self._timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as List<BreachEvent>,
    ));
  }
}

// dart format on
