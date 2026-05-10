// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      badgeCount: (json['badge_count'] as num?)?.toInt() ?? 0,
      cluesCreated: (json['clues_created'] as num?)?.toInt() ?? 0,
      cluesCompleted: (json['clues_completed'] as num?)?.toInt() ?? 0,
      isCreator: json['is_creator'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'total_points': instance.totalPoints,
      'badge_count': instance.badgeCount,
      'clues_created': instance.cluesCreated,
      'clues_completed': instance.cluesCompleted,
      'is_creator': instance.isCreator,
      'role': instance.role,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
