import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';

/// 가위바위보 vs CPU. 승리 시 +5p 적립.
class RpsGame extends ConsumerStatefulWidget {
  const RpsGame({super.key});

  @override
  ConsumerState<RpsGame> createState() => _RpsGameState();
}

enum _Choice { rock, paper, scissors }

extension on _Choice {
  String get emoji => switch (this) {
        _Choice.rock => '✊',
        _Choice.paper => '✋',
        _Choice.scissors => '✌️',
      };
}

class _RpsGameState extends ConsumerState<RpsGame> {
  _Choice? _user;
  _Choice? _cpu;
  String? _result;
  int _wins = 0, _losses = 0, _draws = 0;

  void _play(_Choice c) {
    HapticFeedback.lightImpact();
    final cpu = _Choice.values[Random().nextInt(3)];
    final result = _judge(c, cpu);
    setState(() {
      _user = c;
      _cpu = cpu;
      _result = result;
      if (result == 'win') {
        _wins++;
      } else if (result == 'lose') {
        _losses++;
      } else {
        _draws++;
      }
    });
    if (result == 'win') {
      HapticFeedback.heavyImpact();
      _awardPoints(5);
    }
  }

  Future<void> _awardPoints(int p) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(pointsServiceProvider).add(
          userId: uid,
          delta: p,
          reason: 'minigame:rps:win',
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

  String _judge(_Choice u, _Choice c) {
    if (u == c) return 'draw';
    if ((u == _Choice.rock && c == _Choice.scissors) ||
        (u == _Choice.paper && c == _Choice.rock) ||
        (u == _Choice.scissors && c == _Choice.paper)) return 'win';
    return 'lose';
  }

  Color get _resultColor => switch (_result) {
        'win' => AppColors.brandGreen,
        'lose' => AppColors.brandRed,
        'draw' => AppColors.brandYellow,
        _ => AppColors.textMuted,
      };

  String get _resultLabel => switch (_result) {
        'win' => '🎉 승리!',
        'lose' => '😢 패배',
        'draw' => '🤝 무승부',
        _ => '선택해주세요',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('가위바위보',
            style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score row
            Row(
              children: [
                _scoreBox('승', _wins, AppColors.brandGreen),
                const SizedBox(width: 8),
                _scoreBox('패', _losses, AppColors.brandRed),
                const SizedBox(width: 8),
                _scoreBox('무', _draws, AppColors.brandYellow),
              ],
            ),
            const SizedBox(height: 32),
            // CPU display
            Column(
              children: [
                Text('CPU',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.borderDefault, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _cpu?.emoji ?? '❓',
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Result
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _resultColor.withValues(alpha: 0.4)),
              ),
              child: Text(_resultLabel,
                  style: TextStyle(
                      color: _resultColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 24),
            // User choice
            Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.brandBlue.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _user?.emoji ?? '?',
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
                const SizedBox(height: 6),
                Text('나',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            const Spacer(),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _Choice.values
                  .map((c) => _choiceBtn(c))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int v, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text('$v',
                style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _choiceBtn(_Choice c) {
    return GestureDetector(
      onTap: () => _play(c),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.brandYellow.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(c.emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}
