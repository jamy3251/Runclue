import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';

/// 미니 오셀로 6×6 vs CPU. 승리 시 +10p.
class OthelloGame extends ConsumerStatefulWidget {
  const OthelloGame({super.key});

  @override
  ConsumerState<OthelloGame> createState() => _OthelloGameState();
}

const int N = 6;
const int B = 1; // 흑 (사용자)
const int W = 2; // 백 (CPU)
const _dirs = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

class _OthelloGameState extends ConsumerState<OthelloGame> {
  late List<List<int>> _board;
  int _turn = B;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(N, (_) => List.filled(N, 0));
    final m = N ~/ 2;
    _board[m - 1][m - 1] = W;
    _board[m][m] = W;
    _board[m - 1][m] = B;
    _board[m][m - 1] = B;
    _turn = B;
    _winner = null;
    setState(() {});
  }

  List<List<int>> _flips(List<List<int>> b, int r, int c, int p) {
    if (b[r][c] != 0) return [];
    final opp = p == B ? W : B;
    final flips = <List<int>>[];
    for (final d in _dirs) {
      final line = <List<int>>[];
      int rr = r + d[0], cc = c + d[1];
      while (rr >= 0 && rr < N && cc >= 0 && cc < N && b[rr][cc] == opp) {
        line.add([rr, cc]);
        rr += d[0];
        cc += d[1];
      }
      if (line.isNotEmpty &&
          rr >= 0 && rr < N && cc >= 0 && cc < N &&
          b[rr][cc] == p) {
        flips.addAll(line);
      }
    }
    return flips;
  }

  bool _hasAnyMove(List<List<int>> b, int p) {
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < N; c++) {
        if (_flips(b, r, c, p).isNotEmpty) return true;
      }
    }
    return false;
  }

  Map<String, int> _count(List<List<int>> b) {
    int bk = 0, wt = 0;
    for (final row in b) {
      for (final v in row) {
        if (v == B) bk++;
        if (v == W) wt++;
      }
    }
    return {'B': bk, 'W': wt};
  }

  void _play(int r, int c) {
    if (_turn != B || _winner != null) return;
    final flips = _flips(_board, r, c, B);
    if (flips.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _board[r][c] = B;
      for (final f in flips) {
        _board[f[0]][f[1]] = B;
      }
      _turn = W;
    });
    Future.delayed(const Duration(milliseconds: 500), _cpuMove);
  }

  void _cpuMove() {
    if (_winner != null) return;
    // greedy — 가장 많이 뒤집는 수
    int bestR = -1, bestC = -1, bestCount = 0;
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < N; c++) {
        final flips = _flips(_board, r, c, W);
        if (flips.length > bestCount) {
          bestCount = flips.length;
          bestR = r;
          bestC = c;
        }
      }
    }
    if (bestR < 0) {
      // CPU 패스 — 사용자도 못 두면 종료
      if (!_hasAnyMove(_board, B)) return _finish();
      setState(() => _turn = B);
      return;
    }
    final flips = _flips(_board, bestR, bestC, W);
    setState(() {
      _board[bestR][bestC] = W;
      for (final f in flips) {
        _board[f[0]][f[1]] = W;
      }
      _turn = B;
    });
    if (!_hasAnyMove(_board, B)) {
      // 사용자 패스
      if (!_hasAnyMove(_board, W)) return _finish();
      Future.delayed(const Duration(milliseconds: 600), _cpuMove);
    }
  }

  void _finish() {
    final cnt = _count(_board);
    setState(() {
      _winner = cnt['B']! > cnt['W']!
          ? 'win'
          : cnt['B']! < cnt['W']!
              ? 'lose'
              : 'draw';
    });
    HapticFeedback.heavyImpact();
    if (_winner == 'win') _awardPoints(10);
  }

  Future<void> _awardPoints(int p) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(pointsServiceProvider).add(
          userId: uid,
          delta: p,
          reason: 'minigame:othello:win',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${p}p 획득!'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.brandGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cnt = _count(_board);
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('오셀로 6×6',
            style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _scoreCard('나 (●)', cnt['B'] ?? 0,
                      AppColors.textPrimary, _turn == B && _winner == null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _scoreCard('CPU (○)', cnt['W'] ?? 0, Colors.white,
                      _turn == W && _winner == null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_winner != null) _resultBanner(),
            if (_winner != null) const SizedBox(height: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: N,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: N * N,
                    itemBuilder: (_, i) {
                      final r = i ~/ N;
                      final c = i % N;
                      final v = _board[r][c];
                      final canPlay = _turn == B &&
                          _winner == null &&
                          _flips(_board, r, c, B).isNotEmpty;
                      return GestureDetector(
                        onTap: canPlay ? () => _play(r, c) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: v == 0
                              ? (canPlay
                                  ? Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.brandYellow
                                            .withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : const SizedBox.shrink())
                              : Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: v == B ? Colors.black : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                          offset: Offset(0, 1))
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _winner != null
                  ? '게임 종료'
                  : _turn == B
                      ? '내 차례 — 노란 점에 두세요'
                      : 'CPU 생각 중...',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(String label, int v, Color pieceColor, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColors.brandYellow
              : AppColors.borderDefault,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDefault),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
          Text('$v',
              style: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _resultBanner() {
    final color = switch (_winner) {
      'win' => AppColors.brandGreen,
      'lose' => AppColors.brandRed,
      _ => AppColors.brandYellow,
    };
    final label = switch (_winner) {
      'win' => '🎉 승리!',
      'lose' => '😢 패배',
      _ => '🤝 무승부',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w900)),
    );
  }
}
