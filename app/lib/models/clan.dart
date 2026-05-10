import 'package:freezed_annotation/freezed_annotation.dart';

part 'clan.freezed.dart';
part 'clan.g.dart';

@freezed
class Clan with _$Clan {
  const factory Clan({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'leader_id') required String leaderId,
    @Default(1) @JsonKey(name: 'member_count') int memberCount,
    @Default(0) @JsonKey(name: 'total_points') int totalPoints,
    @Default(true) @JsonKey(name: 'is_public') bool isPublic,
    @Default(50) @JsonKey(name: 'max_members') int maxMembers,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Clan;

  factory Clan.fromJson(Map<String, dynamic> json) => _$ClanFromJson(json);
}
