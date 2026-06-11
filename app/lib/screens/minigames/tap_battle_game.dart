import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';

/// 서로 때리기 — 10초간 탭 연사 vs CPU. 승리 +15 코인, 패배 +3 코인.
class TapBattleGame extends ConsumerStatefulWidget {
  const TapBattleGame({super.key});

  @override
  ConsumerState<TapBattleGame> createState() => _TapBattleGameState();
}

class _TapBattleGameState extends ConsumerState<TapBattleGame> {
  static const Duration _gameDuration = Duration(seconds: 10);
  Timer? _tickTimer;
  Timer? _cpuTimer;
  Duration _remaining = _gameDuration;
  int _userTaps = 0;
  int _cpuTaps = 0;
  bool _running = false;
  String? _result;

  void _start() {
    setState(() {
      _userTaps = 0;
      _cpuTaps = 0;
      _remaining = _gameDuration;
      _running = true;
      _result = null;
    });
    // CPU 자동 탭 — 약간 랜덤하게 (200~350ms 마다 1회)
    _cpuTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (Random().nextInt(3) == 0) {
        setState(() => _cpuTaps++);
      }
    });
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_remaining <= Duration.zero) {
        _stop();
        return;
      }
      setState(() => _remaining -= const Duration(milliseconds: 100));
    });
  }

  void _stop() {
    _tickTimer?.cancel();
    _cpuTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _running = false;
      if (_userTaps > _cpuTaps) {
        _result = 'win';
      } else if (_userTaps < _cpuTaps) {
        _result = 'lose';
      } else {
        _result = 'draw';
      }
    });
    if (_result == 'win') {
      _awardCoin(15, isWin: true);
    } else if (_result == 'lose') {
      _awardCoin(3, isWin: false);
    }
  }

  Future<void> _awardCoin(int p, {required bool isWin}) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final res = await ref.read(currencyServiceProvider).grantCoin(
          userId: uid,
          delta: p,
          reason: isWin ? 'minigame_win' : 'minigame_lose',
          sourceId: 'tap_battle',
        );
    if (res['ok'] != true) return;
    ref.invalidate(balancesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isWin ? '🪙 +$p 코인!' : '+$p 코인 (참가상)'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.brandGreen,
        ),
      );
    }
  }

  void _tap() {
    if (!_running) return;
    HapticFeedback.selectionClick();
    setState(() => _userTaps++);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _cpuTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = (_remaining.inMilliseconds / 1000).ceil();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('서로 때리기',
            style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _scoreCard('나', _userTaps, AppColors.brandBlue)),
                const SizedBox(width: 8),
                _vsBadge(secs),
                const SizedBox(width: 8),
                Expanded(child: _scoreCard('CPU', _cpuTaps, AppColors.brandRed)),
              ],
            ),
            const SizedBox(height: 24),
            if (_result != null) _resultBanner(),
            const SizedBox(height: 24),
            Expanded(
              child: GestureDetector(
                onTap: _running ? _tap : _start,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _running
                          ? [
                              AppColors.brandRed.withValues(alpha: 0.3),
                              AppColors.brandOrange.withValues(alpha: 0.3),
                            ]
                          : [
                              AppColors.brandYellow.withValues(alpha: 0.2),
                              AppColors.brandYellow.withValues(alpha: 0.05),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (_running
                                ? AppColors.brandRed
                                : AppColors.brandYellow)
                            .withValues(alpha: 0.5),
                        width: 2,),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _running ? Icons.touch_app : Icons.play_circle_outline,
                        size: 80,
                        color: _running
                            ? AppColors.brandRed
                            : AppColors.brandYellow,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _running ? '연속으로 탭!' : (_result != null ? '다시 시작' : '시작'),
                        style: GoogleFonts.notoSansKr(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _running
                                ? AppColors.brandRed
                                : AppColors.brandYellow,),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(String label, int v, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: AppColors.textMuted,),),
          const SizedBox(height: 4),
          Text('$v',
              style: GoogleFonts.notoSansKr(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,),),
        ],
      ),
    );
  }

  Widget _vsBadge(int secs) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('VS',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,),),
          const SizedBox(height: 4),
          Text('${secs}s',
              style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandYellow,),),
        ],
      ),
    );
  }

  Widget _resultBanner() {
    final color = switch (_result) {
      'win' => AppColors.brandGreen,
      'lose' => AppColors.brandRed,
      _ => AppColors.brandYellow,
    };
    final label = switch (_result) {
      'win' => '🎉 승리!',
      'lose' => '😢 패배',
      _ => '🤝 무승부',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w900,),),
    );
  }
}
