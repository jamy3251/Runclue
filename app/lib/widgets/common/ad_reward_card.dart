import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/ads_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/quest_provider.dart';

/// "광고 보고 +20 코인" 카드 (트랙 C).
/// 일일 5회 캡 — UI에 X/5 표시. 사장 모드는 호출 측에서 숨김 처리.
class AdRewardCard extends ConsumerStatefulWidget {
  const AdRewardCard({super.key, this.compact = false});

  /// true면 작은 막대형(홈), false면 큰 카드(보상 화면).
  final bool compact;

  @override
  ConsumerState<AdRewardCard> createState() => _AdRewardCardState();
}

class _AdRewardCardState extends ConsumerState<AdRewardCard> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 광고 SDK + 첫 광고 preload
    Future.microtask(
      () => ref.read(adsServiceProvider).init(),
    );
  }

  Future<void> _onTap() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref.read(adsServiceProvider).showAndClaim();
      if (!mounted) return;
      final ok = res['ok'] == true;
      if (ok) {
        HapticFeedback.heavyImpact();
        ref.invalidate(balancesProvider);
        ref.invalidate(todayAdCountProvider);
        ref.invalidate(todayQuestStatusProvider); // 광고는 quest 진행에는 영향 X지만 일관 갱신
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🪙 +${res['reward_coin']} 코인! '
                '(오늘 ${res['today_count']}/${res['cap']})'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final reason = res['reason']?.toString() ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_reasonMessage(reason))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _reasonMessage(String reason) {
    switch (reason) {
      case 'daily_cap_reached':
        return '오늘 광고는 모두 보셨어요 (5/5)';
      case 'ad_not_ready':
        return '광고 준비 중 — 잠시 후 다시 시도';
      case 'not_completed':
        return '광고를 끝까지 봐야 보상이 지급됩니다';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '실패: $reason';
    }
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(todayAdCountProvider);
    final m = countAsync.valueOrNull;
    final remaining = (m?['remaining'] as int?) ?? 5;
    final cap = (m?['cap'] as int?) ?? 5;
    final disabled = remaining <= 0;

    if (widget.compact) {
      return _CompactRow(
        remaining: remaining,
        cap: cap,
        busy: _busy,
        disabled: disabled,
        onTap: _onTap,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : LinearGradient(
                colors: [
                  AppColors.brandYellow.withValues(alpha: 0.12),
                  AppColors.brandBlue.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: disabled ? AppColors.bgSurface : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: disabled
              ? AppColors.borderDefault
              : AppColors.brandYellow.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_display,
              size: 32, color: AppColors.brandBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disabled ? '오늘 광고는 모두 보셨어요' : '광고 보고 코인 +20',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disabled ? '내일 또 받을 수 있어요' : '오늘 ${cap - remaining}/$cap 시청',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: disabled || _busy ? null : _onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    disabled ? '완료' : '보기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.remaining,
    required this.cap,
    required this.busy,
    required this.disabled,
    required this.onTap,
  });

  final int remaining;
  final int cap;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled || busy ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_display,
                size: 16, color: AppColors.brandBlue),
            const SizedBox(width: 6),
            Text(
              disabled
                  ? '광고 보상 완료'
                  : '광고 +20 코인 (${cap - remaining}/$cap)',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    disabled ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
