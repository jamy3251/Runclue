import 'package:freezed_annotation/freezed_annotation.dart';

import 'clue_step.dart';
import 'profile.dart';

part 'clue.freezed.dart';
part 'clue.g.dart';

@JsonEnum(valueField: 'value')
enum ClueCategory {
  @JsonValue('adventure')
  adventure('adventure'),
  @JsonValue('quiz')
  quiz('quiz'),
  @JsonValue('education')
  education('education'),
  @JsonValue('life_help')
  lifeHelp('life_help'),
  @JsonValue('promotion')
  promotion('promotion'),
  @JsonValue('workshop')
  workshop('workshop'),
  @JsonValue('broadcast')
  broadcast('broadcast');

  const ClueCategory(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum ClueGameMode {
  @JsonValue('solo')
  solo('solo'),
  @JsonValue('coop')
  coop('coop');

  const ClueGameMode(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum CoopState {
  @JsonValue('idle')
  idle('idle'),
  @JsonValue('recruiting')
  recruiting('recruiting'),
  @JsonValue('started')
  started('started'),
  @JsonValue('cancelled')
  cancelled('cancelled');

  const CoopState(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum ClueStatus {
  @JsonValue('draft')
  draft('draft'),
  @JsonValue('pending_approval')
  pendingApproval('pending_approval'),
  @JsonValue('approved')
  approved('approved'),
  @JsonValue('active')
  active('active'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('rejected')
  rejected('rejected'),
  @JsonValue('suspended')
  suspended('suspended');

  const ClueStatus(this.value);
  final String value;
}

@freezed
class Clue with _$Clue {
  const factory Clue({
    required String id,
    @JsonKey(name: 'creator_id') required String creatorId,
    required String title,
    String? description,
    required ClueCategory category,
    @Default(ClueStatus.draft) ClueStatus status,
    @Default(true) @JsonKey(name: 'is_public') bool isPublic,
    @JsonKey(name: 'max_participants') int? maxParticipants,
    @Default(0) @JsonKey(name: 'current_participants') int currentParticipants,
    @Default(ClueGameMode.solo) @JsonKey(name: 'game_mode') ClueGameMode gameMode,
    @Default(1) @JsonKey(name: 'min_participants') int minParticipants,
    @Default(30) @JsonKey(name: 'lobby_window_minutes') int lobbyWindowMinutes,
    @JsonKey(name: 'lobby_started_at') DateTime? lobbyStartedAt,
    @Default(CoopState.idle) @JsonKey(name: 'coop_state') CoopState coopState,
    @JsonKey(name: 'start_time') DateTime? startTime,
    @JsonKey(name: 'end_time') DateTime? endTime,
    @JsonKey(name: 'time_limit_minutes') int? timeLimitMinutes,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'radius_meters') double? radiusMeters,
    String? address,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'reward_type') String? rewardType,
    @JsonKey(name: 'reward_value') String? rewardValue,
    @Default(false) @JsonKey(name: 'requires_approval') bool requiresApproval,
    @Default(false) @JsonKey(name: 'is_prize_type') bool isPrizeType,
    @Default(false) @JsonKey(name: 'is_broadcast_type') bool isBroadcastType,
    @JsonKey(name: 'min_age') int? minAge,
    @Default([]) List<String> tags,
    @Default(0) @JsonKey(name: 'view_count') int viewCount,
    @Default(0) @JsonKey(name: 'like_count') int likeCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    List<ClueStep>? steps,
    @JsonKey(name: 'creator_profile') Profile? creatorProfile,
  }) = _Clue;

  factory Clue.fromJson(Map<String, dynamic> json) => _$ClueFromJson(json);
}
