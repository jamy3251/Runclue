// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Reward _$RewardFromJson(Map<String, dynamic> json) {
  return _Reward.fromJson(json);
}

/// @nodoc
mixin _$Reward {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'clue_id')
  String get clueId => throw _privateConstructorUsedError;
  @JsonKey(name: 'participation_id')
  String get participationId => throw _privateConstructorUsedError;
  RewardType get type => throw _privateConstructorUsedError;
  String? get value => throw _privateConstructorUsedError;
  @JsonKey(name: 'badge_name')
  String? get badgeName => throw _privateConstructorUsedError;
  @JsonKey(name: 'badge_icon_url')
  String? get badgeIconUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'coupon_code')
  String? get couponCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_claimed')
  bool get isClaimed => throw _privateConstructorUsedError;
  @JsonKey(name: 'claimed_at')
  DateTime? get claimedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Reward to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RewardCopyWith<Reward> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardCopyWith<$Res> {
  factory $RewardCopyWith(Reward value, $Res Function(Reward) then) =
      _$RewardCopyWithImpl<$Res, Reward>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'participation_id') String participationId,
      RewardType type,
      String? value,
      @JsonKey(name: 'badge_name') String? badgeName,
      @JsonKey(name: 'badge_icon_url') String? badgeIconUrl,
      @JsonKey(name: 'coupon_code') String? couponCode,
      @JsonKey(name: 'is_claimed') bool isClaimed,
      @JsonKey(name: 'claimed_at') DateTime? claimedAt,
      @JsonKey(name: 'expires_at') DateTime? expiresAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$RewardCopyWithImpl<$Res, $Val extends Reward>
    implements $RewardCopyWith<$Res> {
  _$RewardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? clueId = null,
    Object? participationId = null,
    Object? type = null,
    Object? value = freezed,
    Object? badgeName = freezed,
    Object? badgeIconUrl = freezed,
    Object? couponCode = freezed,
    Object? isClaimed = null,
    Object? claimedAt = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      participationId: null == participationId
          ? _value.participationId
          : participationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RewardType,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      badgeName: freezed == badgeName
          ? _value.badgeName
          : badgeName // ignore: cast_nullable_to_non_nullable
              as String?,
      badgeIconUrl: freezed == badgeIconUrl
          ? _value.badgeIconUrl
          : badgeIconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      couponCode: freezed == couponCode
          ? _value.couponCode
          : couponCode // ignore: cast_nullable_to_non_nullable
              as String?,
      isClaimed: null == isClaimed
          ? _value.isClaimed
          : isClaimed // ignore: cast_nullable_to_non_nullable
              as bool,
      claimedAt: freezed == claimedAt
          ? _value.claimedAt
          : claimedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RewardImplCopyWith<$Res> implements $RewardCopyWith<$Res> {
  factory _$$RewardImplCopyWith(
          _$RewardImpl value, $Res Function(_$RewardImpl) then) =
      __$$RewardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'participation_id') String participationId,
      RewardType type,
      String? value,
      @JsonKey(name: 'badge_name') String? badgeName,
      @JsonKey(name: 'badge_icon_url') String? badgeIconUrl,
      @JsonKey(name: 'coupon_code') String? couponCode,
      @JsonKey(name: 'is_claimed') bool isClaimed,
      @JsonKey(name: 'claimed_at') DateTime? claimedAt,
      @JsonKey(name: 'expires_at') DateTime? expiresAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$RewardImplCopyWithImpl<$Res>
    extends _$RewardCopyWithImpl<$Res, _$RewardImpl>
    implements _$$RewardImplCopyWith<$Res> {
  __$$RewardImplCopyWithImpl(
      _$RewardImpl _value, $Res Function(_$RewardImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? clueId = null,
    Object? participationId = null,
    Object? type = null,
    Object? value = freezed,
    Object? badgeName = freezed,
    Object? badgeIconUrl = freezed,
    Object? couponCode = freezed,
    Object? isClaimed = null,
    Object? claimedAt = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$RewardImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      participationId: null == participationId
          ? _value.participationId
          : participationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RewardType,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
      badgeName: freezed == badgeName
          ? _value.badgeName
          : badgeName // ignore: cast_nullable_to_non_nullable
              as String?,
      badgeIconUrl: freezed == badgeIconUrl
          ? _value.badgeIconUrl
          : badgeIconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      couponCode: freezed == couponCode
          ? _value.couponCode
          : couponCode // ignore: cast_nullable_to_non_nullable
              as String?,
      isClaimed: null == isClaimed
          ? _value.isClaimed
          : isClaimed // ignore: cast_nullable_to_non_nullable
              as bool,
      claimedAt: freezed == claimedAt
          ? _value.claimedAt
          : claimedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RewardImpl implements _Reward {
  const _$RewardImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'clue_id') required this.clueId,
      @JsonKey(name: 'participation_id') required this.participationId,
      required this.type,
      this.value,
      @JsonKey(name: 'badge_name') this.badgeName,
      @JsonKey(name: 'badge_icon_url') this.badgeIconUrl,
      @JsonKey(name: 'coupon_code') this.couponCode,
      @JsonKey(name: 'is_claimed') this.isClaimed = false,
      @JsonKey(name: 'claimed_at') this.claimedAt,
      @JsonKey(name: 'expires_at') this.expiresAt,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$RewardImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'clue_id')
  final String clueId;
  @override
  @JsonKey(name: 'participation_id')
  final String participationId;
  @override
  final RewardType type;
  @override
  final String? value;
  @override
  @JsonKey(name: 'badge_name')
  final String? badgeName;
  @override
  @JsonKey(name: 'badge_icon_url')
  final String? badgeIconUrl;
  @override
  @JsonKey(name: 'coupon_code')
  final String? couponCode;
  @override
  @JsonKey(name: 'is_claimed')
  final bool isClaimed;
  @override
  @JsonKey(name: 'claimed_at')
  final DateTime? claimedAt;
  @override
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Reward(id: $id, userId: $userId, clueId: $clueId, participationId: $participationId, type: $type, value: $value, badgeName: $badgeName, badgeIconUrl: $badgeIconUrl, couponCode: $couponCode, isClaimed: $isClaimed, claimedAt: $claimedAt, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.clueId, clueId) || other.clueId == clueId) &&
            (identical(other.participationId, participationId) ||
                other.participationId == participationId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.badgeName, badgeName) ||
                other.badgeName == badgeName) &&
            (identical(other.badgeIconUrl, badgeIconUrl) ||
                other.badgeIconUrl == badgeIconUrl) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.isClaimed, isClaimed) ||
                other.isClaimed == isClaimed) &&
            (identical(other.claimedAt, claimedAt) ||
                other.claimedAt == claimedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      clueId,
      participationId,
      type,
      value,
      badgeName,
      badgeIconUrl,
      couponCode,
      isClaimed,
      claimedAt,
      expiresAt,
      createdAt);

  /// Create a copy of Reward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardImplCopyWith<_$RewardImpl> get copyWith =>
      __$$RewardImplCopyWithImpl<_$RewardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RewardImplToJson(
      this,
    );
  }
}

