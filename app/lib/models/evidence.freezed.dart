// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evidence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Evidence _$EvidenceFromJson(Map<String, dynamic> json) {
  return _Evidence.fromJson(json);
}

/// @nodoc
mixin _$Evidence {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'step_id')
  String get stepId => throw _privateConstructorUsedError;
  @JsonKey(name: 'participation_id')
  String get participationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  EvidenceType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_url')
  String? get mediaUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'text_content')
  String? get textContent => throw _privateConstructorUsedError;
  @JsonKey(name: 'boolean_answer')
  bool? get booleanAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'checklist_state')
  Map<String, dynamic>? get checklistState =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_latitude')
  double? get submittedLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_longitude')
  double? get submittedLongitude => throw _privateConstructorUsedError;
  EvidenceStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'validated_at')
  DateTime? get validatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'validated_by')
  String? get validatedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'rejection_reason')
  String? get rejectionReason => throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_at')
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Evidence to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Evidence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvidenceCopyWith<Evidence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvidenceCopyWith<$Res> {
  factory $EvidenceCopyWith(Evidence value, $Res Function(Evidence) then) =
      _$EvidenceCopyWithImpl<$Res, Evidence>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'step_id') String stepId,
      @JsonKey(name: 'participation_id') String participationId,
      @JsonKey(name: 'user_id') String userId,
      EvidenceType type,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'text_content') String? textContent,
      @JsonKey(name: 'boolean_answer') bool? booleanAnswer,
      @JsonKey(name: 'checklist_state') Map<String, dynamic>? checklistState,
      @JsonKey(name: 'submitted_latitude') double? submittedLatitude,
      @JsonKey(name: 'submitted_longitude') double? submittedLongitude,
      EvidenceStatus status,
      @JsonKey(name: 'validated_at') DateTime? validatedAt,
      @JsonKey(name: 'validated_by') String? validatedBy,
      @JsonKey(name: 'rejection_reason') String? rejectionReason,
      @JsonKey(name: 'submitted_at') DateTime? submittedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$EvidenceCopyWithImpl<$Res, $Val extends Evidence>
    implements $EvidenceCopyWith<$Res> {
  _$EvidenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Evidence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? participationId = null,
    Object? userId = null,
    Object? type = null,
    Object? mediaUrl = freezed,
    Object? textContent = freezed,
    Object? booleanAnswer = freezed,
    Object? checklistState = freezed,
    Object? submittedLatitude = freezed,
    Object? submittedLongitude = freezed,
    Object? status = null,
    Object? validatedAt = freezed,
    Object? validatedBy = freezed,
    Object? rejectionReason = freezed,
    Object? submittedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      stepId: null == stepId
          ? _value.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      participationId: null == participationId
          ? _value.participationId
          : participationId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EvidenceType,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      textContent: freezed == textContent
          ? _value.textContent
          : textContent // ignore: cast_nullable_to_non_nullable
              as String?,
      booleanAnswer: freezed == booleanAnswer
          ? _value.booleanAnswer
          : booleanAnswer // ignore: cast_nullable_to_non_nullable
              as bool?,
      checklistState: freezed == checklistState
          ? _value.checklistState
          : checklistState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      submittedLatitude: freezed == submittedLatitude
          ? _value.submittedLatitude
          : submittedLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      submittedLongitude: freezed == submittedLongitude
          ? _value.submittedLongitude
          : submittedLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as EvidenceStatus,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
abstract class _$$EvidenceImplCopyWith<$Res>
    implements $EvidenceCopyWith<$Res> {
  factory _$$EvidenceImplCopyWith(
          _$EvidenceImpl value, $Res Function(_$EvidenceImpl) then) =
      __$$EvidenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'step_id') String stepId,
      @JsonKey(name: 'participation_id') String participationId,
      @JsonKey(name: 'user_id') String userId,
      EvidenceType type,
      @JsonKey(name: 'media_url') String? mediaUrl,
      @JsonKey(name: 'text_content') String? textContent,
      @JsonKey(name: 'boolean_answer') bool? booleanAnswer,
      @JsonKey(name: 'checklist_state') Map<String, dynamic>? checklistState,
      @JsonKey(name: 'submitted_latitude') double? submittedLatitude,
      @JsonKey(name: 'submitted_longitude') double? submittedLongitude,
      EvidenceStatus status,
      @JsonKey(name: 'validated_at') DateTime? validatedAt,
      @JsonKey(name: 'validated_by') String? validatedBy,
      @JsonKey(name: 'rejection_reason') String? rejectionReason,
      @JsonKey(name: 'submitted_at') DateTime? submittedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$EvidenceImplCopyWithImpl<$Res>
    extends _$EvidenceCopyWithImpl<$Res, _$EvidenceImpl>
    implements _$$EvidenceImplCopyWith<$Res> {
  __$$EvidenceImplCopyWithImpl(
      _$EvidenceImpl _value, $Res Function(_$EvidenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Evidence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? participationId = null,
    Object? userId = null,
    Object? type = null,
    Object? mediaUrl = freezed,
    Object? textContent = freezed,
    Object? booleanAnswer = freezed,
    Object? checklistState = freezed,
    Object? submittedLatitude = freezed,
    Object? submittedLongitude = freezed,
    Object? status = null,
    Object? validatedAt = freezed,
    Object? validatedBy = freezed,
    Object? rejectionReason = freezed,
    Object? submittedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$EvidenceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      stepId: null == stepId
          ? _value.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      participationId: null == participationId
          ? _value.participationId
          : participationId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EvidenceType,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      textContent: freezed == textContent
          ? _value.textContent
          : textContent // ignore: cast_nullable_to_non_nullable
              as String?,
      booleanAnswer: freezed == booleanAnswer
          ? _value.booleanAnswer
          : booleanAnswer // ignore: cast_nullable_to_non_nullable
              as bool?,
      checklistState: freezed == checklistState
          ? _value._checklistState
          : checklistState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      submittedLatitude: freezed == submittedLatitude
          ? _value.submittedLatitude
          : submittedLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      submittedLongitude: freezed == submittedLongitude
          ? _value.submittedLongitude
          : submittedLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as EvidenceStatus,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$EvidenceImpl implements _Evidence {
  const _$EvidenceImpl(
      {required this.id,
      @JsonKey(name: 'step_id') required this.stepId,
      @JsonKey(name: 'participation_id') required this.participationId,
      @JsonKey(name: 'user_id') required this.userId,
      required this.type,
      @JsonKey(name: 'media_url') this.mediaUrl,
      @JsonKey(name: 'text_content') this.textContent,
      @JsonKey(name: 'boolean_answer') this.booleanAnswer,
      @JsonKey(name: 'checklist_state')
      final Map<String, dynamic>? checklistState,
      @JsonKey(name: 'submitted_latitude') this.submittedLatitude,
      @JsonKey(name: 'submitted_longitude') this.submittedLongitude,
      this.status = EvidenceStatus.pending,
      @JsonKey(name: 'validated_at') this.validatedAt,
      @JsonKey(name: 'validated_by') this.validatedBy,
      @JsonKey(name: 'rejection_reason') this.rejectionReason,
      @JsonKey(name: 'submitted_at') this.submittedAt,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _checklistState = checklistState;

  factory _$EvidenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvidenceImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'step_id')
  final String stepId;
  @override
  @JsonKey(name: 'participation_id')
  final String participationId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final EvidenceType type;
  @override
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @override
  @JsonKey(name: 'text_content')
  final String? textContent;
  @override
  @JsonKey(name: 'boolean_answer')
  final bool? booleanAnswer;
  final Map<String, dynamic>? _checklistState;
  @override
  @JsonKey(name: 'checklist_state')
  Map<String, dynamic>? get checklistState {
    final value = _checklistState;
    if (value == null) return null;
    if (_checklistState is EqualUnmodifiableMapView) return _checklistState;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'submitted_latitude')
  final double? submittedLatitude;
  @override
  @JsonKey(name: 'submitted_longitude')
  final double? submittedLongitude;
  @override
  @JsonKey()
  final EvidenceStatus status;
  @override
  @JsonKey(name: 'validated_at')
  final DateTime? validatedAt;
  @override
  @JsonKey(name: 'validated_by')
  final String? validatedBy;
  @override
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;
  @override
  @JsonKey(name: 'submitted_at')
  final DateTime? submittedAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Evidence(id: $id, stepId: $stepId, participationId: $participationId, userId: $userId, type: $type, mediaUrl: $mediaUrl, textContent: $textContent, booleanAnswer: $booleanAnswer, checklistState: $checklistState, submittedLatitude: $submittedLatitude, submittedLongitude: $submittedLongitude, status: $status, validatedAt: $validatedAt, validatedBy: $validatedBy, rejectionReason: $rejectionReason, submittedAt: $submittedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvidenceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.participationId, participationId) ||
                other.participationId == participationId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.textContent, textContent) ||
                other.textContent == textContent) &&
            (identical(other.booleanAnswer, booleanAnswer) ||
                other.booleanAnswer == booleanAnswer) &&
            const DeepCollectionEquality()
                .equals(other._checklistState, _checklistState) &&
            (identical(other.submittedLatitude, submittedLatitude) ||
                other.submittedLatitude == submittedLatitude) &&
            (identical(other.submittedLongitude, submittedLongitude) ||
                other.submittedLongitude == submittedLongitude) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.validatedAt, validatedAt) ||
                other.validatedAt == validatedAt) &&
            (identical(other.validatedBy, validatedBy) ||
                other.validatedBy == validatedBy) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      stepId,
      participationId,
      userId,
      type,
      mediaUrl,
      textContent,
      booleanAnswer,
      const DeepCollectionEquality().hash(_checklistState),
      submittedLatitude,
      submittedLongitude,
      status,
      validatedAt,
      validatedBy,
      rejectionReason,
      submittedAt,
      createdAt,
      updatedAt);

  /// Create a copy of Evidence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvidenceImplCopyWith<_$EvidenceImpl> get copyWith =>
      __$$EvidenceImplCopyWithImpl<_$EvidenceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvidenceImplToJson(
      this,
    );
  }
}

