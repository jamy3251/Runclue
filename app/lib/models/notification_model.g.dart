// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'is_read': instance.isRead,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.clueApproved: 'clue_approved',
  NotificationType.clueRejected: 'clue_rejected',
  NotificationType.newParticipant: 'new_participant',
  NotificationType.stepCompleted: 'step_completed',
  NotificationType.clueCompleted: 'clue_completed',
  NotificationType.rewardEarned: 'reward_earned',
  NotificationType.clanInvite: 'clan_invite',
  NotificationType.evidenceReviewed: 'evidence_reviewed',
  NotificationType.system: 'system',
};
