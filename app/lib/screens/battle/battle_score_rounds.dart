import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

/// Battle용 점수 라운드 위젯 — 솔로 미니게임과 달리 코인을 직접 지급하지 않고
/// 라운드 종료 시 점수를 콜백으로 넘긴다 (battle_finish RPC가 판정·분배).

/// 서로 때리기 배틀 라운드: 10초 탭 연사 → 탭 수 제출.
class BattleTapRound extends StatefulWidget {
  const BattleTapRound({super.key, required this.onDone});
  final void Function(int score) onDone;

  @override
  State<BattleTapRound> createState() => _BattleTapRoundState();
}

class _BattleTapRoundState extends State<BattleTapRound> {
  static const Duration _gameDuration = Duration(seconds: 10);
  Timer? _tickTimer;
  Duration _remaining = _gameDuration;
  int _taps = 0;
  bool _running = false;
  bool _done = false;

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _taps = 0;
      _remaining = _gameDuration;
      _running = true;
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
    if (_done) return;
    _done = true;
    HapticFeedback.heavyImpact();
    setState(() => _running = false);
    widget.onDone(_taps.clamp(0, 150));
  }

  void _tap() {
    if (!_running) return;
    HapticFeedback.selectionClick();
    setState(() => _taps++);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = (_remaining.inMilliseconds / 1000).ceil();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _hudChip('내 탭', '$_taps', AppColors.brandBlue),
            const SizedBox(width: 12),
            _hudChip('남은 시간', '${secs}s', AppColors.brandRed),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GestureDetector(
            onTap: _running ? _tap : (_done ? null : _start),
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
                    color: (_running ? AppColors.brandRed : AppColors.brandYellow)
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
                    color: _running ? AppColors.brandRed : AppColors.brandYellow,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _done
                        ? '제출 완료'
                        : (_running ? '연속으로 탭!' : '탭해서 시작 (10초)'),
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
    );
  }

  Widget _hudChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.notoSansKr(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color,),),
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 10, color: AppColors.textMuted,),),
        ],
      ),
    );
  }
}

/// 동전 줍기 배틀 라운드: 15초간 화면 동전 탭 → 점수 제출.
class BattleCoinRound extends StatefulWidget {
  const BattleCoinRound({super.key, required this.onDone});
  final void Function(int score) onDone;

  @override
  State<BattleCoinRound> createState() => _BattleCoinRoundState();
}

class _CoinDrop {
  final Offset pos;
  final int value;
  _CoinDrop(this.pos, this.value);
}

class _BattleCoinRoundState extends State<BattleCoinRound> {
  static const Duration _gameDuration = Duration(seconds: 15);
  Timer? _spawnTimer;
  Timer? _tickTimer;
  final List<_CoinDrop> _coins = [];
  int _score = 0;
  Duration _remaining = _gameDuration;
  bool _running = false;
  bool _done = false;
  final _rng = Random();

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _coins.clear();
      _score = 0;
      _remaining = _gameDuration;
      _running = true;
    });
    _spawnTimer = Timer.periodic(
        const Duration(milliseconds: 350), (_) => _spawnCoin(),);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_remaining <= Duration.zero) {
        _stop();
        return;
      }
      setState(() => _remaining -= const Duration(milliseconds: 200));
    });
  }

  void _stop() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    if (_done) return;
    _done = true;
    HapticFeedback.heavyImpact();
    setState(() => _running = false);
    widget.onDone(_score.clamp(0, 200));
  }

  void _spawnCoin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    const cs = 56.0;
    if (size.width < cs + 32 || size.height < cs + 100) return;
    setState(() {
      _coins.add(_CoinDrop(
        Offset(_rng.nextDouble() * (size.width - cs - 16) + 8,
            _rng.nextDouble() * (size.height - cs - 80) + 64,),
        _rng.nextInt(10) > 7 ? 5 : 1,
      ),);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _coins.isNotEmpty) {
        setState(() => _coins.removeAt(0));
      }
    });
  }

  void _grab(_CoinDrop c) {
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
    return Stack(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _hudChip('점수', '$_score', AppColors.brandYellow),
                const SizedBox(width: 12),
                _hudChip('남은 시간', '${secs}s', AppColors.brandRed),
              ],
            ),
            const SizedBox(height: 16),
            if (!_running && !_done)
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
                label: Text('시작 (15초)',
                    style: GoogleFonts.notoSansKr(
                        fontWeight: FontWeight.w900, fontSize: 16,),),
              ),
            if (_done)
              Text('제출 완료',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandGreen,),),
          ],
        ),
        ..._coins.map((c) => Positioned(
              left: c.pos.dx,
              top: c.pos.dy,
              child: GestureDetector(
                onTap: () => _grab(c),
                child: Container(
                  width: 56,
                  height: 56,
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
                        color: AppColors.brandYellow.withValues(alpha: 0.4),
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
    );
  }

  Widget _hudChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.notoSansKr(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color,),),
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 10, color: AppColors.textMuted,),),
        ],
      ),
    );
  }
}
