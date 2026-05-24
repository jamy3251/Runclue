import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/season_provider.dart';

/// 주간 시즌 리더보드 화면 (#16).
/// Top 10 다이아 분배 안내 + 내 순위 표시 + 보상 내역.
class SeasonLeaderboardScreen extends ConsumerWidget {
  const SeasonLeaderboardScreen({super.key});

  static const _payout = <int, int>{
    1: 500,
    2: 300,
    3: 200,
    4: 100,
    5: 100,
    6: 50,
    7: 50,
    8: 50,
    9: 50,
    10: 50,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final boardAsync = ref.watch(seasonLeaderboardProvider);
    final myRewardsAsync = ref.watch(mySeasonRewardsProvider);
    final myId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('주간 시즌')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentSeasonProvider);
          ref.invalidate(seasonLeaderboardProvider);
          ref.invalidate(mySeasonRewardsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            _SeasonHeader(seasonAsync: seasonAsync),
            const SizedBox(height: 12),
            const _RewardLegend(),
            const SizedBox(height: 16),
            _SectionLabel('리더보드 Top 100'),
            const SizedBox(height: 6),
            boardAsync.when(
              loading: () =>
                  const Center(child: Padding(padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator())),
              error: (e, _) => Text('불러올 수 없습니다: $e'),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '아직 점수를 얻은 사용자가 없어요.\n클루를 완료하거나 코인을 적립해서 1등이 되어보세요.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children:
                      items.map((row) => _LeaderRow(row: row, myId: myId)).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionLabel('내 시즌 보상 내역'),
            const SizedBox(height: 6),
            myRewardsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    '아직 받은 시즌 보상이 없어요.',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textMuted),
                  );
                }
                return Column(
                  children: items.map((r) => _RewardRow(row: r)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({required this.seasonAsync});
  final AsyncValue<Map<String, dynamic>?> seasonAsync;

  @override
  Widget build(BuildContext context) {
    final s = seasonAsync.valueOrNull;
    if (s == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('시즌 정보를 불러오는 중...'),
      );
    }
    final slug = s['slug'] as String? ?? '';
    final startAt = DateTime.tryParse(s['start_at'] as String? ?? '');
    final endAt = DateTime.tryParse(s['end_at'] as String? ?? '');
    final ends = endAt != null
        ? timeago.format(endAt, locale: 'ko', allowFromNow: true)
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandYellow.withValues(alpha: 0.16),
            AppColors.brandBlue.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.brandYellow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  size: 22, color: AppColors.brandYellow),
              const SizedBox(width: 6),
              Text(
                'Season $slug',
                style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandYellow),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '점수 = 완료 클루 × 100 + 적립 코인 합',
            style: GoogleFonts.notoSansKr(
                fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            '$ends 종료 → Top 10에 다이아 자동 지급',
            style: GoogleFonts.notoSansKr(
                fontSize: 11, color: AppColors.textMuted),
          ),
          if (startAt != null && endAt != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress(startAt, endAt),
                minHeight: 5,
                backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.brandYellow),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static double _progress(DateTime start, DateTime end) {
    final now = DateTime.now();
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class _RewardLegend extends StatelessWidget {
  const _RewardLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  size: 14, color: AppColors.brandBlue),
              const SizedBox(width: 4),
              Text('다이아 보상 (Top 10)',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: const [
              _RewardChip(rank: 1, diamond: 500),
              _RewardChip(rank: 2, diamond: 300),
              _RewardChip(rank: 3, diamond: 200),
              _RewardChip(rank: 4, diamond: 100),
              _RewardChip(rank: 5, diamond: 100),
              _RewardChip(rank: 6, diamond: 50, isRange: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.rank,
    required this.diamond,
    this.isRange = false,
  });
  final int rank;
  final int diamond;
  final bool isRange;

  @override
  Widget build(BuildContext context) {
    final label = isRange ? '6~10등' : '$rank등';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label • $diamond💎',
          style: GoogleFonts.notoSansKr(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary));
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.row, required this.myId});
  final Map<String, dynamic> row;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final userId = row['user_id'] as String?;
    final rank = (row['rank'] as int?) ?? 0;
    final nickname = row['nickname'] as String? ?? '익명';
    final avatar = row['avatar_url'] as String?;
    final completed = (row['completed'] as int?) ?? 0;
    final coin = (row['coin_earned'] as int?) ?? 0;
    final score = (row['score'] as int?) ?? 0;
    final isMe = userId != null && userId == myId;
    final isTop3 = rank <= 3;
    final isTop10 = rank <= 10;
    final diamond = SeasonLeaderboardScreen._payout[rank];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.brandYellow.withValues(alpha: 0.10)
            : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? AppColors.brandYellow
              : isTop3
                  ? AppColors.brandBlue.withValues(alpha: 0.3)
                  : AppColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              _rankBadge(rank),
              style: GoogleFonts.notoSansKr(
                fontSize: isTop3 ? 16 : 13,
                fontWeight: FontWeight.w900,
                color: isTop3 ? AppColors.brandYellow : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
            child: avatar == null
                ? const Icon(Icons.person, size: 16, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isMe
                                  ? AppColors.brandYellow
                                  : AppColors.textPrimary)),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Text('(나)',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              color: AppColors.brandYellow)),
                    ],
                  ],
                ),
                Text('${completed}개 클루 · ${coin} 코인',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              if (isTop10 && diamond != null)
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        size: 10, color: AppColors.brandBlue),
                    const SizedBox(width: 2),
                    Text('+$diamond',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _rankBadge(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '$rank';
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final season = (row['seasons'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final slug = season['slug'] as String? ?? '';
    final rank = (row['rank'] as int?) ?? 0;
    final score = (row['score'] as int?) ?? 0;
    final reward = (row['reward_diamond'] as int?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Text('S $slug',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
          const SizedBox(width: 10),
          Text('$rank등',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandYellow)),
          const SizedBox(width: 10),
          Text('점수 $score',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: AppColors.textMuted)),
          const Spacer(),
          const Icon(Icons.diamond, size: 14, color: AppColors.brandBlue),
          const SizedBox(width: 3),
          Text('+$reward',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue)),
        ],
      ),
    );
  }
}
