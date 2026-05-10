// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Clan _$ClanFromJson(Map<String, dynamic> json) {
  return _Clan.fromJson(json);
}

/// @nodoc
mixin _$Clan {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'leader_id')
  String get leaderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_count')
  int get memberCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_points')
  int get totalPoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public')
  bool get isPublic => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_members')
  int get maxMembers => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Clan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Clan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClanCopyWith<Clan> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClanCopyWith<$Res> {
  factory $ClanCopyWith(Clan value, $Res Function(Clan) then) =
      _$ClanCopyWithImpl<$Res, Clan>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'leader_id') String leaderId,
      @JsonKey(name: 'member_count') int memberCount,
      @JsonKey(name: 'total_points') int totalPoints,
      @JsonKey(name: 'is_public') bool isPublic,
      @JsonKey(name: 'max_members') int maxMembers,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ClanCopyWithImpl<$Res, $Val extends Clan>
    implements $ClanCopyWith<$Res> {
  _$ClanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Clan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? avatarUrl = freezed,
    Object? leaderId = null,
    Object? memberCount = null,
    Object? totalPoints = null,
    Object? isPublic = null,
    Object? maxMembers = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      leaderId: null == leaderId
          ? _value.leaderId
          : leaderId // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
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
abstract class _$$ClanImplCopyWith<$Res> implements $ClanCopyWith<$Res> {
  factory _$$ClanImplCopyWith(
          _$ClanImpl value, $Res Function(_$ClanImpl) then) =
      __$$ClanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'leader_id') String leaderId,
      @JsonKey(name: 'member_count') int memberCount,
      @JsonKey(name: 'total_points') int totalPoints,
      @JsonKey(name: 'is_public') bool isPublic,
      @JsonKey(name: 'max_members') int maxMembers,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$ClanImplCopyWithImpl<$Res>
    extends _$ClanCopyWithImpl<$Res, _$ClanImpl>
    implements _$$ClanImplCopyWith<$Res> {
  __$$ClanImplCopyWithImpl(_$ClanImpl _value, $Res Function(_$ClanImpl) _then)
      : super(_value, _then);

  /// Create a copy of Clan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? avatarUrl = freezed,
    Object? leaderId = null,
    Object? memberCount = null,
    Object? totalPoints = null,
    Object? isPublic = null,
    Object? maxMembers = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ClanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      leaderId: null == leaderId
          ? _value.leaderId
          : leaderId // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
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
class _$ClanImpl implements _Clan {
  const _$ClanImpl(
      {required this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'leader_id') required this.leaderId,
      @JsonKey(name: 'member_count') this.memberCount = 1,
      @JsonKey(name: 'total_points') this.totalPoints = 0,
      @JsonKey(name: 'is_public') this.isPublic = true,
      @JsonKey(name: 'max_members') this.maxMembers = 50,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$ClanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClanImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'leader_id')
  final String leaderId;
  @override
  @JsonKey(name: 'member_count')
  final int memberCount;
  @override
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @override
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @override
  @JsonKey(name: 'max_members')
  final int maxMembers;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Clan(id: $id, name: $name, description: $description, avatarUrl: $avatarUrl, leaderId: $leaderId, memberCount: $memberCount, totalPoints: $totalPoints, isPublic: $isPublic, maxMembers: $maxMembers, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.leaderId, leaderId) ||
                other.leaderId == leaderId) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
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
      name,
      description,
      avatarUrl,
      leaderId,
      memberCount,
      totalPoints,
      isPublic,
      maxMembers,
      createdAt,
      updatedAt);

  /// Create a copy of Clan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClanImplCopyWith<_$ClanImpl> get copyWith =>
      __$$ClanImplCopyWithImpl<_$ClanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClanImplToJson(
      this,
    );
  }
}

abstract class _Clan implements Clan {
  const factory _Clan(
      {required final String id,
      required final String name,
      final String? description,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      @JsonKey(name: 'leader_id') required final String leaderId,
      @JsonKey(name: 'member_count') final int memberCount,
      @JsonKey(name: 'total_points') final int totalPoints,
      @JsonKey(name: 'is_public') final bool isPublic,
      @JsonKey(name: 'max_members') final int maxMembers,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt}) = _$ClanImpl;

  factory _Clan.fromJson(Map<String, dynamic> json) = _$ClanImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'leader_id')
  String get leaderId;
  @override
  @JsonKey(name: 'member_count')
  int get memberCount;
  @override
  @JsonKey(name: 'total_points')
  int get totalPoints;
  @override
  @JsonKey(name: 'is_public')
  bool get isPublic;
  @override
  @JsonKey(name: 'max_members')
  int get maxMembers;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Clan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClanImplCopyWith<_$ClanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
