// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ParticipationImpl _$$ParticipationImplFromJson(Map<String, dynamic> json) =>
    _$ParticipationImpl(
      id: json['id'] as String,
      clueId: json['clue_id'] as String,
      userId: json['user_id'] as String,
      clanId: json['clan_id'] as String?,
      status:
          $enumDecodeNullable(_$ParticipationStatusEnumMap, json['status']) ??
              ParticipationStatus.joined,
      currentStepIndex: (json['current_step_index'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      totalPointsEarned: (json['total_points_earned'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      clue: json['clue'] == null
          ? null
          : Clue.fromJson(json['clue'] as Map<String, dynamic>),
      user: json['user'] == null
          ? null
          : Profile.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ParticipationImplToJson(_$ParticipationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clue_id': instance.clueId,
      'user_id': instance.userId,
      'clan_id': instance.clanId,
      'status': _$ParticipationStatusEnumMap[instance.status]!,
      'current_step_index': instance.currentStepIndex,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'total_points_earned': instance.totalPointsEarned,
      'rank': instance.rank,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'clue': instance.clue,
      'user': instance.user,
    };

const _$ParticipationStatusEnumMap = {
  ParticipationStatus.joined: 'joined',
  ParticipationStatus.inProgress: 'in_progress',
  ParticipationStatus.completed: 'completed',
  ParticipationStatus.abandoned: 'abandoned',
  ParticipationStatus.disqualified: 'disqualified',
};
