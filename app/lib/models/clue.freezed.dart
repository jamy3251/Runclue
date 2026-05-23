// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Clue _$ClueFromJson(Map<String, dynamic> json) {
  return _Clue.fromJson(json);
}

/// @nodoc
mixin _$Clue {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'creator_id')
  String get creatorId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  ClueCategory get category => throw _privateConstructorUsedError;
  ClueStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public')
  bool get isPublic => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_participants')
  int? get maxParticipants => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_participants')
  int get currentParticipants => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_mode')
  ClueGameMode get gameMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_participants')
  int get minParticipants => throw _privateConstructorUsedError;
  @JsonKey(name: 'lobby_window_minutes')
  int get lobbyWindowMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'lobby_started_at')
  DateTime? get lobbyStartedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'coop_state')
  CoopState get coopState => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  DateTime? get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  DateTime? get endTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_limit_minutes')
  int? get timeLimitMinutes => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'radius_meters')
  double? get radiusMeters => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_type')
  String? get rewardType => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_value')
  String? get rewardValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_approval')
  bool get requiresApproval => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_prize_type')
  bool get isPrizeType => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_broadcast_type')
  bool get isBroadcastType => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_age')
  int? get minAge => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'view_count')
  int get viewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'like_count')
  int get likeCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  List<ClueStep>? get steps => throw _privateConstructorUsedError;
  @JsonKey(name: 'creator_profile')
  Profile? get creatorProfile => throw _privateConstructorUsedError;

  /// Serializes this Clue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClueCopyWith<Clue> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClueCopyWith<$Res> {
  factory $ClueCopyWith(Clue value, $Res Function(Clue) then) =
      _$ClueCopyWithImpl<$Res, Clue>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'creator_id') String creatorId,
      String title,
      String? description,
      ClueCategory category,
      ClueStatus status,
      @JsonKey(name: 'is_public') bool isPublic,
      @JsonKey(name: 'max_participants') int? maxParticipants,
      @JsonKey(name: 'current_participants') int currentParticipants,
      @JsonKey(name: 'game_mode') ClueGameMode gameMode,
      @JsonKey(name: 'min_participants') int minParticipants,
      @JsonKey(name: 'lobby_window_minutes') int lobbyWindowMinutes,
      @JsonKey(name: 'lobby_started_at') DateTime? lobbyStartedAt,
      @JsonKey(name: 'coop_state') CoopState coopState,
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
      @JsonKey(name: 'requires_approval') bool requiresApproval,
      @JsonKey(name: 'is_prize_type') bool isPrizeType,
      @JsonKey(name: 'is_broadcast_type') bool isBroadcastType,
      @JsonKey(name: 'min_age') int? minAge,
      List<String> tags,
      @JsonKey(name: 'view_count') int viewCount,
      @JsonKey(name: 'like_count') int likeCount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      List<ClueStep>? steps,
      @JsonKey(name: 'creator_profile') Profile? creatorProfile});

  $ProfileCopyWith<$Res>? get creatorProfile;
}

