import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/season_provider.dart';

/// 홈 화면용 시즌 배너 — 내 순위 + 종료까지 시간 + Top10 안내.
class SeasonBannerCard extends ConsumerWidget {
  const SeasonBannerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final boardAsync = ref.watch(seasonLeaderboardProvider);
    final myId = ref.watch(currentUserIdProvider);

    return seasonAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        final slug = s['slug'] as String? ?? '';
        final endAt = DateTime.tryParse(s['end_at'] as String? ?? '');
        final ends = endAt != null
            ? timeago.format(endAt, locale: 'ko', allowFromNow: true)
            : '?';

        final board = boardAsync.valueOrNull ?? const [];
        int? myRank;
        int? myScore;
        for (final row in board) {
          if (row['user_id'] == myId) {
            myRank = row['rank'] as int?;
            myScore = row['score'] as int?;
            break;
          }
        }

        return GestureDetector(
          onTap: () => context.push('/seasons'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandYellow.withValues(alpha: 0.16),
                  AppColors.brandBlue.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.brandYellow.withValues(alpha: 0.35),),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    size: 28, color: AppColors.brandYellow,),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Season $slug · Top 10 다이아 분배',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,),),
                      const SizedBox(height: 2),
                      Text(
                        myRank != null
                            ? '내 순위 $myRank등 · 점수 $myScore · $ends 종료'
                            : '아직 점수 0 · $ends 종료',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 11, color: AppColors.textMuted,),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textMuted,),
              ],
            ),
          ),
        );
      },
    );
  }
}
