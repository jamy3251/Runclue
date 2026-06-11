import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../utils/platform_grade.dart';
import 'gifticon_admin_tab.dart';

/// 관리자 페이지 — 통계 + 클루 관리 + 보상 관리.
/// is_admin() 검증 후 진입. 일반 사용자는 redirect.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);
    return isAdminAsync.when(
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),),
      ),
      error: (e, _) => _denied('권한 확인 실패: $e'),
      data: (isAdmin) {
        if (!isAdmin) return _denied('관리자만 접근 가능합니다');
        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            backgroundColor: AppColors.bgElevated,
            title: Text(
              '관리자 페이지',
              style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.brandYellow,
              labelColor: AppColors.brandYellow,
              unselectedLabelColor: AppColors.textMuted,
              isScrollable: true,
              tabs: const [
                Tab(text: '대시보드', icon: Icon(Icons.dashboard, size: 18)),
                Tab(text: '클루', icon: Icon(Icons.explore, size: 18)),
                Tab(text: '보상', icon: Icon(Icons.card_giftcard, size: 18)),
                Tab(text: '기프티콘', icon: Icon(Icons.redeem, size: 18)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: const [
              _StatsTab(),
              _CluesTab(),
              _RewardsTab(),
              GifticonAdminTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _denied(String msg) => Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: AppBar(
          backgroundColor: AppColors.bgElevated,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock,
                  size: 56, color: AppColors.textMuted,),
              const SizedBox(height: 12),
              Text(msg,
                  style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary, fontSize: 14,),),
            ],
          ),
        ),
      );
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      color: AppColors.brandYellow,
      child: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),),
        error: (e, _) => Center(
            child: Text('오류: $e', style: const TextStyle(color: AppColors.error)),),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PlatformGradeCard(
              totalClues: s['totalClues'] ?? 0,
              totalUsers: s['totalUsers'] ?? 0,
            ),
            const SizedBox(height: 16),
            _statCard('전체 클루', '${s['totalClues'] ?? 0}', Icons.explore,
                AppColors.brandBlue,),
            _statCard('활성 클루', '${s['activeClues'] ?? 0}',
                Icons.flash_on, AppColors.brandGreen,),
            _statCard('전체 사용자', '${s['totalUsers'] ?? 0}',
                Icons.person, AppColors.brandPurple,),
            _statCard('전체 참여', '${s['totalParticipations'] ?? 0}',
                Icons.groups, AppColors.brandOrange,),
            _statCard('발급된 보상', '${s['totalRewards'] ?? 0}',
                Icons.card_giftcard, AppColors.brandYellow,),
            _statCard('미수령 보상', '${s['unclaimedRewards'] ?? 0}',
                Icons.inventory, AppColors.brandRed,),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textMuted,),),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CluesTab extends ConsumerWidget {
  const _CluesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cluesAsync = ref.watch(adminAllCluesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminAllCluesProvider),
      color: AppColors.brandYellow,
      child: cluesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),),
        error: (e, _) => Center(
            child: Text('오류: $e', style: const TextStyle(color: AppColors.error)),),
        data: (clues) {
          if (clues.isEmpty) {
            return const Center(
                child: Text('클루 없음',
                    style: TextStyle(color: AppColors.textMuted),),);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ClueAdminTile(
              clue: clues[i],
              onChanged: () => ref.invalidate(adminAllCluesProvider),
            ),
          );
        },
      ),
    );
  }
}

class _ClueAdminTile extends ConsumerWidget {
  final Map<String, dynamic> clue;
  final VoidCallback onChanged;
  const _ClueAdminTile({required this.clue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = clue['status']?.toString() ?? 'unknown';
    final creator = clue['creator'] as Map?;
    final creatorName = creator?['nickname']?.toString() ?? '?';
    final created = DateTime.tryParse(clue['created_at']?.toString() ?? '');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clue['title']?.toString() ?? '(제목 없음)',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@$creatorName · ${created != null ? DateFormat("MM/dd HH:mm").format(created) : ""}',
            style: GoogleFonts.notoSansKr(
                fontSize: 11, color: AppColors.textMuted,),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status != 'suspended')
                _actionBtn('정지', AppColors.brandRed, () async {
                  await ref
                      .read(adminServiceProvider)
                      .updateClueStatus(clue['id'], 'suspended');
                  onChanged();
                }),
              if (status == 'suspended')
                _actionBtn('활성화', AppColors.brandGreen, () async {
                  await ref
                      .read(adminServiceProvider)
                      .updateClueStatus(clue['id'], 'active');
                  onChanged();
                }),
              const SizedBox(width: 8),
              _actionBtn('삭제', AppColors.brandRed, () async {
                final ok = await _confirm(context, '${clue['title']} 삭제?');
                if (ok != true) return;
                await ref
                    .read(adminServiceProvider)
                    .hardDeleteClue(clue['id']);
                onChanged();
              }, outlined: true,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String s) {
    final color = switch (s) {
      'active' => AppColors.brandGreen,
      'suspended' => AppColors.brandRed,
      'pending' => AppColors.brandOrange,
      'completed' => AppColors.brandBlue,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(s,
          style: GoogleFonts.notoSansKr(
              fontSize: 10, color: color, fontWeight: FontWeight.w700,),),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap,
      {bool outlined = false,}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: outlined ? null : color.withValues(alpha: 0.15),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.notoSansKr(
                fontSize: 11, color: color, fontWeight: FontWeight.w700,),),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('확인',
            style: TextStyle(color: AppColors.textPrimary),),
        content: Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('확인',
                  style: TextStyle(color: AppColors.brandRed),),),
        ],
      ),
    );
  }
}

class _RewardsTab extends ConsumerWidget {
  const _RewardsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(adminAllRewardsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminAllRewardsProvider),
      color: AppColors.brandYellow,
      child: rewardsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),),
        error: (e, _) => Center(
            child: Text('오류: $e', style: const TextStyle(color: AppColors.error)),),
        data: (rewards) {
          if (rewards.isEmpty) {
            return const Center(
                child: Text('보상 없음',
                    style: TextStyle(color: AppColors.textMuted),),);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = rewards[i];
              final user = r['user'] as Map?;
              final clue = r['clue'] as Map?;
              final claimed = r['is_claimed'] == true;
              final created =
                  DateTime.tryParse(r['created_at']?.toString() ?? '');
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: claimed
                          ? AppColors.borderDefault
                          : AppColors.brandYellow.withValues(alpha: 0.3),),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.card_giftcard,
                          color: AppColors.brandYellow, size: 18,),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['type'] ?? "?"} · ${r['value'] ?? r['badge_name'] ?? "?"}',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,),
                          ),
                          Text(
                            '@${user?['nickname'] ?? "?"} · ${clue?['title'] ?? "?"}',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 11, color: AppColors.textMuted,),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (created != null)
                            Text(
                              DateFormat("yyyy/MM/dd HH:mm").format(created),
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 10, color: AppColors.textMuted,),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: claimed
                            ? AppColors.brandGreen.withValues(alpha: 0.15)
                            : AppColors.brandOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        claimed ? '수령' : '미수령',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: claimed
                                ? AppColors.brandGreen
                                : AppColors.brandOrange,),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
