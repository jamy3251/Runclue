import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/battle_provider.dart';
import '../../providers/currency_provider.dart';

/// 가위바위보 1판 (Battle game_type='rps').
/// 사용자 선택 → battle_finish RPC.
/// vs CPU: 즉시 결과. vs 사용자: 상대 선택 대기.
class BattleGameScreen extends ConsumerStatefulWidget {
  const BattleGameScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends ConsumerState<BattleGameScreen> {
  bool _busy = false;
  bool _myChoiceSubmitted = false;
  Map<String, dynamic>? _finalResult;

  static const _choices = <(String, String, IconData)>[
    ('rock', '바위', Icons.back_hand),
    ('paper', '보', Icons.front_hand),
    ('scissors', '가위', Icons.content_cut),
  ];

  Future<void> _onChoose(String choice) async {
    if (_busy || _myChoiceSubmitted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _myChoiceSubmitted = true;
    });
    try {
      final res = await ref
          .read(battleServiceProvider)
          .finish(matchId: widget.matchId, choice: choice);
      if (!mounted) return;
      ref.invalidate(balancesProvider);
      if (res['ok'] == true && res['status'] != 'awaiting_opponent') {
        HapticFeedback.heavyImpact();
        setState(() => _finalResult = res);
      } else if (res['ok'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실패: ${res['reason']}')),
        );
        setState(() => _myChoiceSubmitted = false);
      }
      // awaiting_opponent면 polling이 자동 감지
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(battleMatchProvider(widget.matchId));
    final row = matchAsync.valueOrNull;

    // 매치 polling이 status='finished' 또는 'draw'를 감지하면 결과 표시
    if (_finalResult == null && row != null &&
        (row['status'] == 'finished' || row['status'] == 'draw')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 우리 finish 호출 안 했어도 표시 가능 (상대가 끝낸 경우)
        setState(() => _finalResult = {
          'ok': true,
          'status': row['status'],
          'opp_choice': row['challenger_id'] == row['winner_id']
              ? row['challenger_choice']
              : row['opponent_choice'],
          'my_choice': null,
          'winner': row['winner_id'] == null ? 'cpu'
              : 'opponent',
          'payout': 0,
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle — RPS'),
      ),
      body: _finalResult != null
          ? _buildResult(_finalResult!)
          : _buildPlay(row),
    );
  }

  Widget _buildPlay(Map<String, dynamic>? row) {
    final stake = (row?['stake_coin'] as int?) ?? 0;
    final vsCpu = row?['vs_cpu'] == true;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings,
                    size: 16, color: AppColors.brandYellow),
                const SizedBox(width: 4),
                Text('베팅 $stake 코인',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandRed)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: vsCpu
                        ? AppColors.textMuted.withValues(alpha: 0.2)
                        : AppColors.brandBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(vsCpu ? 'vs CPU' : 'vs 사용자',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: vsCpu
                              ? AppColors.textMuted
                              : AppColors.brandBlue)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_myChoiceSubmitted) ...[
            const CircularProgressIndicator(color: AppColors.brandRed),
            const SizedBox(height: 16),
            Text(
              vsCpu ? 'CPU 선택 중...' : '상대방 선택 대기 중...',
              style: GoogleFonts.notoSansKr(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ] else ...[
            Text(
              '바위·보·가위 중 하나를 선택',
              style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _choices
                  .map((c) => _ChoiceButton(
                        label: c.$2,
                        icon: c.$3,
                        onTap: () => _onChoose(c.$1),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> res) {
    final status = res['status'] as String? ?? '';
    final winner = res['winner'] as String?;
    final payout = (res['payout'] as int?) ?? 0;
    final myChoice = res['my_choice'] as String?;
    final oppChoice = res['opp_choice'] as String?;
    final refund = (res['refund'] as int?) ?? 0;

    String headline;
    Color color;
    IconData icon;
    if (status == 'draw') {
      headline = '무승부 — $refund 코인 환불';
      color = AppColors.brandYellow;
      icon = Icons.balance;
    } else if (winner == 'me') {
      headline = '승리! +$payout 코인';
      color = AppColors.brandGreen;
      icon = Icons.emoji_events;
    } else if (winner == 'cpu') {
      headline = 'CPU 승 — 베팅 잃음';
      color = AppColors.brandRed;
      icon = Icons.computer;
    } else {
      headline = '패배 — 베팅 잃음';
      color = AppColors.brandRed;
      icon = Icons.sentiment_dissatisfied;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(headline,
                style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (myChoice != null && oppChoice != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChoiceLabel(label: '나', choice: myChoice),
                  const SizedBox(width: 20),
                  const Text('vs',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textMuted)),
                  const SizedBox(width: 20),
                  _ChoiceLabel(label: '상대', choice: oppChoice),
                ],
              ),
              const SizedBox(height: 32),
            ],
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('홈으로',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.pushReplacement('/battle'),
              child: const Text('다시 도전'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.brandRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.brandRed.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.brandRed),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandRed)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceLabel extends StatelessWidget {
  const _ChoiceLabel({required this.label, required this.choice});
  final String label;
  final String choice;

  static const _icons = <String, IconData>{
    'rock': Icons.back_hand,
    'paper': Icons.front_hand,
    'scissors': Icons.content_cut,
  };
  static const _names = <String, String>{
    'rock': '바위',
    'paper': '보',
    'scissors': '가위',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.notoSansKr(
                fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Icon(_icons[choice] ?? Icons.help,
            size: 36, color: AppColors.brandRed),
        const SizedBox(height: 2),
        Text(_names[choice] ?? choice,
            style: GoogleFonts.notoSansKr(
                fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
