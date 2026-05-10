import 'package:freezed_annotation/freezed_annotation.dart';

import 'clue.dart';
import 'profile.dart';

part 'participation.freezed.dart';
part 'participation.g.dart';

@JsonEnum(valueField: 'value')
enum ParticipationStatus {
  @JsonValue('joined')
  joined('joined'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('abandoned')
  abandoned('abandoned'),
  @JsonValue('disqualified')
  disqualified('disqualified');

  const ParticipationStatus(this.value);
  final String value;
}

@freezed
class Participation with _$Participation {
  const factory Participation({
    required String id,
    @JsonKey(name: 'clue_id') required String clueId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'clan_id') String? clanId,
    @Default(ParticipationStatus.joined) ParticipationStatus status,
    @Default(0) @JsonKey(name: 'current_step_index') int currentStepIndex,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @Default(0) @JsonKey(name: 'total_points_earned') int totalPointsEarned,
    int? rank,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    Clue? clue,
    Profile? user,
  }) = _Participation;

  factory Participation.fromJson(Map<String, dynamic> json) =>
      _$ParticipationFromJson(json);
}