abstract class _Reward implements Reward {
  const factory _Reward(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'clue_id') required final String clueId,
      @JsonKey(name: 'participation_id') required final String participationId,
      required final RewardType type,
      final String? value,
      @JsonKey(name: 'badge_name') final String? badgeName,
      @JsonKey(name: 'badge_icon_url') final String? badgeIconUrl,
      @JsonKey(name: 'coupon_code') final String? couponCode,
      @JsonKey(name: 'is_claimed') final bool isClaimed,
      @JsonKey(name: 'claimed_at') final DateTime? claimedAt,
      @JsonKey(name: 'expires_at') final DateTime? expiresAt,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$RewardImpl;

  factory _Reward.fromJson(Map<String, dynamic> json) = _$RewardImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'clue_id')
  String get clueId;
  @override
  @JsonKey(name: 'participation_id')
  String get participationId;
  @override
  RewardType get type;
  @override
  String? get value;
  @override
  @JsonKey(name: 'badge_name')
  String? get badgeName;
  @override
  @JsonKey(name: 'badge_icon_url')
  String? get badgeIconUrl;
  @override
  @JsonKey(name: 'coupon_code')
  String? get couponCode;
  @override
  @JsonKey(name: 'is_claimed')
  bool get isClaimed;
  @override
  @JsonKey(name: 'claimed_at')
  DateTime? get claimedAt;
  @override
  @JsonKey(name: 'expires_at')
  DateTime? get expiresAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Reward
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardImplCopyWith<_$RewardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
