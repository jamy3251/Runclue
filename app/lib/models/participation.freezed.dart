// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'participation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Participation _$ParticipationFromJson(Map<String, dynamic> json) {
  return _Participation.fromJson(json);
}

/// @nodoc
mixin _$Participation {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'clue_id')
  String get clueId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'clan_id')
  String? get clanId => throw _privateConstructorUsedError;
  ParticipationStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_step_index')
  int get currentStepIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  DateTime? get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_points_earned')
  int get totalPointsEarned => throw _privateConstructorUsedError;
  int? get rank => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  Clue? get clue => throw _privateConstructorUsedError;
  Profile? get user => throw _privateConstructorUsedError;

  /// Serializes this Participation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipationCopyWith<Participation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipationCopyWith<$Res> {
  factory $ParticipationCopyWith(
          Participation value, $Res Function(Participation) then) =
      _$ParticipationCopyWithImpl<$Res, Participation>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'clan_id') String? clanId,
      ParticipationStatus status,
      @JsonKey(name: 'current_step_index') int currentStepIndex,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'total_points_earned') int totalPointsEarned,
      int? rank,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      Clue? clue,
      Profile? user});

  $ClueCopyWith<$Res>? get clue;
  $ProfileCopyWith<$Res>? get user;
}

/// @nodoc
class _$ParticipationCopyWithImpl<$Res, $Val extends Participation>
    implements $ParticipationCopyWith<$Res> {
  _$ParticipationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clueId = null,
    Object? userId = null,
    Object? clanId = freezed,
    Object? status = null,
    Object? currentStepIndex = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? totalPointsEarned = null,
    Object? rank = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? clue = freezed,
    Object? user = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      clanId: freezed == clanId
          ? _value.clanId
          : clanId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ParticipationStatus,
      currentStepIndex: null == currentStepIndex
          ? _value.currentStepIndex
          : currentStepIndex // ignore: cast_nullable_to_non_nullable
              as int,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalPointsEarned: null == totalPointsEarned
          ? _value.totalPointsEarned
          : totalPointsEarned // ignore: cast_nullable_to_non_nullable
              as int,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clue: freezed == clue
          ? _value.clue
          : clue // ignore: cast_nullable_to_non_nullable
              as Clue?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ) as $Val);
  }

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClueCopyWith<$Res>? get clue {
    if (_value.clue == null) {
      return null;
    }

    return $ClueCopyWith<$Res>(_value.clue!, (value) {
      return _then(_value.copyWith(clue: value) as $Val);
    });
  }

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $ProfileCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ParticipationImplCopyWith<$Res>
    implements $ParticipationCopyWith<$Res> {
  factory _$$ParticipationImplCopyWith(
          _$ParticipationImpl value, $Res Function(_$ParticipationImpl) then) =
      __$$ParticipationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'clan_id') String? clanId,
      ParticipationStatus status,
      @JsonKey(name: 'current_step_index') int currentStepIndex,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'total_points_earned') int totalPointsEarned,
      int? rank,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      Clue? clue,
      Profile? user});

  @override
  $ClueCopyWith<$Res>? get clue;
  @override
  $ProfileCopyWith<$Res>? get user;
}

/// @nodoc
class __$$ParticipationImplCopyWithImpl<$Res>
    extends _$ParticipationCopyWithImpl<$Res, _$ParticipationImpl>
    implements _$$ParticipationImplCopyWith<$Res> {
  __$$ParticipationImplCopyWithImpl(
      _$ParticipationImpl _value, $Res Function(_$ParticipationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clueId = null,
    Object? userId = null,
    Object? clanId = freezed,
    Object? status = null,
    Object? currentStepIndex = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? totalPointsEarned = null,
    Object? rank = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? clue = freezed,
    Object? user = freezed,
  }) {
    return _then(_$ParticipationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      clanId: freezed == clanId
          ? _value.clanId
          : clanId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ParticipationStatus,
      currentStepIndex: null == currentStepIndex
          ? _value.currentStepIndex
          : currentStepIndex // ignore: cast_nullable_to_non_nullable
              as int,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalPointsEarned: null == totalPointsEarned
          ? _value.totalPointsEarned
          : totalPointsEarned // ignore: cast_nullable_to_non_nullable
              as int,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clue: freezed == clue
          ? _value.clue
          : clue // ignore: cast_nullable_to_non_nullable
              as Clue?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ParticipationImpl implements _Participation {
  const _$ParticipationImpl(
      {required this.id,
      @JsonKey(name: 'clue_id') required this.clueId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'clan_id') this.clanId,
      this.status = ParticipationStatus.joined,
      @JsonKey(name: 'current_step_index') this.currentStepIndex = 0,
      @JsonKey(name: 'started_at') this.startedAt,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'total_points_earned') this.totalPointsEarned = 0,
      this.rank,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      this.clue,
      this.user});

  factory _$ParticipationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParticipationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'clue_id')
  final String clueId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'clan_id')
  final String? clanId;
  @override
  @JsonKey()
  final ParticipationStatus status;
  @override
  @JsonKey(name: 'current_step_index')
  final int currentStepIndex;
  @override
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'total_points_earned')
  final int totalPointsEarned;
  @override
  final int? rank;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  final Clue? clue;
  @override
  final Profile? user;

  @override
  String toString() {
    return 'Participation(id: $id, clueId: $clueId, userId: $userId, clanId: $clanId, status: $status, currentStepIndex: $currentStepIndex, startedAt: $startedAt, completedAt: $completedAt, totalPointsEarned: $totalPointsEarned, rank: $rank, createdAt: $createdAt, updatedAt: $updatedAt, clue: $clue, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clueId, clueId) || other.clueId == clueId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.clanId, clanId) || other.clanId == clanId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentStepIndex, currentStepIndex) ||
                other.currentStepIndex == currentStepIndex) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.totalPointsEarned, totalPointsEarned) ||
                other.totalPointsEarned == totalPointsEarned) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.clue, clue) || other.clue == clue) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      clueId,
      userId,
      clanId,
      status,
      currentStepIndex,
      startedAt,
      completedAt,
      totalPointsEarned,
      rank,
      createdAt,
      updatedAt,
      clue,
      user);

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipationImplCopyWith<_$ParticipationImpl> get copyWith =>
      __$$ParticipationImplCopyWithImpl<_$ParticipationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParticipationImplToJson(
      this,
    );
  }
}

abstract class _Participation implements Participation {
  const factory _Participation(
      {required final String id,
      @JsonKey(name: 'clue_id') required final String clueId,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'clan_id') final String? clanId,
      final ParticipationStatus status,
      @JsonKey(name: 'current_step_index') final int currentStepIndex,
      @JsonKey(name: 'started_at') final DateTime? startedAt,
      @JsonKey(name: 'completed_at') final DateTime? completedAt,
      @JsonKey(name: 'total_points_earned') final int totalPointsEarned,
      final int? rank,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      final Clue? clue,
      final Profile? user}) = _$ParticipationImpl;

  factory _Participation.fromJson(Map<String, dynamic> json) =
      _$ParticipationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'clue_id')
  String get clueId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'clan_id')
  String? get clanId;
  @override
  ParticipationStatus get status;
  @override
  @JsonKey(name: 'current_step_index')
  int get currentStepIndex;
  @override
  @JsonKey(name: 'started_at')
  DateTime? get startedAt;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'total_points_earned')
  int get totalPointsEarned;
  @override
  int? get rank;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  Clue? get clue;
  @override
  Profile? get user;

  /// Create a copy of Participation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipationImplCopyWith<_$ParticipationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
