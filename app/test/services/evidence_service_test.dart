import 'package:flutter_test/flutter_test.dart';
import 'package:runclue/services/evidence_service.dart';
import 'package:runclue/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 검증 로직만 테스트하므로 Supabase client는 사용하지 않음.
// auto-validate 메서드들은 순수 함수로 네트워크 호출 없음.
final _dummyClient = SupabaseClient('https://dummy.supabase.co', 'dummy-key');

void main() {
  late EvidenceService evidenceService;

  setUp(() {
    evidenceService = EvidenceService(
      client: _dummyClient,
      locationService: LocationService(),
    );
  });

  group('autoValidateCheckpoint', () {
    test('50m 이내이면 true 반환', () {
      // 서울시청 (37.5666, 126.9784) 기준, 약 30m 떨어진 지점
      final evidence = {
        'latitude': 37.5666,
        'longitude': 126.9784,
      };
      final step = {
        'latitude': 37.5669,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isTrue);
    });

    test('50m 초과이면 false 반환', () {
      // 약 200m 떨어진 지점
      final evidence = {
        'latitude': 37.5666,
        'longitude': 126.9784,
      };
      final step = {
        'latitude': 37.5685,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isFalse);
    });

    test('정확히 같은 좌표이면 true 반환', () {
      final evidence = {
        'latitude': 37.5666,
        'longitude': 126.9784,
      };
      final step = {
        'latitude': 37.5666,
        'longitude': 126.9784,
        'radius_meters': 50,
      };

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isTrue);
    });

    test('radius_meters 미지정 시 기본값 50m 사용', () {
      final evidence = {
        'latitude': 37.5666,
        'longitude': 126.9784,
      };
      final step = {
        'latitude': 37.5669,
        'longitude': 126.9784,
        // radius_meters 없음 → 기본 50m
      };

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isTrue);
    });

    test('잘못된 데이터이면 false 반환 (exception 안 던짐)', () {
      final evidence = <String, dynamic>{};
      final step = <String, dynamic>{};

      expect(evidenceService.autoValidateCheckpoint(evidence, step), isFalse);
    });
  });

  group('autoValidateQuiz', () {
    test('정답 일치 시 true 반환', () {
      final evidence = {'answer': 'O'};
      final step = {'correct_answer': 'O'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('대소문자 무시하여 비교', () {
      final evidence = {'answer': 'True'};
      final step = {'correct_answer': 'true'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('앞뒤 공백 제거 후 비교', () {
      final evidence = {'answer': '  O  '};
      final step = {'correct_answer': 'O'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isTrue);
    });

    test('오답이면 false 반환', () {
      final evidence = {'answer': 'X'};
      final step = {'correct_answer': 'O'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isFalse);
    });

    test('빈 답안이면 false 반환', () {
      final evidence = {'answer': ''};
      final step = {'correct_answer': 'O'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isFalse);
    });

    test('null 답안이면 false 반환', () {
      final evidence = <String, dynamic>{};
      final step = {'correct_answer': 'O'};

      expect(evidenceService.autoValidateQuiz(evidence, step), isFalse);
    });
  });

  group('autoValidateChecklist', () {
    test('필수 항목 전체 완료 시 true 반환', () {
      final evidence = {
        'checked_items': ['item1', 'item2', 'item3'],
      };
      final step = {
        'checklist_items': ['item1', 'item2', 'item3'],
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isTrue);
    });

    test('필수 항목 일부 미완료 시 false 반환', () {
      final evidence = {
        'checked_items': ['item1', 'item2'],
      };
      final step = {
        'checklist_items': ['item1', 'item2', 'item3'],
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isFalse);
    });

    test('추가 항목이 있어도 필수 전부 포함이면 true', () {
      final evidence = {
        'checked_items': ['item1', 'item2', 'item3', 'extra'],
      };
      final step = {
        'checklist_items': ['item1', 'item2', 'item3'],
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isTrue);
    });

    test('빈 체크리스트이면 false 반환', () {
      final evidence = {
        'checked_items': <String>[],
      };
      final step = {
        'checklist_items': ['item1'],
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isFalse);
    });

    test('필수 항목이 없으면 false 반환', () {
      final evidence = {
        'checked_items': ['item1'],
      };
      final step = {
        'checklist_items': <String>[],
      };

      expect(evidenceService.autoValidateChecklist(evidence, step), isFalse);
    });
  });
}
