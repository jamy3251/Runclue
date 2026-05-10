import 'package:flutter_test/flutter_test.dart';
import 'package:runclue/services/deep_link_service.dart';

void main() {
  group('generateClueLink', () {
    test('올바른 URL 형식 생성', () {
      final link = DeepLinkService.generateClueLink('abc-123');
      expect(link, 'https://runclue.app/clue/abc-123');
    });
  });

  group('parseClueId', () {
    test('정상 URL에서 clueId 추출', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/clue/abc-123',
      );
      expect(id, 'abc-123');
    });

    test('/join/ 형식에서도 clueId 추출', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/join/abc-123',
      );
      expect(id, 'abc-123');
    });

    test('UUID 형식 clueId 추출', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/clue/550e8400-e29b-41d4-a716-446655440000',
      );
      expect(id, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('잘못된 경로이면 null 반환', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/explore',
      );
      expect(id, isNull);
    });

    test('빈 clueId이면 null 반환', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/clue/',
      );
      // trailing slash → pathSegments = ['clue', ''] or ['clue']
      expect(id, isNull);
    });

    test('완전히 잘못된 URL이면 null 반환', () {
      final id = DeepLinkService.parseClueId('not-a-url');
      expect(id, isNull);
    });

    test('빈 문자열이면 null 반환', () {
      final id = DeepLinkService.parseClueId('');
      expect(id, isNull);
    });

    test('쿼리 파라미터가 있어도 clueId 추출', () {
      final id = DeepLinkService.parseClueId(
        'https://runclue.app/clue/abc-123?ref=kakao',
      );
      expect(id, 'abc-123');
    });
  });
}
