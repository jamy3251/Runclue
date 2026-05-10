// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClanImpl _$$ClanImplFromJson(Map<String, dynamic> json) => _$ClanImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      leaderId: json['leader_id'] as String,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 50,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ClanImplToJson(_$ClanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'avatar_url': instance.avatarUrl,
      'leader_id': instance.leaderId,
      'member_count': instance.memberCount,
      'total_points': instance.totalPoints,
      'is_public': instance.isPublic,
      'max_members': instance.maxMembers,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
