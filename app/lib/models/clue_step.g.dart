// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clue_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChecklistItemImpl _$$ChecklistItemImplFromJson(Map<String, dynamic> json) =>
    _$ChecklistItemImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      required: json['required'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChecklistItemImplToJson(_$ChecklistItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'required': instance.required,
    };

_$ClueStepImpl _$$ClueStepImplFromJson(Map<String, dynamic> json) =>
    _$ClueStepImpl(
      id: json['id'] as String,
      clueId: json['clue_id'] as String,
      orderIndex: (json['order_index'] as num).toInt(),
      type: $enumDecode(_$StepTypeEnumMap, json['type']),
      title: json['title'] as String?,
      description: json['description'] as String?,
      instruction: json['instruction'] as String?,
      targetLatitude: (json['target_latitude'] as num?)?.toDouble(),
      targetLongitude: (json['target_longitude'] as num?)?.toDouble(),
      locationRadiusMeters:
          (json['location_radius_meters'] as num?)?.toDouble(),
      referenceImageUrl: json['reference_image_url'] as String?,
      questQuestion: json['quest_question'] as String?,
      questAnswer: json['quest_answer'] as String?,
      questAnswerType: json['quest_answer_type'] as String?,
      quizCorrectAnswer: json['quiz_correct_answer'] as bool?,
      quizExplanation: json['quiz_explanation'] as String?,
      quizTimeLimitSeconds: (json['quiz_time_limit_seconds'] as num?)?.toInt(),
      checklistItems: (json['checklist_items'] as List<dynamic>?)
          ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      validationType: $enumDecodeNullable(
              _$ValidationTypeEnumMap, json['validation_type']) ??
          ValidationType.auto,
      points: (json['points'] as num?)?.toInt() ?? 0,
      isRequired: json['is_required'] as bool? ?? true,
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt(),
      hint: json['hint'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ClueStepImplToJson(_$ClueStepImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clue_id': instance.clueId,
      'order_index': instance.orderIndex,
      'type': _$StepTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'instruction': instance.instruction,
      'target_latitude': instance.targetLatitude,
      'target_longitude': instance.targetLongitude,
      'location_radius_meters': instance.locationRadiusMeters,
      'reference_image_url': instance.referenceImageUrl,
      'quest_question': instance.questQuestion,
      'quest_answer': instance.questAnswer,
      'quest_answer_type': instance.questAnswerType,
      'quiz_correct_answer': instance.quizCorrectAnswer,
      'quiz_explanation': instance.quizExplanation,
      'quiz_time_limit_seconds': instance.quizTimeLimitSeconds,
      'checklist_items': instance.checklistItems,
      'validation_type': _$ValidationTypeEnumMap[instance.validationType]!,
      'points': instance.points,
      'is_required': instance.isRequired,
      'time_limit_seconds': instance.timeLimitSeconds,
      'hint': instance.hint,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$StepTypeEnumMap = {
  StepType.checkpoint: 'checkpoint',
  StepType.snapshot: 'snapshot',
  StepType.quest: 'quest',
  StepType.oxQuiz: 'ox_quiz',
  StepType.list: 'list',
  StepType.board: 'board',
  StepType.panorama: 'panorama',
  StepType.facial: 'facial',
};

const _$ValidationTypeEnumMap = {
  ValidationType.auto: 'auto',
  ValidationType.delayed: 'delayed',
  ValidationType.manual: 'manual',
};
