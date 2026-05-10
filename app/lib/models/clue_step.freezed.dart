// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clue_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) {
  return _ChecklistItem.fromJson(json);
}

/// @nodoc
mixin _$ChecklistItem {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  bool get required => throw _privateConstructorUsedError;

  /// Serializes this ChecklistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChecklistItemCopyWith<ChecklistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChecklistItemCopyWith<$Res> {
  factory $ChecklistItemCopyWith(
          ChecklistItem value, $Res Function(ChecklistItem) then) =
      _$ChecklistItemCopyWithImpl<$Res, ChecklistItem>;
  @useResult
  $Res call({String id, String text, bool required});
}

/// @nodoc
class _$ChecklistItemCopyWithImpl<$Res, $Val extends ChecklistItem>
    implements $ChecklistItemCopyWith<$Res> {
  _$ChecklistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? required = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      required: null == required
          ? _value.required
          : required // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChecklistItemImplCopyWith<$Res>
    implements $ChecklistItemCopyWith<$Res> {
  factory _$$ChecklistItemImplCopyWith(
          _$ChecklistItemImpl value, $Res Function(_$ChecklistItemImpl) then) =
      __$$ChecklistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String text, bool required});
}

/// @nodoc
class __$$ChecklistItemImplCopyWithImpl<$Res>
    extends _$ChecklistItemCopyWithImpl<$Res, _$ChecklistItemImpl>
    implements _$$ChecklistItemImplCopyWith<$Res> {
  __$$ChecklistItemImplCopyWithImpl(
      _$ChecklistItemImpl _value, $Res Function(_$ChecklistItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? required = null,
  }) {
    return _then(_$ChecklistItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      required: null == required
          ? _value.required
          : required // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChecklistItemImpl implements _ChecklistItem {
  const _$ChecklistItemImpl(
      {required this.id, required this.text, this.required = false});

  factory _$ChecklistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecklistItemImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  @JsonKey()
  final bool required;

  @override
  String toString() {
    return 'ChecklistItem(id: $id, text: $text, required: $required)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecklistItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.required, required) ||
                other.required == required));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, text, required);

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecklistItemImplCopyWith<_$ChecklistItemImpl> get copyWith =>
      __$$ChecklistItemImplCopyWithImpl<_$ChecklistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecklistItemImplToJson(
      this,
    );
  }
}

abstract class _ChecklistItem implements ChecklistItem {
  const factory _ChecklistItem(
      {required final String id,
      required final String text,
      final bool required}) = _$ChecklistItemImpl;

