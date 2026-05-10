import 'package:freezed_annotation/freezed_annotation.dart';

part 'clue_step.freezed.dart';
part 'clue_step.g.dart';

@JsonEnum(valueField: 'value')
enum StepType {
  @JsonValue('checkpoint')
  checkpoint('checkpoint'),
  @JsonValue('snapshot')
  snapshot('snapshot'),
  @JsonValue('quest')
  quest('quest'),
  @JsonValue('ox_quiz')
  oxQuiz('ox_quiz'),
  @JsonValue('list')
  list('list'),
  @JsonValue('board')
  board('board'),
  @JsonValue('panorama')
  panorama('panorama'),
  @JsonValue('facial')
  facial('facial');

  const StepType(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum ValidationType {
  @JsonValue('auto')
  auto('auto'),
  @JsonValue('delayed')
  delayed('delayed'),
  @JsonValue('manual')
  manual('manual');

  const ValidationType(this.value);
  final String value;
}

@freezed
class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String text,
    @Default(false) bool required,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

@freezed
class ClueStep with _$ClueStep {
  const factory ClueStep({
    required String id,
    @JsonKey(name: 'clue_id') required String clueId,
    @JsonKey(name: 'order_index') required int orderIndex,
    required StepType type,
    String? title,
    String? description,
    String? instruction,
    @JsonKey(name: 'target_latitude') double? targetLatitude,
    @JsonKey(name: 'target_longitude') double? targetLongitude,
    @JsonKey(name: 'location_radius_meters') double? locationRadiusMeters,
    @JsonKey(name: 'reference_image_url') String? referenceImageUrl,
    @JsonKey(name: 'quest_question') String? questQuestion,
    @JsonKey(name: 'quest_answer') String? questAnswer,
    @JsonKey(name: 'quest_answer_type') String? questAnswerType,
    @JsonKey(name: 'quiz_correct_answer') bool? quizCorrectAnswer,
    @JsonKey(name: 'quiz_explanation') String? quizExplanation,
    @JsonKey(name: 'quiz_time_limit_seconds') int? quizTimeLimitSeconds,
    @JsonKey(name: 'checklist_items') List<ChecklistItem>? checklistItems,
    @Default(ValidationType.auto)
    @JsonKey(name: 'validation_type')
    ValidationType validationType,
    @Default(0) int points,
    @Default(true) @JsonKey(name: 'is_required') bool isRequired,
    @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
    String? hint,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ClueStep;

  factory ClueStep.fromJson(Map<String, dynamic> json) =>
      _$ClueStepFromJson(json);
}
