import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@JsonEnum(valueField: 'value')
enum NotificationType {
  @JsonValue('clue_approved')
  clueApproved('clue_approved'),
  @JsonValue('clue_rejected')
  clueRejected('clue_rejected'),
  @JsonValue('new_participant')
  newParticipant('new_participant'),
  @JsonValue('step_completed')
  stepCompleted('step_completed'),
  @JsonValue('clue_completed')
  clueCompleted('clue_completed'),
  @JsonValue('reward_earned')
  rewardEarned('reward_earned'),
  @JsonValue('clan_invite')
  clanInvite('clan_invite'),
  @JsonValue('evidence_reviewed')
  evidenceReviewed('evidence_reviewed'),
  @JsonValue('system')
  system('system');

  const NotificationType(this.value);
  final String value;
}

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    @Default(false) @JsonKey(name: 'is_read') bool isRead,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
