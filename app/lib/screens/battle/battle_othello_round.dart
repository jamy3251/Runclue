import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../utils/othello_engine.dart';

/// 오셀로 배틀 — vs CPU 라운드: 로컬 전판 플레이 후 최종 보드 콜백.
class BattleOthelloCpuRound extends StatefulWidget {
  const BattleOthelloCpuRound({super.key, required this.onDone});

  /// 게임 종료 시 최종 보드 전달 (서버가 돌 수로 판정).
  final void Function(List<int> finalBoard) onDone;

  @override
  State<BattleOthelloCpuRound> createState() => _BattleOthelloCpuRoundState();
}

class _BattleOthelloCpuRoundState extends State<BattleOthelloCpuRound> {
  late List<int> _board = othelloInitialBoard();
  int _turn = 1; // 1=나(흑), 2=CPU(백)
  bool _done = false;

  void _tap(int idx) {
    if (_turn != 1 || _done) return;
    final next = othelloApply(_board, idx, 1);
    if (next == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _board = next;
      _turn = 2;
    });
    Future.delayed(const Duration(milliseconds: 450), _cpuMove);
  }

  void _cpuMove() {
    if (_done || !mounted) return;
    final mv = othelloGreedyMove(_board, 2);
    if (mv >= 0) {
      setState(() => _board = othelloApply(_board, mv, 2)!);
    }
    if (othelloIsFinished(_board)) return _finish();
    if (othelloHasAnyMove(_board, 1)) {
      setState(() => _turn = 1);
    } else {
      // 내가 패스 — CPU 연속
      Future.delayed(const Duration(milliseconds: 450), _cpuMove);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    HapticFeedback.heavyImpact();
    widget.onDone(_board);
  }

  @override
  Widget build(BuildContext context) {
    final (mine, opp) = othelloCount(_board);
    return _OthelloBoardView(
      board: _board,
      myColor: 1,
      myTurn: _turn == 1 && !_done,
      myCount: mine,
      oppCount: opp,
      oppLabel: 'CPU',
      onTap: _tap,
    );
  }
}

/// 오셀로 배틀 — PvP 보드: 부모(battle_game_screen)가 폴링한 state를 표시하고,
/// 내 턴에 수를 두면 새 state를 콜백 (battle_move 제출은 부모 책임).
class BattleOthelloPvpBoard extends StatelessWidget {
  const BattleOthelloPvpBoard({
    super.key,
    required this.state,
    required this.myRole,
    required this.onMove,
    this.submitting = false,
  });

  /// game_state: {board, turn, finished}
  final Map<String, dynamic> state;

  /// challenger=1(흑), opponent=2(백)
  final int myRole;
  final bool submitting;
  final void Function(Map<String, dynamic> newState) onMove;

  @override
  Widget build(BuildContext context) {
    final board =
        (state['board'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            othelloInitialBoard();
    final turn = (state['turn'] as num?)?.toInt() ?? 1;
    final myTurn = turn == myRole && !submitting;
    final (black, white) = othelloCount(board);

    return _OthelloBoardView(
      board: board,
      myColor: myRole,
      myTurn: myTurn,
      myCount: myRole == 1 ? black : white,
      oppCount: myRole == 1 ? white : black,
      oppLabel: '상대',
      waitingLabel: submitting
          ? '제출 중...'
          : (myTurn ? null : '상대 차례 — 기다리는 중...'),
      onTap: (idx) {
        if (!myTurn) return;
        final next = othelloApply(board, idx, myRole);
        if (next == null) return;
        HapticFeedback.lightImpact();

        final oppRole = 3 - myRole;
        final finished = othelloIsFinished(next);
        // 상대가 둘 수 없으면 턴 유지 (연속 수), 둘 다 못 두면 종료
        final nextTurn = finished
            ? 0
            : (othelloHasAnyMove(next, oppRole) ? oppRole : myRole);
        onMove({
          'board': next,
          'turn': nextTurn,
          'finished': finished,
        });
      },
    );
  }
}

/// 공용 보드 렌더링 — 6×6 그리드 + 점수 헤더.
class _OthelloBoardView extends StatelessWidget {
  const _OthelloBoardView({
    required this.board,
    required this.myColor,
    required this.myTurn,
    required this.myCount,
    required this.oppCount,
    required this.oppLabel,
    required this.onTap,
    this.waitingLabel,
  });

  final List<int> board;
  final int myColor;
  final bool myTurn;
  final int myCount;
  final int oppCount;
  final String oppLabel;
  final String? waitingLabel;
  final void Function(int idx) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _scoreChip('나', myCount, myColor == 1 ? Colors.black : Colors.white,
                highlight: myTurn,),
            const SizedBox(width: 12),
            _scoreChip(oppLabel, oppCount,
                myColor == 1 ? Colors.white : Colors.black,
                highlight: !myTurn,),
          ],
        ),
        if (waitingLabel != null) ...[
          const SizedBox(height: 6),
          Text(waitingLabel!,
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: AppColors.brandYellow,),),
        ],
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: myTurn
                      ? AppColors.brandYellow
                      : AppColors.borderDefault,
                  width: 2,),
            ),
            padding: const EdgeInsets.all(6),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: othelloN,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: othelloCells,
              itemBuilder: (_, i) {
                final v = board[i];
                final canPlay = myTurn &&
                    v == 0 &&
                    othelloFlips(board, i, myColor).isNotEmpty;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(4),
                      border: canPlay
                          ? Border.all(
                              color: AppColors.brandYellow
                                  .withValues(alpha: 0.7),)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: v == 0
                        ? (canPlay
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.brandYellow
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null)
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: v == 1 ? Colors.black : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38, blurRadius: 2,),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreChip(String label, int count, Color stone,
      {required bool highlight,}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: highlight ? AppColors.brandYellow : AppColors.borderDefault,
            width: highlight ? 2 : 1,),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: stone,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDefault),
            ),
          ),
          const SizedBox(width: 6),
          Text('$label $count',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,),),
        ],
      ),
    );
  }
}
