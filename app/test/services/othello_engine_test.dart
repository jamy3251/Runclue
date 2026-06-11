import 'package:flutter_test/flutter_test.dart';
import 'package:runclue/utils/othello_engine.dart';

void main() {
  group('othello engine', () {
    test('초기 보드 — 중앙 4칸, 흑백 2:2', () {
      final b = othelloInitialBoard();
      expect(b.length, othelloCells);
      final (black, white) = othelloCount(b);
      expect(black, 2);
      expect(white, 2);
      // (2,3)=15, (3,2)=20 흑 / (2,2)=14, (3,3)=21 백
      expect(b[15], 1);
      expect(b[20], 1);
      expect(b[14], 2);
      expect(b[21], 2);
    });

    test('초기 보드에서 흑은 둘 수 있다', () {
      final b = othelloInitialBoard();
      expect(othelloHasAnyMove(b, 1), isTrue);
      expect(othelloIsFinished(b), isFalse);
    });

    test('합법 수 적용 — 돌이 뒤집힌다', () {
      final b = othelloInitialBoard();
      // (1,3)=9 에 흑을 두면 (2,3)=15 방향으로 백(14)이 아니라...
      // (2,2)=14 백을 사이에 두는 수: (1,2)=8? 검증: 8 아래(2,2)=14 백, (3,2)=20 흑 → 합법
      final next = othelloApply(b, 8, 1);
      expect(next, isNotNull);
      expect(next![8], 1);
      expect(next[14], 1); // 뒤집힘
      final (black, white) = othelloCount(next);
      expect(black, 4);
      expect(white, 1);
    });

    test('불법 수 — null 반환', () {
      final b = othelloInitialBoard();
      expect(othelloApply(b, 0, 1), isNull); // 구석 — 뒤집을 돌 없음
      expect(othelloApply(b, 14, 1), isNull); // 이미 돌 있음
    });

    test('greedy CPU는 합법 수를 고른다', () {
      final b = othelloInitialBoard();
      final mv = othelloGreedyMove(b, 2);
      expect(mv, greaterThanOrEqualTo(0));
      expect(othelloApply(b, mv, 2), isNotNull);
    });

    test('가득 찬 보드는 종료', () {
      final b = List<int>.filled(othelloCells, 1);
      expect(othelloIsFinished(b), isTrue);
      final (black, white) = othelloCount(b);
      expect(black, 36);
      expect(white, 0);
    });
  });
}