  factory _ChecklistItem.fromJson(Map<String, dynamic> json) =
      _$ChecklistItemImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  bool get required;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecklistItemImplCopyWith<_$ChecklistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClueStep _$ClueStepFromJson(Map<String, dynamic> json) {
  return _ClueStep.fromJson(json);
}

/// @nodoc
mixin _$ClueStep {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'clue_id')
  String get clueId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_index')
  int get orderIndex => throw _privateConstructorUsedError;
  StepType get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get instruction => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_latitude')
  double? get targetLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_longitude')
  double? get targetLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_radius_meters')
  double? get locationRadiusMeters => throw _privateConstructorUsedError;
  @JsonKey(name: 'reference_image_url')
  String? get referenceImageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_question')
  String? get questQuestion => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_answer')
  String? get questAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_answer_type')
  String? get questAnswerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_correct_answer')
  bool? get quizCorrectAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_explanation')
  String? get quizExplanation => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_time_limit_seconds')
  int? get quizTimeLimitSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'checklist_items')
  List<ChecklistItem>? get checklistItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'validation_type')
  ValidationType get validationType => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_required')
  bool get isRequired => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_limit_seconds')
  int? get timeLimitSeconds => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ClueStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClueStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClueStepCopyWith<ClueStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClueStepCopyWith<$Res> {
  factory $ClueStepCopyWith(ClueStep value, $Res Function(ClueStep) then) =
      _$ClueStepCopyWithImpl<$Res, ClueStep>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'order_index') int orderIndex,
      StepType type,
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
      @JsonKey(name: 'validation_type') ValidationType validationType,
      int points,
      @JsonKey(name: 'is_required') bool isRequired,
      @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
      String? hint,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ClueStepCopyWithImpl<$Res, $Val extends ClueStep>
    implements $ClueStepCopyWith<$Res> {
  _$ClueStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClueStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clueId = null,
    Object? orderIndex = null,
    Object? type = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? instruction = freezed,
    Object? targetLatitude = freezed,
    Object? targetLongitude = freezed,
    Object? locationRadiusMeters = freezed,
    Object? referenceImageUrl = freezed,
    Object? questQuestion = freezed,
    Object? questAnswer = freezed,
    Object? questAnswerType = freezed,
    Object? quizCorrectAnswer = freezed,
    Object? quizExplanation = freezed,
    Object? quizTimeLimitSeconds = freezed,
    Object? checklistItems = freezed,
    Object? validationType = null,
    Object? points = null,
    Object? isRequired = null,
    Object? timeLimitSeconds = freezed,
    Object? hint = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as StepType,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      instruction: freezed == instruction
          ? _value.instruction
          : instruction // ignore: cast_nullable_to_non_nullable
              as String?,
      targetLatitude: freezed == targetLatitude
          ? _value.targetLatitude
          : targetLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLongitude: freezed == targetLongitude
          ? _value.targetLongitude
          : targetLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationRadiusMeters: freezed == locationRadiusMeters
          ? _value.locationRadiusMeters
          : locationRadiusMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      referenceImageUrl: freezed == referenceImageUrl
          ? _value.referenceImageUrl
          : referenceImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      questQuestion: freezed == questQuestion
          ? _value.questQuestion
          : questQuestion // ignore: cast_nullable_to_non_nullable
              as String?,
      questAnswer: freezed == questAnswer
          ? _value.questAnswer
          : questAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      questAnswerType: freezed == questAnswerType
          ? _value.questAnswerType
          : questAnswerType // ignore: cast_nullable_to_non_nullable
              as String?,
      quizCorrectAnswer: freezed == quizCorrectAnswer
          ? _value.quizCorrectAnswer
          : quizCorrectAnswer // ignore: cast_nullable_to_non_nullable
              as bool?,
      quizExplanation: freezed == quizExplanation
          ? _value.quizExplanation
          : quizExplanation // ignore: cast_nullable_to_non_nullable
              as String?,
      quizTimeLimitSeconds: freezed == quizTimeLimitSeconds
          ? _value.quizTimeLimitSeconds
          : quizTimeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      checklistItems: freezed == checklistItems
          ? _value.checklistItems
          : checklistItems // ignore: cast_nullable_to_non_nullable
              as List<ChecklistItem>?,
      validationType: null == validationType
          ? _value.validationType
          : validationType // ignore: cast_nullable_to_non_nullable
              as ValidationType,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      timeLimitSeconds: freezed == timeLimitSeconds
          ? _value.timeLimitSeconds
          : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClueStepImplCopyWith<$Res>
    implements $ClueStepCopyWith<$Res> {
  factory _$$ClueStepImplCopyWith(
          _$ClueStepImpl value, $Res Function(_$ClueStepImpl) then) =
      __$$ClueStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'clue_id') String clueId,
      @JsonKey(name: 'order_index') int orderIndex,
      StepType type,
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
      @JsonKey(name: 'validation_type') ValidationType validationType,
      int points,
      @JsonKey(name: 'is_required') bool isRequired,
      @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
      String? hint,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$ClueStepImplCopyWithImpl<$Res>
    extends _$ClueStepCopyWithImpl<$Res, _$ClueStepImpl>
    implements _$$ClueStepImplCopyWith<$Res> {
  __$$ClueStepImplCopyWithImpl(
      _$ClueStepImpl _value, $Res Function(_$ClueStepImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClueStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clueId = null,
    Object? orderIndex = null,
    Object? type = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? instruction = freezed,
    Object? targetLatitude = freezed,
    Object? targetLongitude = freezed,
    Object? locationRadiusMeters = freezed,
    Object? referenceImageUrl = freezed,
    Object? questQuestion = freezed,
    Object? questAnswer = freezed,
    Object? questAnswerType = freezed,
    Object? quizCorrectAnswer = freezed,
    Object? quizExplanation = freezed,
    Object? quizTimeLimitSeconds = freezed,
    Object? checklistItems = freezed,
    Object? validationType = null,
    Object? points = null,
    Object? isRequired = null,
    Object? timeLimitSeconds = freezed,
    Object? hint = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ClueStepImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clueId: null == clueId
          ? _value.clueId
          : clueId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as StepType,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      instruction: freezed == instruction
          ? _value.instruction
          : instruction // ignore: cast_nullable_to_non_nullable
              as String?,
      targetLatitude: freezed == targetLatitude
          ? _value.targetLatitude
          : targetLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLongitude: freezed == targetLongitude
          ? _value.targetLongitude
          : targetLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationRadiusMeters: freezed == locationRadiusMeters
          ? _value.locationRadiusMeters
          : locationRadiusMeters // ignore: cast_nullable_to_non_nullable
              as double?,
      referenceImageUrl: freezed == referenceImageUrl
          ? _value.referenceImageUrl
          : referenceImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      questQuestion: freezed == questQuestion
          ? _value.questQuestion
          : questQuestion // ignore: cast_nullable_to_non_nullable
              as String?,
      questAnswer: freezed == questAnswer
          ? _value.questAnswer
          : questAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      questAnswerType: freezed == questAnswerType
          ? _value.questAnswerType
          : questAnswerType // ignore: cast_nullable_to_non_nullable
              as String?,
      quizCorrectAnswer: freezed == quizCorrectAnswer
          ? _value.quizCorrectAnswer
          : quizCorrectAnswer // ignore: cast_nullable_to_non_nullable
              as bool?,
      quizExplanation: freezed == quizExplanation
          ? _value.quizExplanation
          : quizExplanation // ignore: cast_nullable_to_non_nullable
              as String?,
      quizTimeLimitSeconds: freezed == quizTimeLimitSeconds
          ? _value.quizTimeLimitSeconds
          : quizTimeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      checklistItems: freezed == checklistItems
          ? _value._checklistItems
          : checklistItems // ignore: cast_nullable_to_non_nullable
              as List<ChecklistItem>?,
      validationType: null == validationType
          ? _value.validationType
          : validationType // ignore: cast_nullable_to_non_nullable
              as ValidationType,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      timeLimitSeconds: freezed == timeLimitSeconds
          ? _value.timeLimitSeconds
          : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClueStepImpl implements _ClueStep {
  const _$ClueStepImpl(
      {required this.id,
      @JsonKey(name: 'clue_id') required this.clueId,
      @JsonKey(name: 'order_index') required this.orderIndex,
      required this.type,
      this.title,
      this.description,
      this.instruction,
      @JsonKey(name: 'target_latitude') this.targetLatitude,
      @JsonKey(name: 'target_longitude') this.targetLongitude,
      @JsonKey(name: 'location_radius_meters') this.locationRadiusMeters,
      @JsonKey(name: 'reference_image_url') this.referenceImageUrl,
      @JsonKey(name: 'quest_question') this.questQuestion,
      @JsonKey(name: 'quest_answer') this.questAnswer,
      @JsonKey(name: 'quest_answer_type') this.questAnswerType,
      @JsonKey(name: 'quiz_correct_answer') this.quizCorrectAnswer,
      @JsonKey(name: 'quiz_explanation') this.quizExplanation,
      @JsonKey(name: 'quiz_time_limit_seconds') this.quizTimeLimitSeconds,
      @JsonKey(name: 'checklist_items')
      final List<ChecklistItem>? checklistItems,
      @JsonKey(name: 'validation_type')
      this.validationType = ValidationType.auto,
      this.points = 0,
      @JsonKey(name: 'is_required') this.isRequired = true,
      @JsonKey(name: 'time_limit_seconds') this.timeLimitSeconds,
      this.hint,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _checklistItems = checklistItems;

  factory _$ClueStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClueStepImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'clue_id')
  final String clueId;
  @override
  @JsonKey(name: 'order_index')
  final int orderIndex;
  @override
  final StepType type;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? instruction;
  @override
  @JsonKey(name: 'target_latitude')
  final double? targetLatitude;
  @override
  @JsonKey(name: 'target_longitude')
  final double? targetLongitude;
  @override
  @JsonKey(name: 'location_radius_meters')
  final double? locationRadiusMeters;
  @override
  @JsonKey(name: 'reference_image_url')
  final String? referenceImageUrl;
  @override
  @JsonKey(name: 'quest_question')
  final String? questQuestion;
  @override
  @JsonKey(name: 'quest_answer')
  final String? questAnswer;
  @override
  @JsonKey(name: 'quest_answer_type')
  final String? questAnswerType;
  @override
  @JsonKey(name: 'quiz_correct_answer')
  final bool? quizCorrectAnswer;
  @override
  @JsonKey(name: 'quiz_explanation')
  final String? quizExplanation;
  @override
  @JsonKey(name: 'quiz_time_limit_seconds')
  final int? quizTimeLimitSeconds;
  final List<ChecklistItem>? _checklistItems;
  @override
  @JsonKey(name: 'checklist_items')
  List<ChecklistItem>? get checklistItems {
    final value = _checklistItems;
    if (value == null) return null;
    if (_checklistItems is EqualUnmodifiableListView) return _checklistItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'validation_type')
  final ValidationType validationType;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey(name: 'is_required')
  final bool isRequired;
  @override
  @JsonKey(name: 'time_limit_seconds')
  final int? timeLimitSeconds;
  @override
  final String? hint;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ClueStep(id: $id, clueId: $clueId, orderIndex: $orderIndex, type: $type, title: $title, description: $description, instruction: $instruction, targetLatitude: $targetLatitude, targetLongitude: $targetLongitude, locationRadiusMeters: $locationRadiusMeters, referenceImageUrl: $referenceImageUrl, questQuestion: $questQuestion, questAnswer: $questAnswer, questAnswerType: $questAnswerType, quizCorrectAnswer: $quizCorrectAnswer, quizExplanation: $quizExplanation, quizTimeLimitSeconds: $quizTimeLimitSeconds, checklistItems: $checklistItems, validationType: $validationType, points: $points, isRequired: $isRequired, timeLimitSeconds: $timeLimitSeconds, hint: $hint, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClueStepImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clueId, clueId) || other.clueId == clueId) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction) &&
            (identical(other.targetLatitude, targetLatitude) ||
                other.targetLatitude == targetLatitude) &&
            (identical(other.targetLongitude, targetLongitude) ||
                other.targetLongitude == targetLongitude) &&
            (identical(other.locationRadiusMeters, locationRadiusMeters) ||
                other.locationRadiusMeters == locationRadiusMeters) &&
            (identical(other.referenceImageUrl, referenceImageUrl) ||
                other.referenceImageUrl == referenceImageUrl) &&
            (identical(other.questQuestion, questQuestion) ||
                other.questQuestion == questQuestion) &&
            (identical(other.questAnswer, questAnswer) ||
                other.questAnswer == questAnswer) &&
            (identical(other.questAnswerType, questAnswerType) ||
                other.questAnswerType == questAnswerType) &&
            (identical(other.quizCorrectAnswer, quizCorrectAnswer) ||
                other.quizCorrectAnswer == quizCorrectAnswer) &&
            (identical(other.quizExplanation, quizExplanation) ||
                other.quizExplanation == quizExplanation) &&
            (identical(other.quizTimeLimitSeconds, quizTimeLimitSeconds) ||
                other.quizTimeLimitSeconds == quizTimeLimitSeconds) &&
            const DeepCollectionEquality()
                .equals(other._checklistItems, _checklistItems) &&
            (identical(other.validationType, validationType) ||
                other.validationType == validationType) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.timeLimitSeconds, timeLimitSeconds) ||
                other.timeLimitSeconds == timeLimitSeconds) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        clueId,
        orderIndex,
        type,
        title,
        description,
        instruction,
        targetLatitude,
        targetLongitude,
        locationRadiusMeters,
        referenceImageUrl,
        questQuestion,
        questAnswer,
        questAnswerType,
        quizCorrectAnswer,
        quizExplanation,
        quizTimeLimitSeconds,
        const DeepCollectionEquality().hash(_checklistItems),
        validationType,
        points,
        isRequired,
        timeLimitSeconds,
        hint,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of ClueStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClueStepImplCopyWith<_$ClueStepImpl> get copyWith =>
      __$$ClueStepImplCopyWithImpl<_$ClueStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClueStepImplToJson(
      this,
    );
  }
}

