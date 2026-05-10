// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunityPostImpl _$$CommunityPostImplFromJson(Map<String, dynamic> json) =>
    _$CommunityPostImpl(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      clueId: json['clue_id'] as String?,
      type: $enumDecode(_$PostTypeEnumMap, json['type']),
      title: json['title'] as String?,
      content: json['content'] as String,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      author: json['author'] == null
          ? null
          : Profile.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CommunityPostImplToJson(_$CommunityPostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'clue_id': instance.clueId,
      'type': _$PostTypeEnumMap[instance.type]!,
      'title': instance.title,
      'content': instance.content,
      'media_urls': instance.mediaUrls,
      'like_count': instance.likeCount,
      'comment_count': instance.commentCount,
      'is_pinned': instance.isPinned,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'author': instance.author,
    };

const _$PostTypeEnumMap = {
  PostType.review: 'review',
  PostType.tip: 'tip',
  PostType.photo: 'photo',
  PostType.question: 'question',
  PostType.general: 'general',
};
