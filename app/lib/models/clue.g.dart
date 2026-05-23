// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClueImpl _$$ClueImplFromJson(Map<String, dynamic> json) => _$ClueImpl(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: $enumDecode(_$ClueCategoryEnumMap, json['category']),
      status: $enumDecodeNullable(_$ClueStatusEnumMap, json['status']) ??
          ClueStatus.draft,
      isPublic: json['is_public'] as bool? ?? true,
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      currentParticipants: (json['current_participants'] as num?)?.toInt() ?? 0,
      gameMode: $enumDecodeNullable(_$ClueGameModeEnumMap, json['game_mode']) ??
          ClueGameMode.solo,
      minParticipants: (json['min_participants'] as num?)?.toInt() ?? 1,
      lobbyWindowMinutes: (json['lobby_window_minutes'] as num?)?.toInt() ?? 30,
      lobbyStartedAt: json['lobby_started_at'] == null
          ? null
          : DateTime.parse(json['lobby_started_at'] as String),
      coopState: $enumDecodeNullable(_$CoopStateEnumMap, json['coop_state']) ??
          CoopState.idle,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      timeLimitMinutes: (json['time_limit_minutes'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble(),
      address: json['address'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      rewardType: json['reward_type'] as String?,
      rewardValue: json['reward_value'] as String?,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      isPrizeType: json['is_prize_type'] as bool? ?? false,
      isBroadcastType: json['is_broadcast_type'] as bool? ?? false,
      minAge: (json['min_age'] as num?)?.toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ClueStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      creatorProfile: json['creator_profile'] == null
          ? null
          : Profile.fromJson(json['creator_profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ClueImplToJson(_$ClueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'creator_id': instance.creatorId,
      'title': instance.title,
      'description': instance.description,
      'category': _$ClueCategoryEnumMap[instance.category]!,
      'status': _$ClueStatusEnumMap[instance.status]!,
      'is_public': instance.isPublic,
      'max_participants': instance.maxParticipants,
      'current_participants': instance.currentParticipants,
      'game_mode': _$ClueGameModeEnumMap[instance.gameMode]!,
      'min_participants': instance.minParticipants,
      'lobby_window_minutes': instance.lobbyWindowMinutes,
      'lobby_started_at': instance.lobbyStartedAt?.toIso8601String(),
      'coop_state': _$CoopStateEnumMap[instance.coopState]!,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'time_limit_minutes': instance.timeLimitMinutes,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius_meters': instance.radiusMeters,
      'address': instance.address,
      'thumbnail_url': instance.thumbnailUrl,
      'reward_type': instance.rewardType,
      'reward_value': instance.rewardValue,
      'requires_approval': instance.requiresApproval,
      'is_prize_type': instance.isPrizeType,
      'is_broadcast_type': instance.isBroadcastType,
      'min_age': instance.minAge,
      'tags': instance.tags,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'steps': instance.steps,
      'creator_profile': instance.creatorProfile,
    };

const _$ClueCategoryEnumMap = {
  ClueCategory.adventure: 'adventure',
  ClueCategory.quiz: 'quiz',
  ClueCategory.education: 'education',
  ClueCategory.lifeHelp: 'life_help',
  ClueCategory.promotion: 'promotion',
  ClueCategory.workshop: 'workshop',
  ClueCategory.broadcast: 'broadcast',
};

const _$ClueStatusEnumMap = {
  ClueStatus.draft: 'draft',
  ClueStatus.pendingApproval: 'pending_approval',
  ClueStatus.approved: 'approved',
  ClueStatus.active: 'active',
  ClueStatus.completed: 'completed',
  ClueStatus.rejected: 'rejected',
  ClueStatus.suspended: 'suspended',
};

const _$ClueGameModeEnumMap = {
  ClueGameMode.solo: 'solo',
  ClueGameMode.coop: 'coop',
};

const _$CoopStateEnumMap = {
  CoopState.idle: 'idle',
  CoopState.recruiting: 'recruiting',
  CoopState.started: 'started',
  CoopState.cancelled: 'cancelled',
};
