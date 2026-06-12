import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/currency_balance_chip.dart';

/// 플레이 허브 — 흩어져 있던 게임 기능들의 단일 진입점 (IA 재정비).
/// 배틀(PvP 베팅) / 미니게임(솔로) / 주간 시즌 / 상점(기프티콘·다이아) / 루틴 / 퀘스트.
class PlayHubScreen extends ConsumerWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balancesProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        automaticallyImplyLeading: false,
        title: Text('플레이',
            style: GoogleFonts.blackHanSans(
                fontSize: 20, color: AppColors.textPrimary,),),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: CurrencyBalanceChips()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(balancesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 메인: PvP 배틀 (히어로 카드)
            _HeroCard(
              title: 'PvP 베팅 대전',
              subtitle: '코인을 걸고 1:1 미니게임 — 이기면 ×1.9\n'
                  '가위바위보 · 서로 때리기 · 동전 줍기',
              icon: Icons.sports_kabaddi,
              colors: const [AppColors.brandRed, AppColors.brandOrange],
              route: '/battle',
              badge: balances != null && balances.coin >= 10
                  ? '보유 ${balances.coin}코인'
                  : null,
            ),
            const SizedBox(height: 12),

            // 2열 그리드: 나머지 게임 기능
            const Row(
              children: [
                Expanded(
                  child: _HubTile(
                    title: '미니게임',
                    subtitle: '무료 연습 + 코인',
                    icon: Icons.videogame_asset,
                    color: AppColors.brandPurple,
                    route: '/minigames',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HubTile(
                    title: '주간 시즌',
                    subtitle: 'Top 10 다이아',
                    icon: Icons.military_tech,
                    color: AppColors.brandYellow,
                    route: '/seasons',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: _HubTile(
                    title: '기프티콘 상점',
                    subtitle: '다이아로 교환',
                    icon: Icons.card_giftcard,
                    color: AppColors.brandGreen,
                    route: '/shop/gifticons',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HubTile(
                    title: '다이아 충전',
                    subtitle: '패키지 구매',
                    icon: Icons.diamond,
                    color: AppColors.brandBlue,
                    route: '/shop/diamonds',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: _HubTile(
                    title: '루틴',
                    subtitle: '매일 체크인 streak',
                    icon: Icons.replay_circle_filled,
                    color: AppColors.brandOrange,
                    route: '/routines',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HubTile(
                    title: '클랜 대항전',
                    subtitle: '학교·동아리 주간 랭킹',
                    icon: Icons.shield,
                    color: AppColors.brandRed,
                    route: '/clans',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.route,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String route;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors[0].withValues(alpha: 0.22),
              colors[1].withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors[0].withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors[0].withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: colors[0]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.notoSansKr(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,),),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge!,
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandYellow,),),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,),),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors[0]),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,),),
            Text(subtitle,
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: AppColors.textMuted,),),
          ],
        ),
      ),
    );
  }
}
