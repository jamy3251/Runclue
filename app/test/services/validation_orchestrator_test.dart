import 'package:flutter_test/flutter_test.dart';
import 'package:runclue/services/evidence_service.dart';
import 'package:runclue/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ValidationOrchestrator의 핵심 로직인 "타입별 검증 분기"를 테스트한다.
// 실제 Supabase 호출(submitEvidence, validateEvidence)은 통합 테스트에서 검증.
// 여기서는 auto-validation 로직의 분기가 올바른지만 확인.

final _dummyClient = SupabaseClient('https://dummy.supabase.co', 'dummy-key');

void main() {
  late EvidenceService evidenceService;

  setUp(() {
    evidenceService = EvidenceService(
      client: _dummyClient,
      locationService: LocationService(),
    );
  });

  group('검증 분기 로직', () {
    test('CHECKPOINT: GPS 이내 → auto_approved로 판정', () {
      final evidence = {'latitude': 37.5666, 'longitude': 126.9784};
      final step = {
        'type': 'CHECKPOINT',
        'latitude': 37.5667,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      final result = evidenceService.autoValidateCheckpoint(evidence, step);
      expect(result, isTrue, reason: '50m 이내이므로 통과');
    });

    test('CHECKPOINT: GPS 초과 → auto_rejected로 판정', () {
      final evidence = {'latitude': 37.5666, 'longitude': 126.9784};
      final step = {
        'type': 'CHECKPOINT',
        'latitude': 37.5700,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      final result = evidenceService.autoValidateCheckpoint(evidence, step);
      expect(result, isFalse, reason: '50m 초과이므로 실패');
    });

    test('OX_QUIZ: 정답 O → auto_approved', () {
      final evidence = {'answer': 'true'};
      final step = {'type': 'OX_QUIZ', 'correct_answer': 'true'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('OX_QUIZ: 오답 → auto_rejected', () {
      final evidence = {'answer': 'false'};
      final step = {'type': 'OX_QUIZ', 'correct_answer': 'true'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isFalse);
    });

    test('LIST: 전체 완료 → auto_approved', () {
      final evidence = {
        'checked_items': ['a', 'b', 'c']
      };
      final step = {
        'type': 'LIST',
        'checklist_items': ['a', 'b', 'c']
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isTrue);
    });

    test('LIST: 일부 미완료 → auto_rejected', () {
      final evidence = {
        'checked_items': ['a', 'b']
      };
      final step = {
        'type': 'LIST',
        'checklist_items': ['a', 'b', 'c']
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isFalse);
    });

    test('QUEST auto: 정답 → auto_approved', () {
      final evidence = {'answer': '서울'};
      final step = {
        'type': 'QUEST',
        'correct_answer': '서울',
        'validation_type': 'auto',
      };

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('QUEST auto: 오답 → auto_rejected', () {
      final evidence = {'answer': '부산'};
      final step = {
        'type': 'QUEST',
        'correct_answer': '서울',
        'validation_type': 'auto',
      };

      expect(evidenceService.autoValidateQuiz(evidence, step), isFalse);
    });

    // SNAPSHOT과 QUEST manual은 항상 pending → 수동 검증 대기
    // 이 로직은 ValidationOrchestrator에서 분기 (Supabase 호출 필요)
    // 여기서는 순수 로직만 테스트
  });

  group('경계값 테스트', () {
    test('GPS 거리 0m (같은 좌표) → auto_approved', () {
      final evidence = {'latitude': 37.5666, 'longitude': 126.9784};
      final step = {
        'latitude': 37.5666,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isTrue);
    });

    test('퀴즈 한국어 정답 비교', () {
      final evidence = {'answer': '대한민국'};
      final step = {'correct_answer': '대한민국'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('퀴즈 앞뒤 공백 + 대소문자 무시', () {
      final evidence = {'answer': '  Seoul  '};
      final step = {'correct_answer': 'seoul'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });
  });
}
