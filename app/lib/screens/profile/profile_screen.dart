import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reward_provider.dart';
import '../../utils/user_level.dart';
import '../../widgets/common/currency_balance_chip.dart';
import '../../widgets/common/error_widget.dart' as app;
import '../../widgets/common/loading_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final badgesAsync = ref.watch(myBadgesProvider);
    final clanAsync = ref.watch(myClanProvider);
    final unclaimedCountAsync = ref.watch(unclaimedRewardsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: CurrencyBalanceChips()),
          ),
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => app.AppErrorWidget(
          message: '프로필을 불러올 수 없습니다',
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('로그인이 필요합니다'));
          }

          return SingleChildScrollView(
            // 바텀 nav가 가리지 않도록 충분한 하단 패딩
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              children: [
                // Profile Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.bgSurface,
                        backgroundImage: profile['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile['avatar_url'] == null
                            ? const Icon(Icons.person, size: 48, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile['nickname'] ?? '닉네임 없음',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      UserLevelChip(
                        points: (profile['total_points'] as int?) ?? 0,
                      ),
                      if (profile['bio'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile['bio'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: UserLevelCard(
                    points: (profile['total_points'] as int?) ?? 0,
                  ),
                ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: '포인트',
                          value: _formatNumber(profile['total_points'] ?? 0),
                        ),
                        _divider(),
                        _StatItem(
                          label: '배지',
                          value: '${profile['badge_count'] ?? 0}',
                        ),
                        _divider(),
                        _StatItem(
                          label: '클루생성',
                          value: '${profile['clues_created'] ?? 0}',
                        ),
                        _divider(),
                        _StatItem(
                          label: '클루완료',
                          value: '${profile['clues_completed'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 보상함 — 선물함(미수령) + 인벤토리
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RewardEntryCard(
                          icon: Icons.card_giftcard,
                          accent: AppColors.brandYellow,
                          title: '선물함',
                          subtitle: unclaimedCountAsync.maybeWhen(
                            data: (n) => n > 0 ? '$n개 받기 대기' : '대기 중인 보상 없음',
                            orElse: () => '확인하기',
                          ),
                          badgeCount: unclaimedCountAsync.maybeWhen(
                            data: (n) => n,
                            orElse: () => 0,
                          ),
                          onTap: () => context.push('/rewards?tab=gifts'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RewardEntryCard(
                          icon: Icons.inventory_2_outlined,
                          accent: AppColors.brandBlue,
                          title: '인벤토리',
                          subtitle: '내가 받은 보상',
                          onTap: () => context.push('/rewards?tab=inventory'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // My Badges Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '내 배지',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/progress'),
                        child: const Text('전체보기'),
                      ),
                    ],
                  ),
                ),
                badgesAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 100,
                    child: Center(child: Text('배지를 불러올 수 없습니다')),
                  ),
                  data: (badges) {
                    if (badges.isEmpty) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text(
                            '아직 획득한 배지가 없어요',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: badges.length,
                        itemBuilder: (context, index) {
                          final badge = badges[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .primaries[index % Colors.primaries.length]
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: badge['badge_icon_url'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            badge['badge_icon_url'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          Icons.military_tech,
                                          color: Colors.primaries[
                                              index % Colors.primaries.length],
                                        ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  badge['badge_name'] ?? '배지',
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // My Clan Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내 클랜',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      clanAsync.when(
                        loading: () => const Card(
                          child: ListTile(
                            title: Text('로딩 중...'),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (clanData) {
                          if (clanData == null) {
                            return Card(
                              elevation: 0,
                              color: AppColors.bgSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.bgSurface,
                                  child: const Icon(Icons.group_add,
                                      color: Colors.grey),
                                ),
                                title: const Text('클랜에 가입해보세요'),
                                subtitle: const Text('함께하면 더 재밌어요!'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/community'),
                              ),
                            );
                          }
                          final clan = clanData['clan'] as Map<String, dynamic>?;
                          return Card(
                            elevation: 0,
                            color: AppColors.bgSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                backgroundImage: clan?['avatar_url'] != null
                                    ? NetworkImage(clan!['avatar_url'])
                                    : null,
                                child: clan?['avatar_url'] == null
                                    ? const Icon(Icons.groups,
                                        color: Colors.blue)
                                    : null,
                              ),
                              title: Text(
                                clan?['name'] ?? '클랜',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                  '멤버 ${clan?['member_count'] ?? 0}명'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/community'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(indent: 24, endIndent: 24),

                // Settings List
                _SettingsTile(
                  icon: Icons.repeat,
                  title: '루틴 인증 (streak)',
                  onTap: () => context.push('/routines'),
                ),
                _SettingsTile(
                  icon: Icons.sports_esports,
                  title: '미니게임 4종',
                  onTap: () => context.push('/minigames'),
                ),
                _SettingsTile(
                  icon: Icons.card_giftcard,
                  title: '기프티콘 상점 (다이아 교환)',
                  onTap: () => context.push('/shop/gifticons'),
                ),
                _SettingsTile(
                  icon: Icons.receipt_long,
                  title: '내 교환 내역',
                  onTap: () => context.push('/profile/redemptions'),
                ),
                _SettingsTile(
                  icon: Icons.account_balance_wallet,
                  title: '내 지갑 (사장 전용)',
                  onTap: () => context.push('/biz/wallet'),
                ),
                _SettingsTile(
                  icon: Icons.store,
                  title: '내 가게 메뉴 관리 (사장 전용)',
                  onTap: () => context.push('/store/manage'),
                ),
                _SettingsTile(
                  icon: Icons.qr_code_scanner,
                  title: '손님 QR 스캔 (사장 전용)',
                  onTap: () => context.push('/store/scan'),
                ),
                _SettingsTile(
                  icon: Icons.shopping_bag,
                  title: '내 가게 구매 / QR',
                  onTap: () => context.push('/profile/purchases'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: '알림설정',
                  onTap: () => context.push('/settings/notifications'),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: '개인정보',
                  onTap: () => context.push('/settings/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.block,
                  title: '차단관리',
                  onTap: () => context.push('/settings/blocks'),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  onTap: () => context.push('/settings/terms'),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  onTap: () => context.push('/settings/privacy-policy'),
                ),
                // 관리자 전용 — is_admin RPC가 false면 화면 자체에서 차단
                Consumer(builder: (_, ref, __) {
                  final isAdminAsync = ref.watch(isAdminProvider);
                  return isAdminAsync.maybeWhen(
                    data: (isAdmin) => isAdmin
                        ? _SettingsTile(
                            icon: Icons.shield_outlined,
                            title: '관리자 페이지',
                            onTap: () => context.push('/admin'),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  );
                }),
                const Divider(indent: 24, endIndent: 24),
                _SettingsTile(
                  icon: Icons.logout,
                  title: '로그아웃',
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text('로그아웃 하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ref
                                  .read(authServiceProvider)
                                  .signOut();
                              if (context.mounted) {
                                context.go('/auth');
                              }
                            },
                            child: const Text(
                              '로그아웃',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey[300],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RewardEntryCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  const _RewardEntryCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 22, minHeight: 22),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