/// @nodoc
class _$ClueCopyWithImpl<$Res, $Val extends Clue>
    implements $ClueCopyWith<$Res> {
  _$ClueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorId = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = null,
    Object? status = null,
    Object? isPublic = null,
    Object? maxParticipants = freezed,
    Object? currentParticipants = null,
    Object? gameMode = null,
    Object? minParticipants = null,
    Object? lobbyWindowMinutes = null,
    Object? lobbyStartedAt = freezed,
    Object? coopState = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? timeLimitMinutes = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? radiusMeters = freezed,
    Object? address = freezed,
    Object? thumbnailUrl = freezed,
    Object? rewardType = freezed,
    Object? rewardValue = freezed,
    Object? requiresApproval = null,
    Object? isPrizeType = null,
    Object? isBroadcastType = null,
    Object? minAge = freezed,
    Object? tags = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? steps = freezed,
    Object? creatorProfile = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ClueCategory,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ClueStatus,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
      currentParticipants: null == currentParticipants
          ? _value.currentParticipants
          : currentParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      gameMode: null == gameMode
          ? _value.gameMode
          : gameMode // ignore: cast_nullable_to_non_nullable
              as ClueGameMode,
      minParticipants: null == minParticipants
          ? _value.minParticipants
          : minParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      lobbyWindowMinutes: null == lobbyWindowMinutes
          ? _value.lobbyWindowMinutes
          : lobbyWindowMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      lobbyStartedAt: freezed == lobbyStartedAt
          ? _value.lobbyStartedAt
          : lobbyStartedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      coopState: null == coopState
          ? _value.coopState
          : coopState // ignore: cast_nullable_to_non_nullable
              as CoopState,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeLimitMinutes: freezed == timeLimitMinutes
          ? _value.timeLimitMinutes
          : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      radiusMeters: freezed == radiusMeters
          ? _value.radiusMeters
          : radiusMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      rewardType: freezed == rewardType
          ? _value.rewardType
          : rewardType // ignore: cast_nullable_to_non_nullable
              as String?,
      rewardValue: freezed == rewardValue
          ? _value.rewardValue
          : rewardValue // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresApproval: null == requiresApproval
          ? _value.requiresApproval
          : requiresApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrizeType: null == isPrizeType
          ? _value.isPrizeType
          : isPrizeType // ignore: cast_nullable_to_non_nullable
              as bool,
      isBroadcastType: null == isBroadcastType
          ? _value.isBroadcastType
          : isBroadcastType // ignore: cast_nullable_to_non_nullable
              as bool,
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      steps: freezed == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<ClueStep>?,
      creatorProfile: freezed == creatorProfile
          ? _value.creatorProfile
          : creatorProfile // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ) as $Val);
  }

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<$Res>? get creatorProfile {
    if (_value.creatorProfile == null) {
      return null;
    }

    return $ProfileCopyWith<$Res>(_value.creatorProfile!, (value) {
      return _then(_value.copyWith(creatorProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClueImplCopyWith<$Res> implements $ClueCopyWith<$Res> {
  factory _$$ClueImplCopyWith(
          _$ClueImpl value, $Res Function(_$ClueImpl) then) =
      __$$ClueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'creator_id') String creatorId,
      String title,
      String? description,
      ClueCategory category,
      ClueStatus status,
      @JsonKey(name: 'is_public') bool isPublic,
      @JsonKey(name: 'max_participants') int? maxParticipants,
      @JsonKey(name: 'current_participants') int currentParticipants,
      @JsonKey(name: 'game_mode') ClueGameMode gameMode,
      @JsonKey(name: 'min_participants') int minParticipants,
      @JsonKey(name: 'lobby_window_minutes') int lobbyWindowMinutes,
      @JsonKey(name: 'lobby_started_at') DateTime? lobbyStartedAt,
      @JsonKey(name: 'coop_state') CoopState coopState,
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
      @JsonKey(name: 'requires_approval') bool requiresApproval,
      @JsonKey(name: 'is_prize_type') bool isPrizeType,
      @JsonKey(name: 'is_broadcast_type') bool isBroadcastType,
      @JsonKey(name: 'min_age') int? minAge,
      List<String> tags,
      @JsonKey(name: 'view_count') int viewCount,
      @JsonKey(name: 'like_count') int likeCount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      List<ClueStep>? steps,
      @JsonKey(name: 'creator_profile') Profile? creatorProfile});

  @override
  $ProfileCopyWith<$Res>? get creatorProfile;
}

/// @nodoc
class __$$ClueImplCopyWithImpl<$Res>
    extends _$ClueCopyWithImpl<$Res, _$ClueImpl>
    implements _$$ClueImplCopyWith<$Res> {
  __$$ClueImplCopyWithImpl(_$ClueImpl _value, $Res Function(_$ClueImpl) _then)
      : super(_value, _then);

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creatorId = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = null,
    Object? status = null,
    Object? isPublic = null,
    Object? maxParticipants = freezed,
    Object? currentParticipants = null,
    Object? gameMode = null,
    Object? minParticipants = null,
    Object? lobbyWindowMinutes = null,
    Object? lobbyStartedAt = freezed,
    Object? coopState = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? timeLimitMinutes = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? radiusMeters = freezed,
    Object? address = freezed,
    Object? thumbnailUrl = freezed,
    Object? rewardType = freezed,
    Object? rewardValue = freezed,
    Object? requiresApproval = null,
    Object? isPrizeType = null,
    Object? isBroadcastType = null,
    Object? minAge = freezed,
    Object? tags = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? steps = freezed,
    Object? creatorProfile = freezed,
  }) {
    return _then(_$ClueImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ClueCategory,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ClueStatus,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
      currentParticipants: null == currentParticipants
          ? _value.currentParticipants
          : currentParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      gameMode: null == gameMode
          ? _value.gameMode
          : gameMode // ignore: cast_nullable_to_non_nullable
              as ClueGameMode,
      minParticipants: null == minParticipants
          ? _value.minParticipants
          : minParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      lobbyWindowMinutes: null == lobbyWindowMinutes
          ? _value.lobbyWindowMinutes
          : lobbyWindowMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      lobbyStartedAt: freezed == lobbyStartedAt
          ? _value.lobbyStartedAt
          : lobbyStartedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      coopState: null == coopState
          ? _value.coopState
          : coopState // ignore: cast_nullable_to_non_nullable
              as CoopState,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeLimitMinutes: freezed == timeLimitMinutes
          ? _value.timeLimitMinutes
          : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      radiusMeters: freezed == radiusMeters
          ? _value.radiusMeters
          : radiusMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      rewardType: freezed == rewardType
          ? _value.rewardType
          : rewardType // ignore: cast_nullable_to_non_nullable
              as String?,
      rewardValue: freezed == rewardValue
          ? _value.rewardValue
          : rewardValue // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresApproval: null == requiresApproval
          ? _value.requiresApproval
          : requiresApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrizeType: null == isPrizeType
          ? _value.isPrizeType
          : isPrizeType // ignore: cast_nullable_to_non_nullable
              as bool,
      isBroadcastType: null == isBroadcastType
          ? _value.isBroadcastType
          : isBroadcastType // ignore: cast_nullable_to_non_nullable
              as bool,
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      steps: freezed == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<ClueStep>?,
      creatorProfile: freezed == creatorProfile
          ? _value.creatorProfile
          : creatorProfile // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClueImpl implements _Clue {
  const _$ClueImpl(
      {required this.id,
      @JsonKey(name: 'creator_id') required this.creatorId,
      required this.title,
      this.description,
      required this.category,
      this.status = ClueStatus.draft,
      @JsonKey(name: 'is_public') this.isPublic = true,
      @JsonKey(name: 'max_participants') this.maxParticipants,
      @JsonKey(name: 'current_participants') this.currentParticipants = 0,
      @JsonKey(name: 'game_mode') this.gameMode = ClueGameMode.solo,
      @JsonKey(name: 'min_participants') this.minParticipants = 1,
      @JsonKey(name: 'lobby_window_minutes') this.lobbyWindowMinutes = 30,
      @JsonKey(name: 'lobby_started_at') this.lobbyStartedAt,
      @JsonKey(name: 'coop_state') this.coopState = CoopState.idle,
      @JsonKey(name: 'start_time') this.startTime,
      @JsonKey(name: 'end_time') this.endTime,
      @JsonKey(name: 'time_limit_minutes') this.timeLimitMinutes,
      this.latitude,
      this.longitude,
      @JsonKey(name: 'radius_meters') this.radiusMeters,
      this.address,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      @JsonKey(name: 'reward_type') this.rewardType,
      @JsonKey(name: 'reward_value') this.rewardValue,
      @JsonKey(name: 'requires_approval') this.requiresApproval = false,
      @JsonKey(name: 'is_prize_type') this.isPrizeType = false,
      @JsonKey(name: 'is_broadcast_type') this.isBroadcastType = false,
      @JsonKey(name: 'min_age') this.minAge,
      final List<String> tags = const [],
      @JsonKey(name: 'view_count') this.viewCount = 0,
      @JsonKey(name: 'like_count') this.likeCount = 0,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      final List<ClueStep>? steps,
      @JsonKey(name: 'creator_profile') this.creatorProfile})
      : _tags = tags,
        _steps = steps;

  factory _$ClueImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClueImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final ClueCategory category;
  @override
  @JsonKey()
  final ClueStatus status;
  @override
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @override
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  @override
  @JsonKey(name: 'current_participants')
  final int currentParticipants;
  @override
  @JsonKey(name: 'game_mode')
  final ClueGameMode gameMode;
  @override
  @JsonKey(name: 'min_participants')
  final int minParticipants;
  @override
  @JsonKey(name: 'lobby_window_minutes')
  final int lobbyWindowMinutes;
  @override
  @JsonKey(name: 'lobby_started_at')
  final DateTime? lobbyStartedAt;
  @override
  @JsonKey(name: 'coop_state')
  final CoopState coopState;
  @override
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @override
  @JsonKey(name: 'time_limit_minutes')
  final int? timeLimitMinutes;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'radius_meters')
  final double? radiusMeters;
  @override
  final String? address;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @override
  @JsonKey(name: 'reward_type')
  final String? rewardType;
  @override
  @JsonKey(name: 'reward_value')
  final String? rewardValue;
  @override
  @JsonKey(name: 'requires_approval')
  final bool requiresApproval;
  @override
  @JsonKey(name: 'is_prize_type')
  final bool isPrizeType;
  @override
  @JsonKey(name: 'is_broadcast_type')
  final bool isBroadcastType;
  @override
  @JsonKey(name: 'min_age')
  final int? minAge;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'view_count')
  final int viewCount;
  @override
  @JsonKey(name: 'like_count')
  final int likeCount;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<ClueStep>? _steps;
  @override
  List<ClueStep>? get steps {
    final value = _steps;
    if (value == null) return null;
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'creator_profile')
  final Profile? creatorProfile;

  @override
  String toString() {
    return 'Clue(id: $id, creatorId: $creatorId, title: $title, description: $description, category: $category, status: $status, isPublic: $isPublic, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, gameMode: $gameMode, minParticipants: $minParticipants, lobbyWindowMinutes: $lobbyWindowMinutes, lobbyStartedAt: $lobbyStartedAt, coopState: $coopState, startTime: $startTime, endTime: $endTime, timeLimitMinutes: $timeLimitMinutes, latitude: $latitude, longitude: $longitude, radiusMeters: $radiusMeters, address: $address, thumbnailUrl: $thumbnailUrl, rewardType: $rewardType, rewardValue: $rewardValue, requiresApproval: $requiresApproval, isPrizeType: $isPrizeType, isBroadcastType: $isBroadcastType, minAge: $minAge, tags: $tags, viewCount: $viewCount, likeCount: $likeCount, createdAt: $createdAt, updatedAt: $updatedAt, steps: $steps, creatorProfile: $creatorProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.currentParticipants, currentParticipants) ||
                other.currentParticipants == currentParticipants) &&
            (identical(other.gameMode, gameMode) ||
                other.gameMode == gameMode) &&
            (identical(other.minParticipants, minParticipants) ||
                other.minParticipants == minParticipants) &&
            (identical(other.lobbyWindowMinutes, lobbyWindowMinutes) ||
                other.lobbyWindowMinutes == lobbyWindowMinutes) &&
            (identical(other.lobbyStartedAt, lobbyStartedAt) ||
                other.lobbyStartedAt == lobbyStartedAt) &&
            (identical(other.coopState, coopState) ||
                other.coopState == coopState) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.timeLimitMinutes, timeLimitMinutes) ||
                other.timeLimitMinutes == timeLimitMinutes) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radiusMeters, radiusMeters) ||
                other.radiusMeters == radiusMeters) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.rewardType, rewardType) ||
                other.rewardType == rewardType) &&
            (identical(other.rewardValue, rewardValue) ||
                other.rewardValue == rewardValue) &&
            (identical(other.requiresApproval, requiresApproval) ||
                other.requiresApproval == requiresApproval) &&
            (identical(other.isPrizeType, isPrizeType) ||
                other.isPrizeType == isPrizeType) &&
            (identical(other.isBroadcastType, isBroadcastType) ||
                other.isBroadcastType == isBroadcastType) &&
            (identical(other.minAge, minAge) || other.minAge == minAge) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.creatorProfile, creatorProfile) ||
                other.creatorProfile == creatorProfile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        creatorId,
        title,
        description,
        category,
        status,
        isPublic,
        maxParticipants,
        currentParticipants,
        gameMode,
        minParticipants,
        lobbyWindowMinutes,
        lobbyStartedAt,
        coopState,
        startTime,
        endTime,
        timeLimitMinutes,
        latitude,
        longitude,
        radiusMeters,
        address,
        thumbnailUrl,
        rewardType,
        rewardValue,
        requiresApproval,
        isPrizeType,
        isBroadcastType,
        minAge,
        const DeepCollectionEquality().hash(_tags),
        viewCount,
        likeCount,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(_steps),
        creatorProfile
      ]);

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClueImplCopyWith<_$ClueImpl> get copyWith =>
      __$$ClueImplCopyWithImpl<_$ClueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClueImplToJson(
      this,
    );
  }
}

