// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RewardImpl _$$RewardImplFromJson(Map<String, dynamic> json) => _$RewardImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clueId: json['clue_id'] as String,
      participationId: json['participation_id'] as String,
      type: $enumDecode(_$RewardTypeEnumMap, json['type']),
      value: json['value'] as String?,
      badgeName: json['badge_name'] as String?,
      badgeIconUrl: json['badge_icon_url'] as String?,
      couponCode: json['coupon_code'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? false,
      claimedAt: json['claimed_at'] == null
          ? null
          : DateTime.parse(json['claimed_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$RewardImplToJson(_$RewardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'clue_id': instance.clueId,
      'participation_id': instance.participationId,
      'type': _$RewardTypeEnumMap[instance.type]!,
      'value': instance.value,
      'badge_name': instance.badgeName,
      'badge_icon_url': instance.badgeIconUrl,
      'coupon_code': instance.couponCode,
      'is_claimed': instance.isClaimed,
      'claimed_at': instance.claimedAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$RewardTypeEnumMap = {
  RewardType.points: 'points',
  RewardType.badge: 'badge',
  RewardType.coupon: 'coupon',
  RewardType.prize: 'prize',
  RewardType.certificate: 'certificate',
};
