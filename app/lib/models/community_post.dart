import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'community_post.freezed.dart';
part 'community_post.g.dart';

@JsonEnum(valueField: 'value')
enum PostType {
  @JsonValue('review')
  review('review'),
  @JsonValue('tip')
  tip('tip'),
  @JsonValue('photo')
  photo('photo'),
  @JsonValue('question')
  question('question'),
  @JsonValue('general')
  general('general');

  const PostType(this.value);
  final String value;
}

@freezed
class CommunityPost with _$CommunityPost {
  const factory CommunityPost({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'clue_id') String? clueId,
    required PostType type,
    String? title,
    required String content,
    @JsonKey(name: 'media_urls') List<String>? mediaUrls,
    @Default(0) @JsonKey(name: 'like_count') int likeCount,
    @Default(0) @JsonKey(name: 'comment_count') int commentCount,
    @Default(false) @JsonKey(name: 'is_pinned') bool isPinned,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Profile? author,
  }) = _CommunityPost;

  factory CommunityPost.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostFromJson(json);
}
