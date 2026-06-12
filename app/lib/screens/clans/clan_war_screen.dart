import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/clan_service.dart';

final clanServiceProvider = Provider<ClanService>((ref) => ClanService());

final myClanProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.watch(clanServiceProvider).myClan(uid);
});

final clanLeaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(clanServiceProvider).weeklyLeaderboard();
});

/// 클랜 대항전 — 학교/동아리/과 단위 주간 경쟁.
/// 멤버가 미션을 완료할 때마다 클랜에 +10점 (DB 트리거 자동).
class ClanWarScreen extends ConsumerWidget {
  const ClanWarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myClan = ref.watch(myClanProvider).valueOrNull;
    final board = ref.watch(clanLeaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('클랜 대항전',
            style: GoogleFonts.blackHanSans(
                fontSize: 18, color: AppColors.textPrimary,),),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myClanProvider);
          ref.invalidate(clanLeaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 내 클랜 카드 (없으면 만들기/가입 안내)
            if (myClan != null)
              _MyClanCard(clan: myClan)
            else
              _NoClanCard(onCreate: () => _createDialog(context, ref)),
            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.emoji_events,
                    size: 18, color: AppColors.brandYellow,),
                const SizedBox(width: 6),
                Text('이번 주 랭킹',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 15, fontWeight: FontWeight.w900,),),
                const Spacer(),
                Text('미션 완료 1건 = 10점',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.textMuted,),),
              ],
            ),
            const SizedBox(height: 8),
            board.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child:
                    CircularProgressIndicator(color: AppColors.brandYellow),
              ),),
              error: (e, _) => Text('랭킹 로드 실패: $e',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: AppColors.brandRed,),),
              data: (list) => list.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          '아직 클랜이 없어요.\n첫 클랜을 만들고 우리 학교/동아리 이름을 랭킹에 올려보세요!',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.5,),),
                    )
                  : Column(
                      children: List.generate(list.length, (i) {
                        final c = list[i];
                        final isMine =
                            myClan != null && c['clan_id'] == myClan['id'];
                        return _ClanRankTile(
                          rank: i + 1,
                          row: c,
                          isMine: isMine,
                          canJoin: myClan == null,
                          onJoin: () => _join(context, ref,
                              c['clan_id'] as String, c['name'] as String,),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('클랜 만들기',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 20,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: '클랜 이름 (학교/과/동아리)',
                  hintText: '예: 한양대 컴공',
                  isDense: true,
                  counterText: '',),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: desc,
              decoration: const InputDecoration(
                  labelText: '소개 (선택)', isDense: true,),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: Colors.black,),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final res = await ref.read(clanServiceProvider).createClan(
          name.text.trim(),
          description:
              desc.text.trim().isEmpty ? null : desc.text.trim(),
        );
    if (!context.mounted) return;
    if (res['ok'] == true) {
      HapticFeedback.heavyImpact();
      ref.invalidate(myClanProvider);
      ref.invalidate(clanLeaderboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('클랜 창설! 미션을 완료하면 자동으로 점수가 쌓입니다')),);
    } else {
      final msg = switch (res['reason']) {
        'already_in_clan' => '이미 클랜에 소속되어 있어요',
        'name_taken' => '이미 있는 이름이에요',
        'invalid_name' => '이름은 2~20자로 입력해 주세요',
        _ => '실패: ${res['reason']}',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref, String clanId,
      String name,) async {
    final res = await ref.read(clanServiceProvider).joinClan(clanId);
    if (!context.mounted) return;
    if (res['ok'] == true) {
      HapticFeedback.mediumImpact();
      ref.invalidate(myClanProvider);
      ref.invalidate(clanLeaderboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name 합류! 이제 내 미션이 클랜 점수가 됩니다')),);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 실패: ${res['reason']}')),);
    }
  }
}

class _MyClanCard extends ConsumerWidget {
  const _MyClanCard({required this.clan});
  final Map<String, dynamic> clan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/clans/${clan['id']}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.brandYellow.withValues(alpha: 0.16),
          AppColors.brandOrange.withValues(alpha: 0.08),
        ],),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clan['name'] as String? ?? '?',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandYellow,),),
                Text(
                    '멤버 ${clan['member_count']} · 누적 ${clan['total_points']}점'
                    '${clan['my_role'] == 'leader' ? ' · 리더' : ''}',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textSecondary,),),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final res =
                  await ref.read(clanServiceProvider).leaveClan();
              if (!context.mounted) return;
              if (res['ok'] == true) {
                ref.invalidate(myClanProvider);
                ref.invalidate(clanLeaderboardProvider);
              } else if (res['reason'] == 'leader_must_disband_last') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('리더는 멤버가 모두 나간 뒤에 해산할 수 있어요'),),);
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('탈퇴'),
          ),
        ],
      ),
      ),
    );
  }
}

class _NoClanCard extends StatelessWidget {
  const _NoClanCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아직 클랜이 없어요',
              style: GoogleFonts.notoSansKr(
                  fontSize: 15, fontWeight: FontWeight.w900,),),
          const SizedBox(height: 4),
          Text('학교·학과·동아리 이름으로 클랜을 만들고 친구들과 함께 랭킹을 올려보세요. '
              '멤버가 미션을 완료할 때마다 클랜에 +10점!',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,),),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text('클랜 만들기',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w900,),),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClanRankTile extends StatelessWidget {
  const _ClanRankTile({
    required this.rank,
    required this.row,
    required this.isMine,
    required this.canJoin,
    required this.onJoin,
  });

  final int rank;
  final Map<String, dynamic> row;
  final bool isMine;
  final bool canJoin;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return InkWell(
      onTap: () => context.push('/clans/${row['clan_id']}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMine
              ? AppColors.brandYellow
              : AppColors.borderDefault,
          width: isMine ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(medal ?? '$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                    fontSize: medal != null ? 18 : 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,),),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['name']}${isMine ? ' (내 클랜)' : ''}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isMine
                          ? AppColors.brandYellow
                          : AppColors.textPrimary,),
                ),
                Text(
                    '멤버 ${row['member_count']} · 이번 주 활동 ${row['active_members']}명',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.textMuted,),),
              ],
            ),
          ),
          Text('${row['week_points']}점',
              style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandYellow,),),
          if (canJoin) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                side: const BorderSide(color: AppColors.brandBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text('가입', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
