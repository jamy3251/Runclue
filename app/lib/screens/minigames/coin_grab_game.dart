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

/// 동전줍기 — 15초간 화면 동전 탭 경쟁. 점수의 절반 (max 15) 코인 적립.
class CoinGrabGame extends ConsumerStatefulWidget {
  const CoinGrabGame({super.key});

  @override
  ConsumerState<CoinGrabGame> createState() => _CoinGrabGameState();
}

class _Coin {
  final Offset pos;
  final int value;
  final double size;
  _Coin(this.pos, this.value, this.size);
}

class _CoinGrabGameState extends ConsumerState<CoinGrabGame> {
  static const Duration _gameDuration = Duration(seconds: 15);
  Timer? _spawnTimer;
  Timer? _tickTimer;
  final List<_Coin> _coins = [];
  int _score = 0;
  int _highScore = 0;
  Duration _remaining = _gameDuration;
  bool _running = false;

  final _rng = Random();

  void _start() {
    setState(() {
      _coins.clear();
      _score = 0;
      _remaining = _gameDuration;
      _running = true;
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      _spawnCoin();
    });
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_remaining <= Duration.zero) {
        _stop();
        return;
      }
      setState(() {
        _remaining -= const Duration(milliseconds: 200);
      });
    });
  }

  void _stop() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    setState(() {
      _running = false;
      if (_score > _highScore) _highScore = _score;
    });
    HapticFeedback.heavyImpact();
    // 점수의 절반을 코인으로 (점수 30 = 15코인, max 15 — 단발 ±100 캡 안)
    final awarded = (_score / 2).floor().clamp(0, 15);
    if (awarded > 0) {
      _awardCoin(awarded, isWin: _score >= 10);
    } else {
      _awardCoin(3, isWin: false); // 참가상
    }
  }

  Future<void> _awardCoin(int p, {required bool isWin}) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final res = await ref.read(currencyServiceProvider).grantCoin(
          userId: uid,
          delta: p,
          reason: isWin ? 'minigame_win' : 'minigame_lose',
          sourceId: 'coin_grab',
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

  void _spawnCoin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    const cs = 56.0;
    setState(() {
      _coins.add(_Coin(
        Offset(_rng.nextDouble() * (size.width - cs - 16) + 8,
            _rng.nextDouble() * (size.height - cs - 200) + 120,),
        _rng.nextInt(10) > 7 ? 5 : 1,
        cs,
      ),);
    });
    // 2초 후 자동 제거
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _coins.isNotEmpty) {
        setState(() => _coins.removeWhere((c) => identical(c, _coins.first)));
      }
    });
  }

  void _grab(_Coin c) {
    HapticFeedback.lightImpact();
    setState(() {
      _coins.remove(c);
      _score += c.value;
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
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
        title: Text('동전 줍기',
            style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,),),
      ),
      body: Stack(
        children: [
          // Background HUD
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _hud('점수', '$_score',
                          AppColors.brandYellow, Icons.monetization_on,),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _hud('남은 시간', '${secs}s',
                          AppColors.brandRed, Icons.timer,),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _hud('최고', '$_highScore',
                          AppColors.brandPurple, Icons.emoji_events,),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!_running)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14,),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),),
                    ),
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _score > 0 ? '다시 시작' : '시작',
                      style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.w900, fontSize: 16,),
                    ),
                  ),
              ],
            ),
          ),
          // Coins
          ..._coins.map((c) => Positioned(
                left: c.pos.dx,
                top: c.pos.dy,
                child: GestureDetector(
                  onTap: () => _grab(c),
                  child: Container(
                    width: c.size,
                    height: c.size,
                    decoration: BoxDecoration(
                      gradient: c.value >= 5
                          ? const LinearGradient(colors: [
                              AppColors.brandRed,
                              AppColors.brandOrange,
                            ],)
                          : const LinearGradient(colors: [
                              AppColors.brandYellow,
                              AppColors.brandOrange,
                            ],),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.brandYellow.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.value >= 5 ? '+5' : '+1',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,),
                    ),
                  ),
                ),
              ),),
        ],
      ),
    );
  }

  Widget _hud(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,),),
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 10, color: AppColors.textMuted,),),
        ],
      ),
    );
  }
}