abstract class _Clue implements Clue {
  const factory _Clue(
          {required final String id,
          @JsonKey(name: 'creator_id') required final String creatorId,
          required final String title,
          final String? description,
          required final ClueCategory category,
          final ClueStatus status,
          @JsonKey(name: 'is_public') final bool isPublic,
          @JsonKey(name: 'max_participants') final int? maxParticipants,
          @JsonKey(name: 'current_participants') final int currentParticipants,
          @JsonKey(name: 'game_mode') final ClueGameMode gameMode,
          @JsonKey(name: 'min_participants') final int minParticipants,
          @JsonKey(name: 'lobby_window_minutes') final int lobbyWindowMinutes,
          @JsonKey(name: 'lobby_started_at') final DateTime? lobbyStartedAt,
          @JsonKey(name: 'coop_state') final CoopState coopState,
          @JsonKey(name: 'start_time') final DateTime? startTime,
          @JsonKey(name: 'end_time') final DateTime? endTime,
          @JsonKey(name: 'time_limit_minutes') final int? timeLimitMinutes,
          final double? latitude,
          final double? longitude,
          @JsonKey(name: 'radius_meters') final double? radiusMeters,
          final String? address,
          @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
          @JsonKey(name: 'reward_type') final String? rewardType,
          @JsonKey(name: 'reward_value') final String? rewardValue,
          @JsonKey(name: 'requires_approval') final bool requiresApproval,
          @JsonKey(name: 'is_prize_type') final bool isPrizeType,
          @JsonKey(name: 'is_broadcast_type') final bool isBroadcastType,
          @JsonKey(name: 'min_age') final int? minAge,
          final List<String> tags,
          @JsonKey(name: 'view_count') final int viewCount,
          @JsonKey(name: 'like_count') final int likeCount,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt,
          final List<ClueStep>? steps,
          @JsonKey(name: 'creator_profile') final Profile? creatorProfile}) =
      _$ClueImpl;

