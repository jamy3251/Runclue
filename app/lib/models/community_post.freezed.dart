// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CommunityPost _$CommunityPostFromJson(Map<String, dynamic> json) {
  return _CommunityPost.fromJson(json);
}

/// @nodoc
mixin _$CommunityPost {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String get authorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'clue_id')
  String? get clueId => throw _privateConstructorUsedError;
  PostType get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_urls')
  List<String>? get mediaUrls => throw _privateConstructorUsedError;
  @JsonKey(name: 'like_count')
  int get likeCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_count')
  int get commentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_pinned')
  bool get isPinned => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  Profile? get author => throw _privateConstructorUsedError;

  /// Serializes this CommunityPost to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityPostCopyWith<CommunityPost> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityPostCopyWith<$Res> {
  factory $CommunityPostCopyWith(
          CommunityPost value, $Res Function(CommunityPost) then) =
      _$CommunityPostCopyWithImpl<$Res, CommunityPost>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(name: 'clue_id') String? clueId,
      PostType type,
      String? title,
      String content,
      @JsonKey(name: 'media_urls') List<String>? mediaUrls,
      @JsonKey(name: 'like_count') int likeCount,
      @JsonKey(name: 'comment_count') int commentCount,
      @JsonKey(name: 'is_pinned') bool isPinned,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      Profile? author});

  $ProfileCopyWith<$Res>? get author;
}

/// @nodoc
class _$CommunityPostCopyWithImpl<$Res, $Val extends CommunityPost>
    implements $CommunityPostCopyWith<$Res> {
  _$CommunityPostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? clueId = freezed,
    Object? type = null,
    Object? title = freezed,
    Object? content = null,
    Object? mediaUrls = freezed,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? isPinned = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? author = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: freezed == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PostType,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrls: freezed == mediaUrls
          ? _value.mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ) as $Val);
  }

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<$Res>? get author {
    if (_value.author == null) {
      return null;
    }

    return $ProfileCopyWith<$Res>(_value.author!, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommunityPostImplCopyWith<$Res>
    implements $CommunityPostCopyWith<$Res> {
  factory _$$CommunityPostImplCopyWith(
          _$CommunityPostImpl value, $Res Function(_$CommunityPostImpl) then) =
      __$$CommunityPostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(name: 'clue_id') String? clueId,
      PostType type,
      String? title,
      String content,
      @JsonKey(name: 'media_urls') List<String>? mediaUrls,
      @JsonKey(name: 'like_count') int likeCount,
      @JsonKey(name: 'comment_count') int commentCount,
      @JsonKey(name: 'is_pinned') bool isPinned,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      Profile? author});

  @override
  $ProfileCopyWith<$Res>? get author;
}

/// @nodoc
class __$$CommunityPostImplCopyWithImpl<$Res>
    extends _$CommunityPostCopyWithImpl<$Res, _$CommunityPostImpl>
    implements _$$CommunityPostImplCopyWith<$Res> {
  __$$CommunityPostImplCopyWithImpl(
      _$CommunityPostImpl _value, $Res Function(_$CommunityPostImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? clueId = freezed,
    Object? type = null,
    Object? title = freezed,
    Object? content = null,
    Object? mediaUrls = freezed,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? isPinned = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? author = freezed,
  }) {
    return _then(_$CommunityPostImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: freezed == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PostType,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrls: freezed == mediaUrls
          ? _value._mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommunityPostImpl implements _CommunityPost {
  const _$CommunityPostImpl(
      {required this.id,
      @JsonKey(name: 'author_id') required this.authorId,
      @JsonKey(name: 'clue_id') this.clueId,
      required this.type,
      this.title,
      required this.content,
      @JsonKey(name: 'media_urls') final List<String>? mediaUrls,
      @JsonKey(name: 'like_count') this.likeCount = 0,
      @JsonKey(name: 'comment_count') this.commentCount = 0,
      @JsonKey(name: 'is_pinned') this.isPinned = false,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      this.author})
      : _mediaUrls = mediaUrls;

  factory _$CommunityPostImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunityPostImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  @JsonKey(name: 'clue_id')
  final String? clueId;
  @override
  final PostType type;
  @override
  final String? title;
  @override
  final String content;
  final List<String>? _mediaUrls;
  @override
  @JsonKey(name: 'media_urls')
  List<String>? get mediaUrls {
    final value = _mediaUrls;
    if (value == null) return null;
    if (_mediaUrls is EqualUnmodifiableListView) return _mediaUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'like_count')
  final int likeCount;
  @override
  @JsonKey(name: 'comment_count')
  final int commentCount;
  @override
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  final Profile? author;

  @override
  String toString() {
    return 'CommunityPost(id: $id, authorId: $authorId, clueId: $clueId, type: $type, title: $title, content: $content, mediaUrls: $mediaUrls, likeCount: $likeCount, commentCount: $commentCount, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunityPostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.clueId, clueId) || other.clueId == clueId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._mediaUrls, _mediaUrls) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.author, author) || other.author == author));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      authorId,
      clueId,
      type,
      title,
      content,
      const DeepCollectionEquality().hash(_mediaUrls),
      likeCount,
      commentCount,
      isPinned,
      createdAt,
      updatedAt,
      author);

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunityPostImplCopyWith<_$CommunityPostImpl> get copyWith =>
      __$$CommunityPostImplCopyWithImpl<_$CommunityPostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityPostImplToJson(
      this,
    );
  }
}

abstract class _CommunityPost implements CommunityPost {
  const factory _CommunityPost(
      {required final String id,
      @JsonKey(name: 'author_id') required final String authorId,
      @JsonKey(name: 'clue_id') final String? clueId,
      required final PostType type,
      final String? title,
      required final String content,
      @JsonKey(name: 'media_urls') final List<String>? mediaUrls,
      @JsonKey(name: 'like_count') final int likeCount,
      @JsonKey(name: 'comment_count') final int commentCount,
      @JsonKey(name: 'is_pinned') final bool isPinned,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      final Profile? author}) = _$CommunityPostImpl;

  factory _CommunityPost.fromJson(Map<String, dynamic> json) =
      _$CommunityPostImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'author_id')
  String get authorId;
  @override
  @JsonKey(name: 'clue_id')
  String? get clueId;
  @override
  PostType get type;
  @override
  String? get title;
  @override
  String get content;
  @override
  @JsonKey(name: 'media_urls')
  List<String>? get mediaUrls;
  @override
  @JsonKey(name: 'like_count')
  int get likeCount;
  @override
  @JsonKey(name: 'comment_count')
  int get commentCount;
  @override
  @JsonKey(name: 'is_pinned')
  bool get isPinned;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  Profile? get author;

  /// Create a copy of CommunityPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunityPostImplCopyWith<_$CommunityPostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
