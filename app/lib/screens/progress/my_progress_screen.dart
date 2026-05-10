import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/gradient_scaffold.dart';
import '../../providers/participation_provider.dart';
import '../../widgets/stats/ai_provocation_banner.dart';
import '../../widgets/stats/streak_calendar.dart';
import '../../widgets/stats/fun_stats_grid.dart';
import '../../widgets/common/badge_chip.dart';

/// Screen 05 — 나의 클루 진행도 (MyProgress)
/// 2탭: 크루 랭킹 | 나의 기록
class MyProgressScreen extends ConsumerStatefulWidget {
  const MyProgressScreen({super.key});

  @override
  ConsumerState<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends ConsumerState<MyProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('나의 진행도',
            style: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900),
              unselectedLabelStyle: AppTextStyles.label,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 16), text: '크루'),
                Tab(icon: Icon(Icons.star, size: 16), text: '나의 기록'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _CrewTab(),
                _MyRecordTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 크루 랭킹 탭 ───
class _CrewTab extends ConsumerWidget {
  const _CrewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(weeklyRankingProvider);
    final myProfileAsync = ref.watch(myProfileProvider);

    return rankingAsync.when(
      data: (rankings) {
        final myNickname = myProfileAsync.valueOrNull?['nickname'] ?? '';
        final myPoints = myProfileAsync.valueOrNull?['total_points'] ?? 0;

        // Find my rank
        int myRank = 0;
        for (int i = 0; i < rankings.length; i++) {
          if (rankings[i]['nickname'] == myNickname) {
            myRank = i + 1;
            break;
          }
        }

        // Build provocation message
        String provocation;
        if (rankings.isNotEmpty && myRank > 1) {
          final leader = rankings[0];
          final gap = (leader['total_points'] ?? 0) - myPoints;
          provocation = '${leader['nickname']}님보다 $gap점 뒤져있어요. 오늘 따라잡을 수 있을까요?';
        } else if (myRank == 1) {
          provocation = '현재 1위! 이 기세를 유지하세요 🔥';
        } else {
          provocation = '미션을 클리어하고 랭킹에 이름을 올려보세요!';
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, 140),
          children: [
            AIProvocationBanner(message: provocation),
            const SizedBox(height: AppSpacing.lg),
            if (rankings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('아직 랭킹 데이터가 없어요',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              ...List.generate(rankings.length, (i) {
                final r = rankings[i];
                final isMe = r['nickname'] == myNickname;
                return _RankingTile(
                  rank: i + 1,
                  name: r['nickname'] ?? '유저${i + 1}',
                  points: r['total_points'] ?? 0,
                  avatarUrl: r['avatar_url'],
                  isMe: isMe,
                );
              }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandYellow),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('랭킹을 불러올 수 없습니다',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final String? avatarUrl;
  final bool isMe;

  const _RankingTile({
    required this.rank,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.isMe = false,
  });

  IconData get _rankIcon => switch (rank) {
    1 => Icons.emoji_events,
    2 => Icons.star,
    3 => Icons.bolt,
    _ => Icons.nightlight_round,
  };

  Color get _rankColor => switch (rank) {
    1 => AppColors.brandYellow,
    2 => const Color(0xFFE5E5E5),
    3 => const Color(0xFFCD7F32),
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.brandYellow.withValues(alpha: 0.06)
            : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isMe ? AppColors.brandYellow : AppColors.borderDefault,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_rankIcon, size: 20, color: _rankColor),
          const SizedBox(width: AppSpacing.md),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '나',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$points점',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.brandYellow,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 나의 기록 탭 ───
class _MyRecordTab extends ConsumerWidget {
  const _MyRecordTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfileAsync = ref.watch(myProfileProvider);
    final badgesAsync = ref.watch(myBadgesProvider);
    final participationsAsync = ref.watch(myParticipationsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, 140),
      children: [
        // Streak Calendar — calculate from participations
        participationsAsync.when(
          data: (participations) {
            final now = DateTime.now();
            final last7 = List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));
              return participations.any((p) {
                final completedAt = p['completed_at'];
                if (completedAt == null) return false;
                final date = DateTime.tryParse(completedAt.toString());
                if (date == null) return false;
                return date.year == day.year && date.month == day.month && date.day == day.day;
              });
            });
            // Count current streak
            int streak = 0;
            for (int i = last7.length - 1; i >= 0; i--) {
              if (last7[i]) {
                streak++;
              } else {
                break;
              }
            }
            return StreakCalendar(completedDays: last7, streakCount: streak);
          },
          loading: () => const StreakCalendar(
            completedDays: [false, false, false, false, false, false, false],
            streakCount: 0,
          ),
          error: (_, __) => const StreakCalendar(
            completedDays: [false, false, false, false, false, false, false],
            streakCount: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Fun Stats — from profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            '나의 활동 기록',
            style: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        myProfileAsync.when(
          data: (profile) {
            final points = profile?['total_points'] ?? 0;
            final completed = profile?['completed_clues'] ?? 0;
            return FunStatsGrid(
              stats: FunStat.defaults(
                distance: '${(completed * 1.8).toStringAsFixed(1)}km',
                earnings: '₩${_fmtNum(points)}',
                places: '$completed곳',
                time: '${(completed * 0.7).toStringAsFixed(1)}시간',
              ),
            );
          },
          loading: () => FunStatsGrid(
            stats: FunStat.defaults(
              distance: '...',
              earnings: '...',
              places: '...',
              time: '...',
            ),
          ),
          error: (_, __) => FunStatsGrid(
            stats: FunStat.defaults(
              distance: '-',
              earnings: '-',
              places: '-',
              time: '-',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Badges — from Supabase
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            '획득 배지',
            style: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        badgesAsync.when(
          data: (badges) {
            if (badges.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '아직 획득한 배지가 없어요. 미션을 클리어해보세요!',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: badges.map<Widget>((badge) {
                  return BadgeChip(
                    label: badge['type'] ?? '배지',
                    color: AppColors.brandYellow,
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.brandYellow),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('배지를 불러올 수 없습니다',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtNum(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}만';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}천';
    return n.toString();
  }
}