abstract class _ClueStep implements ClueStep {
  const factory _ClueStep(
      {required final String id,
      @JsonKey(name: 'clue_id') required final String clueId,
      @JsonKey(name: 'order_index') required final int orderIndex,
      required final StepType type,
      final String? title,
      final String? description,
      final String? instruction,
      @JsonKey(name: 'target_latitude') final double? targetLatitude,
      @JsonKey(name: 'target_longitude') final double? targetLongitude,
      @JsonKey(name: 'location_radius_meters')
      final double? locationRadiusMeters,
      @JsonKey(name: 'reference_image_url') final String? referenceImageUrl,
      @JsonKey(name: 'quest_question') final String? questQuestion,
      @JsonKey(name: 'quest_answer') final String? questAnswer,
      @JsonKey(name: 'quest_answer_type') final String? questAnswerType,
      @JsonKey(name: 'quiz_correct_answer') final bool? quizCorrectAnswer,
      @JsonKey(name: 'quiz_explanation') final String? quizExplanation,
      @JsonKey(name: 'quiz_time_limit_seconds') final int? quizTimeLimitSeconds,
      @JsonKey(name: 'checklist_items')
      final List<ChecklistItem>? checklistItems,
      @JsonKey(name: 'validation_type') final ValidationType validationType,
      final int points,
      @JsonKey(name: 'is_required') final bool isRequired,
      @JsonKey(name: 'time_limit_seconds') final int? timeLimitSeconds,
      final String? hint,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt}) = _$ClueStepImpl;

