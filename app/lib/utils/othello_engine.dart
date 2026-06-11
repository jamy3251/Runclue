/// 미니 오셀로 6×6 순수 로직 — flat 36칸 보드 (jsonb 호환).
/// 솔로 미니게임과 배틀(CPU/PvP)이 공유하는 엔진.
///
/// 칸 값: 0=빈칸, 1=흑(challenger), 2=백(opponent/CPU)
library;

const int othelloN = 6;
const int othelloCells = othelloN * othelloN;

const _dirs = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

/// 초기 보드 — 중앙 4칸 교차 배치, 흑(1) 선공.
List<int> othelloInitialBoard() {
  final b = List<int>.filled(othelloCells, 0);
  const m = othelloN ~/ 2;
  b[(m - 1) * othelloN + (m - 1)] = 2;
  b[m * othelloN + m] = 2;
  b[(m - 1) * othelloN + m] = 1;
  b[m * othelloN + (m - 1)] = 1;
  return b;
}

/// idx에 p가 둘 때 뒤집히는 칸 목록 (빈 리스트 = 둘 수 없음).
List<int> othelloFlips(List<int> board, int idx, int p) {
  if (board[idx] != 0) return const [];
  final r0 = idx ~/ othelloN, c0 = idx % othelloN;
  final opp = p == 1 ? 2 : 1;
  final flips = <int>[];
  for (final d in _dirs) {
    final line = <int>[];
    var r = r0 + d[0], c = c0 + d[1];
    while (r >= 0 && r < othelloN && c >= 0 && c < othelloN &&
        board[r * othelloN + c] == opp) {
      line.add(r * othelloN + c);
      r += d[0];
      c += d[1];
    }
    if (line.isNotEmpty &&
        r >= 0 && r < othelloN && c >= 0 && c < othelloN &&
        board[r * othelloN + c] == p) {
      flips.addAll(line);
    }
  }
  return flips;
}

bool othelloHasAnyMove(List<int> board, int p) {
  for (var i = 0; i < othelloCells; i++) {
    if (othelloFlips(board, i, p).isNotEmpty) return true;
  }
  return false;
}

/// 수 적용 — 새 보드 반환 (불변). 둘 수 없으면 null.
List<int>? othelloApply(List<int> board, int idx, int p) {
  final flips = othelloFlips(board, idx, p);
  if (flips.isEmpty) return null;
  final next = List<int>.from(board);
  next[idx] = p;
  for (final f in flips) {
    next[f] = p;
  }
  return next;
}

/// greedy CPU — 가장 많이 뒤집는 수의 인덱스 (둘 수 없으면 -1).
int othelloGreedyMove(List<int> board, int p) {
  var best = -1, bestCount = 0;
  for (var i = 0; i < othelloCells; i++) {
    final n = othelloFlips(board, i, p).length;
    if (n > bestCount) {
      bestCount = n;
      best = i;
    }
  }
  return best;
}

/// (흑 돌 수, 백 돌 수)
(int, int) othelloCount(List<int> board) {
  var black = 0, white = 0;
  for (final v in board) {
    if (v == 1) black++;
    if (v == 2) white++;
  }
  return (black, white);
}

/// 양쪽 모두 둘 수 없으면 종료.
bool othelloIsFinished(List<int> board) =>
    !othelloHasAnyMove(board, 1) && !othelloHasAnyMove(board, 2);
