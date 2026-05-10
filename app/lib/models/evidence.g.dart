// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvidenceImpl _$$EvidenceImplFromJson(Map<String, dynamic> json) =>
    _$EvidenceImpl(
      id: json['id'] as String,
      stepId: json['step_id'] as String,
      participationId: json['participation_id'] as String,
      userId: json['user_id'] as String,
      type: $enumDecode(_$EvidenceTypeEnumMap, json['type']),
      mediaUrl: json['media_url'] as String?,
      textContent: json['text_content'] as String?,
      booleanAnswer: json['boolean_answer'] as bool?,
      checklistState: json['checklist_state'] as Map<String, dynamic>?,
      submittedLatitude: (json['submitted_latitude'] as num?)?.toDouble(),
      submittedLongitude: (json['submitted_longitude'] as num?)?.toDouble(),
      status: $enumDecodeNullable(_$EvidenceStatusEnumMap, json['status']) ??
          EvidenceStatus.pending,
      validatedAt: json['validated_at'] == null
          ? null
          : DateTime.parse(json['validated_at'] as String),
      validatedBy: json['validated_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$EvidenceImplToJson(_$EvidenceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'step_id': instance.stepId,
      'participation_id': instance.participationId,
      'user_id': instance.userId,
      'type': _$EvidenceTypeEnumMap[instance.type]!,
      'media_url': instance.mediaUrl,
      'text_content': instance.textContent,
      'boolean_answer': instance.booleanAnswer,
      'checklist_state': instance.checklistState,
      'submitted_latitude': instance.submittedLatitude,
      'submitted_longitude': instance.submittedLongitude,
      'status': _$EvidenceStatusEnumMap[instance.status]!,
      'validated_at': instance.validatedAt?.toIso8601String(),
      'validated_by': instance.validatedBy,
      'rejection_reason': instance.rejectionReason,
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$EvidenceTypeEnumMap = {
  EvidenceType.photo: 'photo',
  EvidenceType.location: 'location',
  EvidenceType.video: 'video',
  EvidenceType.qrScan: 'qr_scan',
  EvidenceType.textAnswer: 'text_answer',
  EvidenceType.oxAnswer: 'ox_answer',
  EvidenceType.checklist: 'checklist',
};

const _$EvidenceStatusEnumMap = {
  EvidenceStatus.pending: 'pending',
  EvidenceStatus.approved: 'approved',
  EvidenceStatus.rejected: 'rejected',
  EvidenceStatus.autoApproved: 'auto_approved',
  EvidenceStatus.autoRejected: 'auto_rejected',
};
