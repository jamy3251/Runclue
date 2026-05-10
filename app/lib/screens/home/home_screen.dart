import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/clue_provider.dart';
import '../../services/platform_stats_service.dart';
import '../../widgets/cards/persona_card.dart';
import '../../widgets/clue_card.dart';

enum _RoleTab { explorer, creator, business }

/// Screen 02 · 홈 / 플랫폼 대시보드 — 명세 v2.0 §4.2
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _RoleTab _activeTab = _RoleTab.explorer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.brandYellow,
        backgroundColor: AppColors.bgElevated,
        onRefresh: () async {
          ref.invalidate(platformStatsProvider);
          ref.invalidate(trendingCluesProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildPlatformStats()),
            SliverToBoxAdapter(child: _buildRoleTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildLiveSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildCreateInviteCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildPersonaSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── 내 클루 만들기 안내 카드 ───────────────────────
  Widget _buildCreateInviteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/create');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandPurple.withValues(alpha: 0.18),
                AppColors.brandBlue.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandYellow.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 32, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나도 클루 만들기',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '5분이면 첫 클루 등록 완료\n탐험가가 매장으로 직접 찾아옵니다',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Text(
            'RUNCLUE',
            style: GoogleFonts.blackHanSans(
              fontSize: 22,
              color: AppColors.brandYellow,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => context.push('/search'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary),
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.brandRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────── 플랫폼 스탯 ───────────────────────
  Widget _buildPlatformStats() {
    final statsAsync = ref.watch(platformStatsProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            _StatCell(
              value: _formatCount(stats.totalParticipants),
              label: '참여자',
            ),
            const _StatDivider(),
            _StatCell(
              value: '₩${_formatCount(stats.cumulativeEarnings)}',
              label: '누적수익',
            ),
            const _StatDivider(),
            _StatCell(
              value: _formatCount(stats.activeMissions),
              label: '활성미션',
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 50,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandYellow,
              ),
            ),
          ),
        ),
        error: (_, __) => const Row(
          children: [
            _StatCell(value: '—', label: '참여자'),
            _StatDivider(),
            _StatCell(value: '—', label: '누적수익'),
            _StatDivider(),
            _StatCell(value: '—', label: '활성미션'),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}억';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}만';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ─────────────────────── 역할 탭 ───────────────────────
  Widget _buildRoleTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _RoleTabChip(
            icon: Icons.explore_outlined,
            label: '탐험가',
            isActive: _activeTab == _RoleTab.explorer,
            color: AppColors.brandBlue,
            onTap: () => setState(() => _activeTab = _RoleTab.explorer),
          ),
          const SizedBox(width: 8),
          _RoleTabChip(
            icon: Icons.edit_outlined,
            label: '크리에이터',
            isActive: _activeTab == _RoleTab.creator,
            color: AppColors.brandPurple,
            onTap: () => setState(() => _activeTab = _RoleTab.creator),
          ),
          const SizedBox(width: 8),
          _RoleTabChip(
            icon: Icons.storefront_outlined,
            label: '사장님',
            isActive: _activeTab == _RoleTab.business,
            color: AppColors.brandOrange,
            onTap: () => setState(() => _activeTab = _RoleTab.business),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── LIVE 섹션 ───────────────────────
  Widget _buildLiveSection() {
    final cluesAsync = ref.watch(trendingCluesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: '지금 LIVE',
          accent: '주변 매장 퀘스트',
          onMore: () => context.go('/explore'),
        ),
        const SizedBox(height: 12),
        cluesAsync.when(
          data: (clues) {
            if (clues.isEmpty) return _buildEmptyLive();
            return Column(
              children: [
                _LiveHeroCard(
                  clue: clues.first,
                  onTap: () => context.push('/clue/${clues.first['id']}'),
                ),
                const SizedBox(height: 16),
                if (clues.length > 1)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: clues.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final clue = clues[i + 1];
                        return ClueCard(
                          title: clue['title'] ?? '미션',
                          creatorName: clue['creator_nickname'] ?? '크리에이터',
                          category: clue['category'] ?? '탐험',
                          rewardText: clue['reward_amount'] != null
                              ? '₩${_formatCount(clue['reward_amount'] as int)}'
                              : null,
                          statusBadge: 'LIVE',
                          compact: true,
                          onTap: () => context.push('/clue/${clue['id']}'),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brandYellow),
            ),
          ),
          error: (_, __) => _buildEmptyLive(),
        ),
      ],
    );
  }

  Widget _buildEmptyLive() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department,
              size: 36, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            '오늘 첫 번째 미션을 만들어보세요',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('클루 만들기'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── 페르소나 섹션 ───────────────────────
  Widget _buildPersonaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: '이런 분들이 씁니다',
          accent: '캠퍼스타운 베타',
        ),
        const SizedBox(height: 12),
        PersonaCardList(
          cards: [
            PersonaCard(
              name: '지수(21)',
              role: '시립대 탐험가',
              monthlyEarnings: '메뉴 무료',
              empathyText: '방학에도 친구랑 동네 카페 돌면서 메뉴 할인받아요',
              accentColor: AppColors.brandYellow,
              icon: Icons.school_outlined,
              onTap: () => context.go('/explore'),
            ),
            PersonaCard(
              name: '준서(28)',
              role: '직장인 탐험가',
              monthlyEarnings: '커피값 절약',
              empathyText: '점심시간마다 AR 퀘스트 깨고 기프티콘 받아요',
              accentColor: AppColors.brandBlue,
              icon: Icons.work_outline,
              onTap: () => context.go('/explore'),
            ),
            PersonaCard(
              name: '민호(45)',
              role: '캠퍼스타운 사장님',
              monthlyEarnings: '+방학 매출',
              empathyText: '광고비 0원으로 방학에도 신규 손님 유입돼요',
              accentColor: AppColors.brandOrange,
              icon: Icons.storefront_outlined,
              onTap: () => context.push('/biz'),
            ),
            PersonaCard(
              name: '하늘(24)',
              role: '퀘스트 크리에이터',
              monthlyEarnings: '수익 배분',
              empathyText: '동네 매장 퀘스트를 설계하고 방문 수익을 받아요',
              accentColor: AppColors.brandPurple,
              icon: Icons.edit_note_outlined,
              onTap: () => context.push('/create'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 서브 컴포넌트
// ─────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.brandYellow,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.borderDefault,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _RoleTabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _RoleTabChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : AppColors.borderDefault,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? color : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String accent;
  final VoidCallback? onMore;

  const _SectionHeader({
    required this.title,
    required this.accent,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.blackHanSans(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: AppColors.brandYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              accent,
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: Text(
                '전체 보기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveHeroCard extends StatelessWidget {
  final Map<String, dynamic> clue;
  final VoidCallback onTap;

  const _LiveHeroCard({required this.clue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reward = clue['reward_amount'];
    final participants = clue['participant_count'] ?? 0;
    final title = clue['title'] ?? '미션';
    final thumb = clue['thumbnail_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
            image: thumb != null
                ? DecorationImage(
                    image: NetworkImage(thumb),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.55),
                      BlendMode.darken,
                    ),
                  )
                : null,
            boxShadow: const [AppShadows.card],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // 그라디언트 오버레이
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.bgHero.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // 상단 LIVE 배지
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '$participants명',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 하단 제목 + 상금
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.blackHanSans(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (reward != null)
                          Text(
                            '₩${reward is num ? reward.toInt() : reward}',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 24,
                              color: AppColors.brandYellow,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '참여',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
