import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/health_provider.dart';

/// 홈 "걸음수로 코인 적립" 카드 (트랙 E, Step 13).
/// 1000걸음 = 10 코인, 일 최대 50 코인.
/// 권한 미허용 시: 권한 요청 CTA만 표시. 허용 후엔 적립 버튼.
class WalkRewardCard extends ConsumerStatefulWidget {
  const WalkRewardCard({super.key});

  @override
  ConsumerState<WalkRewardCard> createState() => _WalkRewardCardState();
}

class _WalkRewardCardState extends ConsumerState<WalkRewardCard> {
  bool? _hasPermission;
  bool _busy = false;
  int? _lastSteps;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkPermission);
  }

  Future<void> _checkPermission() async {
    final ok = await ref.read(healthServiceProvider).hasPermission();
    if (!mounted) return;
    setState(() => _hasPermission = ok);
    if (ok) {
      // 권한 있으면 백그라운드로 걸음수 미리 가져옴 (UI 표시용)
      final s = await ref.read(healthServiceProvider).todaySteps();
      if (mounted) setState(() => _lastSteps = s);
    }
  }

  Future<void> _onRequestPermission() async {
    HapticFeedback.selectionClick();
    final ok = await ref.read(healthServiceProvider).requestPermission();
    if (!mounted) return;
    setState(() => _hasPermission = ok);
    if (ok) {
      final s = await ref.read(healthServiceProvider).todaySteps();
      if (mounted) setState(() => _lastSteps = s);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('걸음수 권한이 필요합니다 (설정에서 허용)')),
      );
    }
  }

  Future<void> _onClaim() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref.read(healthServiceProvider).claim();
      if (!mounted) return;
      _lastSteps = res['client_steps'] as int? ?? _lastSteps;
      final ok = res['ok'] == true;
      if (ok) {
        HapticFeedback.heavyImpact();
        ref.invalidate(balancesProvider);
        ref.invalidate(todayWalkStatusProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🪙 +${res['delta']} 코인! '
                '(오늘 ${res['steps']}걸음, 누적 ${res['eligible_coin']}/50)'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_reasonMessage(res))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _reasonMessage(Map<String, dynamic> res) {
    final reason = res['reason']?.toString() ?? 'unknown';
    switch (reason) {
      case 'not_enough_steps':
        final s = res['client_steps'] ?? 0;
        return '1000걸음부터 적립돼요 (현재 $s걸음)';
      case 'already_at_cap':
        return '오늘 걸음 보상은 모두 받았어요 (50/50)';
      case 'auth_required':
        return '로그인이 필요합니다';
      case 'grant_failed':
        return '일일 코인 캡 도달';
      default:
        return '실패: $reason';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(todayWalkStatusProvider);
    final status = statusAsync.valueOrNull;
    final coinsAwarded = (status?['coins_awarded'] as int?) ?? 0;
    final remaining = (status?['remaining'] as int?) ?? 50;
    final atCap = remaining <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk,
              size: 32, color: AppColors.brandGreen,),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atCap ? '오늘 걸음 보상 완료' : '걸음수로 코인 적립',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasPermission == false
                      ? '권한 허용 후 1000걸음당 +10 코인'
                      : _lastSteps != null
                          ? '오늘 $_lastSteps걸음 · 적립 $coinsAwarded/50'
                          : '1000걸음당 +10 · 일 최대 50',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildAction(atCap),
        ],
      ),
    );
  }

  Widget _buildAction(bool atCap) {
    if (_hasPermission == null) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_hasPermission == false) {
      return ElevatedButton(
        onPressed: _onRequestPermission,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text('허용',
            style:
                GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w800),),
      );
    }
    return ElevatedButton(
      onPressed: atCap || _busy ? null : _onClaim,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            atCap ? AppColors.bgElevated : AppColors.brandGreen,
        foregroundColor:
            atCap ? AppColors.textMuted : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              atCap ? '완료' : '적립',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
