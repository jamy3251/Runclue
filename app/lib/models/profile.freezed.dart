// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  String get nickname => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_points')
  int get totalPoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'badge_count')
  int get badgeCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'clues_created')
  int get cluesCreated => throw _privateConstructorUsedError;
  @JsonKey(name: 'clues_completed')
  int get cluesCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_creator')
  bool get isCreator => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call(
      {String id,
      String nickname,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      String? bio,
      @JsonKey(name: 'total_points') int totalPoints,
      @JsonKey(name: 'badge_count') int badgeCount,
      @JsonKey(name: 'clues_created') int cluesCreated,
      @JsonKey(name: 'clues_completed') int cluesCompleted,
      @JsonKey(name: 'is_creator') bool isCreator,
      String role,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nickname = null,
    Object? avatarUrl = freezed,
    Object? bio = freezed,
    Object? totalPoints = null,
    Object? badgeCount = null,
    Object? cluesCreated = null,
    Object? cluesCompleted = null,
    Object? isCreator = null,
    Object? role = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      cluesCreated: null == cluesCreated
          ? _value.cluesCreated
          : cluesCreated // ignore: cast_nullable_to_non_nullable
              as int,
      cluesCompleted: null == cluesCompleted
          ? _value.cluesCompleted
          : cluesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      isCreator: null == isCreator
          ? _value.isCreator
          : isCreator // ignore: cast_nullable_to_non_nullable
              as bool,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
          _$ProfileImpl value, $Res Function(_$ProfileImpl) then) =
      __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String nickname,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      String? bio,
      @JsonKey(name: 'total_points') int totalPoints,
      @JsonKey(name: 'badge_count') int badgeCount,
      @JsonKey(name: 'clues_created') int cluesCreated,
      @JsonKey(name: 'clues_completed') int cluesCompleted,
      @JsonKey(name: 'is_creator') bool isCreator,
      String role,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
      _$ProfileImpl _value, $Res Function(_$ProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nickname = null,
    Object? avatarUrl = freezed,
    Object? bio = freezed,
    Object? totalPoints = null,
    Object? badgeCount = null,
    Object? cluesCreated = null,
    Object? cluesCompleted = null,
    Object? isCreator = null,
    Object? role = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      cluesCreated: null == cluesCreated
          ? _value.cluesCreated
          : cluesCreated // ignore: cast_nullable_to_non_nullable
              as int,
      cluesCompleted: null == cluesCompleted
          ? _value.cluesCompleted
          : cluesCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      isCreator: null == isCreator
          ? _value.isCreator
          : isCreator // ignore: cast_nullable_to_non_nullable
              as bool,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl implements _Profile {
  const _$ProfileImpl(
      {required this.id,
      required this.nickname,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      this.bio,
      @JsonKey(name: 'total_points') this.totalPoints = 0,
      @JsonKey(name: 'badge_count') this.badgeCount = 0,
      @JsonKey(name: 'clues_created') this.cluesCreated = 0,
      @JsonKey(name: 'clues_completed') this.cluesCompleted = 0,
      @JsonKey(name: 'is_creator') this.isCreator = false,
      this.role = 'user',
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String nickname;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  final String? bio;
  @override
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @override
  @JsonKey(name: 'badge_count')
  final int badgeCount;
  @override
  @JsonKey(name: 'clues_created')
  final int cluesCreated;
  @override
  @JsonKey(name: 'clues_completed')
  final int cluesCompleted;
  @override
  @JsonKey(name: 'is_creator')
  final bool isCreator;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Profile(id: $id, nickname: $nickname, avatarUrl: $avatarUrl, bio: $bio, totalPoints: $totalPoints, badgeCount: $badgeCount, cluesCreated: $cluesCreated, cluesCompleted: $cluesCompleted, isCreator: $isCreator, role: $role, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.badgeCount, badgeCount) ||
                other.badgeCount == badgeCount) &&
            (identical(other.cluesCreated, cluesCreated) ||
                other.cluesCreated == cluesCreated) &&
            (identical(other.cluesCompleted, cluesCompleted) ||
                other.cluesCompleted == cluesCompleted) &&
            (identical(other.isCreator, isCreator) ||
                other.isCreator == isCreator) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      nickname,
      avatarUrl,
      bio,
      totalPoints,
      badgeCount,
      cluesCreated,
      cluesCompleted,
      isCreator,
      role,
      createdAt,
      updatedAt);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(
      this,
    );
  }
}

abstract class _Profile implements Profile {
  const factory _Profile(
      {required final String id,
      required final String nickname,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      final String? bio,
      @JsonKey(name: 'total_points') final int totalPoints,
      @JsonKey(name: 'badge_count') final int badgeCount,
      @JsonKey(name: 'clues_created') final int cluesCreated,
      @JsonKey(name: 'clues_completed') final int cluesCompleted,
      @JsonKey(name: 'is_creator') final bool isCreator,
      final String role,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt}) = _$ProfileImpl;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get nickname;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  String? get bio;
  @override
  @JsonKey(name: 'total_points')
  int get totalPoints;
  @override
  @JsonKey(name: 'badge_count')
  int get badgeCount;
  @override
  @JsonKey(name: 'clues_created')
  int get cluesCreated;
  @override
  @JsonKey(name: 'clues_completed')
  int get cluesCompleted;
  @override
  @JsonKey(name: 'is_creator')
  bool get isCreator;
  @override
  String get role;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
