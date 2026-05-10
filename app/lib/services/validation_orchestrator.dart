import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'evidence_service.dart';
import 'location_service.dart';

/// Evidence 제출 시 Step 타입에 따라 자동/수동/지연 검증을 분기하는 오케스트레이터.
///
/// 검증 흐름:
///   CHECKPOINT → autoValidateCheckpoint() → 즉시 auto_approved/auto_rejected
///   OX_QUIZ    → autoValidateQuiz()       → 즉시 auto_approved/auto_rejected
///   LIST       → autoValidateChecklist()  → 즉시 auto_approved/auto_rejected
///   SNAPSHOT   → pending (수동)           → 10분 타임아웃 시 auto_approved
///   QUEST      → validation_type에 따라:
///                  auto    → autoValidateQuiz()
///                  manual  → pending (수동)
///                  delayed → pending → 10분 타임아웃
class ValidationOrchestrator {
  final EvidenceService _evidenceService;
  final SupabaseClient _client;

  ValidationOrchestrator({
    EvidenceService? evidenceService,
    SupabaseClient? client,
  })  : _evidenceService = evidenceService ??
            EvidenceService(locationService: LocationService()),
        _client = client ?? safeClient;

  /// Evidence를 제출하고 적절한 검증을 수행한다.
  /// 반환: 생성된 evidence record (status 포함)
  Future<Map<String, dynamic>> submitAndValidate({
    required Map<String, dynamic> evidenceData,
    required Map<String, dynamic> step,
  }) async {
    // 1. Evidence 제출
    final evidence = await _evidenceService.submitEvidence(evidenceData);
    final evidenceId = evidence['id'] as String;
    final stepType = step['type'] as String;
    final validationType = step['validation_type'] as String? ?? 'auto';

    // 2. 타입별 검증 분기
    String resultStatus;

    switch (stepType) {
      case 'CHECKPOINT':
        final passed = _evidenceService.autoValidateCheckpoint(evidence, step);
        resultStatus = passed ? 'auto_approved' : 'auto_rejected';
        break;

      case 'OX_QUIZ':
        final passed = _evidenceService.autoValidateQuiz(evidence, step);
        resultStatus = passed ? 'auto_approved' : 'auto_rejected';
        break;

      case 'LIST':
        final passed = _evidenceService.autoValidateChecklist(evidence, step);
        resultStatus = passed ? 'auto_approved' : 'auto_rejected';
        break;

      case 'QUEST':
        if (validationType == 'auto') {
          final passed = _evidenceService.autoValidateQuiz(evidence, step);
          resultStatus = passed ? 'auto_approved' : 'auto_rejected';
        } else {
          // manual 또는 delayed → pending 상태 유지
          // 10분 타임아웃은 Supabase Edge Function에서 처리
          resultStatus = 'pending';
        }
        break;

      case 'SNAPSHOT':
        // 항상 수동 검증 대기 → 10분 타임아웃 시 자동 승인
        resultStatus = 'pending';
        break;

      default:
        resultStatus = 'pending';
    }

    // 3. 검증 결과 업데이트
    if (resultStatus != 'pending') {
      return await _evidenceService.validateEvidence(
        evidenceId: evidenceId,
        status: resultStatus,
      );
    }

    // 4. pending인 경우 호스트에게 알림 전송
    if (resultStatus == 'pending') {
      await _notifyHost(step, evidence);
    }

    return evidence;
  }

  /// 호스트에게 "새 인증이 도착했습니다" 알림 전송
  Future<void> _notifyHost(
    Map<String, dynamic> step,
    Map<String, dynamic> evidence,
  ) async {
    try {
      // step → clue → creator_id 추출
      final clueId = step['clue_id'] as String?;
      if (clueId == null) return;

      final clue = await _client
          .from('clues')
          .select('creator_id, title')
          .eq('id', clueId)
          .single();

      final creatorId = clue['creator_id'] as String;
      final clueTitle = clue['title'] as String? ?? '';

      await _client.from('notifications').insert({
        'user_id': creatorId,
        'type': 'evidence_approved', // 검증 요청 알림
        'title': '새 인증이 도착했습니다',
        'body': '"$clueTitle"에 새로운 인증이 제출되었습니다. 확인해주세요.',
        'data': {
          'evidence_id': evidence['id'],
          'clue_id': clueId,
          'step_id': step['id'],
        },
      });
    } catch (_) {
      // 알림 실패는 검증 플로우를 막지 않는다
    }
  }
}