  factory _Clue.fromJson(Map<String, dynamic> json) = _$ClueImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'creator_id')
  String get creatorId;
  @override
  String get title;
  @override
  String? get description;
  @override
  ClueCategory get category;
  @override
  ClueStatus get status;
  @override
  @JsonKey(name: 'is_public')
  bool get isPublic;
  @override
  @JsonKey(name: 'max_participants')
  int? get maxParticipants;
  @override
  @JsonKey(name: 'current_participants')
  int get currentParticipants;
  @override
  @JsonKey(name: 'game_mode')
  ClueGameMode get gameMode;
  @override
  @JsonKey(name: 'min_participants')
  int get minParticipants;
  @override
  @JsonKey(name: 'lobby_window_minutes')
  int get lobbyWindowMinutes;
  @override
  @JsonKey(name: 'lobby_started_at')
  DateTime? get lobbyStartedAt;
  @override
  @JsonKey(name: 'coop_state')
  CoopState get coopState;
  @override
  @JsonKey(name: 'start_time')
  DateTime? get startTime;
  @override
  @JsonKey(name: 'end_time')
  DateTime? get endTime;
  @override
  @JsonKey(name: 'time_limit_minutes')
  int? get timeLimitMinutes;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'radius_meters')
  double? get radiusMeters;
  @override
  String? get address;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  @JsonKey(name: 'reward_type')
  String? get rewardType;
  @override
  @JsonKey(name: 'reward_value')
  String? get rewardValue;
  @override
  @JsonKey(name: 'requires_approval')
  bool get requiresApproval;
  @override
  @JsonKey(name: 'is_prize_type')
  bool get isPrizeType;
  @override
  @JsonKey(name: 'is_broadcast_type')
  bool get isBroadcastType;
  @override
  @JsonKey(name: 'min_age')
  int? get minAge;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'view_count')
  int get viewCount;
  @override
  @JsonKey(name: 'like_count')
  int get likeCount;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  List<ClueStep>? get steps;
  @override
  @JsonKey(name: 'creator_profile')
  Profile? get creatorProfile;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClueImplCopyWith<_$ClueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