abstract class _Evidence implements Evidence {
  const factory _Evidence(
      {required final String id,
      @JsonKey(name: 'step_id') required final String stepId,
      @JsonKey(name: 'participation_id') required final String participationId,
      @JsonKey(name: 'user_id') required final String userId,
      required final EvidenceType type,
      @JsonKey(name: 'media_url') final String? mediaUrl,
      @JsonKey(name: 'text_content') final String? textContent,
      @JsonKey(name: 'boolean_answer') final bool? booleanAnswer,
      @JsonKey(name: 'checklist_state')
      final Map<String, dynamic>? checklistState,
      @JsonKey(name: 'submitted_latitude') final double? submittedLatitude,
      @JsonKey(name: 'submitted_longitude') final double? submittedLongitude,
      final EvidenceStatus status,
      @JsonKey(name: 'validated_at') final DateTime? validatedAt,
      @JsonKey(name: 'validated_by') final String? validatedBy,
      @JsonKey(name: 'rejection_reason') final String? rejectionReason,
      @JsonKey(name: 'submitted_at') final DateTime? submittedAt,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt}) = _$EvidenceImpl;

  factory _Evidence.fromJson(Map<String, dynamic> json) =
      _$EvidenceImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'step_id')
  String get stepId;
  @override
  @JsonKey(name: 'participation_id')
  String get participationId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  EvidenceType get type;
  @override
  @JsonKey(name: 'media_url')
  String? get mediaUrl;
  @override
  @JsonKey(name: 'text_content')
  String? get textContent;
  @override
  @JsonKey(name: 'boolean_answer')
  bool? get booleanAnswer;
  @override
  @JsonKey(name: 'checklist_state')
  Map<String, dynamic>? get checklistState;
  @override
  @JsonKey(name: 'submitted_latitude')
  double? get submittedLatitude;
  @override
  @JsonKey(name: 'submitted_longitude')
  double? get submittedLongitude;
  @override
  EvidenceStatus get status;
  @override
  @JsonKey(name: 'validated_at')
  DateTime? get validatedAt;
  @override
  @JsonKey(name: 'validated_by')
  String? get validatedBy;
  @override
  @JsonKey(name: 'rejection_reason')
  String? get rejectionReason;
  @override
  @JsonKey(name: 'submitted_at')
  DateTime? get submittedAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Evidence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvidenceImplCopyWith<_$EvidenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
