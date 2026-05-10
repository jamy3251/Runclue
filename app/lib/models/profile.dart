import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? bio,
    @Default(0) @JsonKey(name: 'total_points') int totalPoints,
    @Default(0) @JsonKey(name: 'badge_count') int badgeCount,
    @Default(0) @JsonKey(name: 'clues_created') int cluesCreated,
    @Default(0) @JsonKey(name: 'clues_completed') int cluesCompleted,
    @Default(false) @JsonKey(name: 'is_creator') bool isCreator,
    @Default('user') String role,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
