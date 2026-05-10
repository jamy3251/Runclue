import 'package:freezed_annotation/freezed_annotation.dart';

part 'evidence.freezed.dart';
part 'evidence.g.dart';

@JsonEnum(valueField: 'value')
enum EvidenceType {
  @JsonValue('photo')
  photo('photo'),
  @JsonValue('location')
  location('location'),
  @JsonValue('video')
  video('video'),
  @JsonValue('qr_scan')
  qrScan('qr_scan'),
  @JsonValue('text_answer')
  textAnswer('text_answer'),
  @JsonValue('ox_answer')
  oxAnswer('ox_answer'),
  @JsonValue('checklist')
  checklist('checklist');

  const EvidenceType(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum EvidenceStatus {
  @JsonValue('pending')
  pending('pending'),
  @JsonValue('approved')
  approved('approved'),
  @JsonValue('rejected')
  rejected('rejected'),
  @JsonValue('auto_approved')
  autoApproved('auto_approved'),
  @JsonValue('auto_rejected')
  autoRejected('auto_rejected');

  const EvidenceStatus(this.value);
  final String value;
}

@freezed
class Evidence with _$Evidence {
  const factory Evidence({
    required String id,
    @JsonKey(name: 'step_id') required String stepId,
    @JsonKey(name: 'participation_id') required String participationId,
    @JsonKey(name: 'user_id') required String userId,
    required EvidenceType type,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'text_content') String? textContent,
    @JsonKey(name: 'boolean_answer') bool? booleanAnswer,
    @JsonKey(name: 'checklist_state') Map<String, dynamic>? checklistState,
    @JsonKey(name: 'submitted_latitude') double? submittedLatitude,
    @JsonKey(name: 'submitted_longitude') double? submittedLongitude,
    @Default(EvidenceStatus.pending) EvidenceStatus status,
    @JsonKey(name: 'validated_at') DateTime? validatedAt,
    @JsonKey(name: 'validated_by') String? validatedBy,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'submitted_at') DateTime? submittedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Evidence;

  factory Evidence.fromJson(Map<String, dynamic> json) =>
      _$EvidenceFromJson(json);
}
