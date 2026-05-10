import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

@JsonEnum(valueField: 'value')
enum RewardType {
  @JsonValue('points')
  points('points'),
  @JsonValue('badge')
  badge('badge'),
  @JsonValue('coupon')
  coupon('coupon'),
  @JsonValue('prize')
  prize('prize'),
  @JsonValue('certificate')
  certificate('certificate');

  const RewardType(this.value);
  final String value;
}

@freezed
class Reward with _$Reward {
  const factory Reward({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'clue_id') required String clueId,
    @JsonKey(name: 'participation_id') required String participationId,
    required RewardType type,
    String? value,
    @JsonKey(name: 'badge_name') String? badgeName,
    @JsonKey(name: 'badge_icon_url') String? badgeIconUrl,
    @JsonKey(name: 'coupon_code') String? couponCode,
    @Default(false) @JsonKey(name: 'is_claimed') bool isClaimed,
    @JsonKey(name: 'claimed_at') DateTime? claimedAt,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Reward;

  factory Reward.fromJson(Map<String, dynamic> json) =>
      _$RewardFromJson(json);
}
