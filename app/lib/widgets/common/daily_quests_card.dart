import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/quest_provider.dart';

/// 홈 화면용 "오늘의 미션" 카드.
/// 4개 quest를 chip 리스트로 표시 + 각각 받기/완료 상태.
///
/// 디자인 원칙: 컴팩트(세로 ~180px), 한눈에 진행도 + 출석 streak 강조.
class DailyQuestsCard extends ConsumerWidget {
  const DailyQuestsCard({super.key});

  static const _quests = <(String, String, String, IconData)>[
    // (key, label, reward_label, icon)
    ('attendance', '출석', '+5', Icons.event_available),
    ('first_clue', '클루 완료', '+20', Icons.flag),
    ('first_comment', '커뮤니티 댓글', '+20', Icons.chat_bubble),
    ('first_minigame', '미니게임 플레이', '+10', Icons.sports_esports),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayQuestStatusProvider);

    return async.when(
      loading: () => const SizedBox(height: 180),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data['ok'] != true) return const SizedBox.shrink();
        final streak = (data['attendance_streak'] as int?) ?? 0;
        final claimed = (data['claimed'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final progress =
            (data['progress'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.brandYellow, size: 20,),
                  const SizedBox(width: 6),
                  Text(
                    '오늘의 미션',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4,),
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔥 출석 $streak일',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._quests.map((q) {
                final key = q.$1;
                final label = q.$2;
                final reward = q.$3;
                final icon = q.$4;
                final isClaimed = claimed.containsKey(key);
                final qualified = _isQualified(key, progress);
                return _QuestRow(
                  icon: icon,
                  label: label,
                  reward: reward,
                  isClaimed: isClaimed,
                  qualified: qualified,
                  onClaim: isClaimed || !qualified
                      ? null
                      : () => _onClaim(context, ref, key),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  static bool _isQualified(String key, Map<String, dynamic> progress) {
    switch (key) {
      case 'attendance':
        return true;
      case 'first_clue':
        return ((progress['first_clue'] as int?) ?? 0) >= 1;
      case 'first_comment':
        return ((progress['first_comment'] as int?) ?? 0) >= 1;
      case 'first_minigame':
        return ((progress['first_minigame'] as int?) ?? 0) >= 1;
      default:
        return false;
    }
  }

  Future<void> _onClaim(
      BuildContext context, WidgetRef ref, String key,) async {
    HapticFeedback.mediumImpact();
    final res = await ref.read(questServiceProvider).claim(key);
    if (!context.mounted) return;
    final ok = res['ok'] == true;
    if (ok) {
      HapticFeedback.heavyImpact();
      ref.invalidate(todayQuestStatusProvider);
      ref.invalidate(balancesProvider);
      final reward = res['reward_coin'] ?? 0;
      final bonus = (res['bonus_coin'] as int?) ?? 0;
      final txt = bonus > 0
          ? '🪙 +$reward + 🎉 streak 보너스 +$bonus'
          : '🪙 +$reward 코인!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txt),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.brandGreen,
        ),
      );
    } else {
      final reason = res['reason']?.toString() ?? 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_reasonMessage(reason))),
      );
    }
  }

  static String _reasonMessage(String reason) {
    switch (reason) {
      case 'already_claimed':
        return '오늘 이미 받았어요';
      case 'not_qualified':
        return '조건을 먼저 달성해 주세요';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '받기 실패: $reason';
    }
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.label,
    required this.reward,
    required this.isClaimed,
    required this.qualified,
    required this.onClaim,
  });

  final IconData icon;
  final String label;
  final String reward;
  final bool isClaimed;
  final bool qualified;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final dimColor =
        isClaimed ? AppColors.textMuted : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: dimColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: dimColor,
                fontWeight: FontWeight.w600,
                decoration: isClaimed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            reward,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isClaimed ? AppColors.textMuted : AppColors.brandYellow,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: isClaimed
                    ? AppColors.bgElevated
                    : qualified
                        ? AppColors.brandGreen
                        : AppColors.bgElevated,
                foregroundColor: isClaimed
                    ? AppColors.textMuted
                    : qualified
                        ? Colors.white
                        : AppColors.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isClaimed ? '완료' : qualified ? '받기' : '대기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