  factory _ClueStep.fromJson(Map<String, dynamic> json) =
      _$ClueStepImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'clue_id')
  String get clueId;
  @override
  @JsonKey(name: 'order_index')
  int get orderIndex;
  @override
  StepType get type;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get instruction;
  @override
  @JsonKey(name: 'target_latitude')
  double? get targetLatitude;
  @override
  @JsonKey(name: 'target_longitude')
  double? get targetLongitude;
  @override
  @JsonKey(name: 'location_radius_meters')
  double? get locationRadiusMeters;
  @override
  @JsonKey(name: 'reference_image_url')
  String? get referenceImageUrl;
  @override
  @JsonKey(name: 'quest_question')
  String? get questQuestion;
  @override
  @JsonKey(name: 'quest_answer')
  String? get questAnswer;
  @override
  @JsonKey(name: 'quest_answer_type')
  String? get questAnswerType;
  @override
  @JsonKey(name: 'quiz_correct_answer')
  bool? get quizCorrectAnswer;
  @override
  @JsonKey(name: 'quiz_explanation')
  String? get quizExplanation;
  @override
  @JsonKey(name: 'quiz_time_limit_seconds')
  int? get quizTimeLimitSeconds;
  @override
  @JsonKey(name: 'checklist_items')
  List<ChecklistItem>? get checklistItems;
  @override
  @JsonKey(name: 'validation_type')
  ValidationType get validationType;
  @override
  int get points;
  @override
  @JsonKey(name: 'is_required')
  bool get isRequired;
  @override
  @JsonKey(name: 'time_limit_seconds')
  int? get timeLimitSeconds;
  @override
  String? get hint;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ClueStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClueStepImplCopyWith<_$ClueStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
