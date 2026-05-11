import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reward_provider.dart';

/// 선물함 (미수령) · 인벤토리 (수령 완료) — 2탭 단일 화면.
///
/// 초기 탭은 ?tab=gifts (기본) / ?tab=inventory 로 제어.
class RewardsScreen extends ConsumerStatefulWidget {
  final String initialTab;
  const RewardsScreen({super.key, this.initialTab = 'gifts'});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab == 'inventory' ? 1 : 0,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unclaimedAsync = ref.watch(myUnclaimedRewardsProvider);
    final claimedAsync = ref.watch(myClaimedRewardsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        title: Text(
          '보상함',
          style: GoogleFonts.notoSansKr(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandYellow,
          indicatorWeight: 3,
          labelColor: AppColors.brandYellow,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, size: 18),
                  const SizedBox(width: 6),
                  Text('선물함'),
                  if (unclaimedAsync.valueOrNull?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 4),
                    _Badge(count: unclaimedAsync.value!.length),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('인벤토리'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GiftBoxList(asyncRewards: unclaimedAsync),
          _InventoryList(asyncRewards: claimedAsync),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 선물함 (미수령)
// ─────────────────────────────────────────────────────────────

class _GiftBoxList extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncRewards;
  const _GiftBoxList({required this.asyncRewards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncRewards.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: '선물함을 불러올 수 없어요',
        onRetry: () => ref.invalidate(myUnclaimedRewardsProvider),
      ),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const _EmptyState(
            icon: Icons.card_giftcard,
            title: '아직 받을 선물이 없어요',
            subtitle: '클루를 완료하면 보상이 여기 도착해요',
          );
        }
        return RefreshIndicator(
          color: AppColors.brandYellow,
          backgroundColor: AppColors.bgSurface,
          onRefresh: () async => ref.invalidate(myUnclaimedRewardsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _RewardCard(reward: rewards[i], isUnclaimed: true),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 인벤토리 (수령)
// ─────────────────────────────────────────────────────────────

class _InventoryList extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncRewards;
  const _InventoryList({required this.asyncRewards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncRewards.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: '인벤토리를 불러올 수 없어요',
        onRetry: () => ref.invalidate(myClaimedRewardsProvider),
      ),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: '인벤토리가 비어있어요',
            subtitle: '선물함에서 보상을 받아보세요',
          );
        }
        return RefreshIndicator(
          color: AppColors.brandYellow,
          backgroundColor: AppColors.bgSurface,
          onRefresh: () async => ref.invalidate(myClaimedRewardsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _RewardCard(reward: rewards[i], isUnclaimed: false),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 보상 카드
// ─────────────────────────────────────────────────────────────

class _RewardCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> reward;
  final bool isUnclaimed;
  const _RewardCard({required this.reward, required this.isUnclaimed});

  @override
  ConsumerState<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends ConsumerState<_RewardCard> {
  bool _claiming = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final type = r['type']?.toString() ?? 'coupon';
    final label = (r['badge_name'] ?? r['clue']?['reward_label'] ?? '보상')
        .toString();
    final value = (r['value'] as num?)?.toInt() ?? 0;
    final couponCode = r['coupon_code']?.toString();
    final expiresAt = _parseDate(r['expires_at']);
    final isExpired =
        expiresAt != null && expiresAt.isBefore(DateTime.now());
    final clueTitle = r['clue']?['title']?.toString();

    final accent = _accentFor(type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpired
              ? AppColors.borderDefault
              : accent.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(type), color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isExpired
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clueTitle != null && clueTitle.isNotEmpty)
                      Text(
                        clueTitle,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (value > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    _valueLabel(type, value),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning_amber : Icons.schedule,
                  size: 14,
                  color: isExpired
                      ? AppColors.brandRed
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _expiryLabel(expiresAt, isExpired),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: isExpired
                        ? AppColors.brandRed
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
          if (couponCode != null && !widget.isUnclaimed) ...[
            const SizedBox(height: 12),
            _CouponCodeBlock(code: couponCode),
          ],
          const SizedBox(height: 12),
          if (widget.isUnclaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired || _claiming ? null : _onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.bgElevated,
                  disabledForegroundColor: AppColors.textMuted,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _claiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        isExpired ? '만료됨' : '받기',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            )
          else
            _ClaimedFooter(claimedAt: _parseDate(r['claimed_at'])),
        ],
      ),
    );
  }

  Future<void> _onClaim() async {
    setState(() => _claiming = true);
    HapticFeedback.mediumImpact();
    try {
      final id = widget.reward['id']?.toString();
      if (id == null) throw Exception('보상 ID 없음');
      await ref.read(rewardServiceProvider).claim(id);
      ref.invalidate(myUnclaimedRewardsProvider);
      ref.invalidate(myClaimedRewardsProvider);
      ref.invalidate(unclaimedRewardsCountProvider);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.brandGreen,
          content: Text(
            '🎉 인벤토리로 옮겼어요',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수령 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }
}

class _CouponCodeBlock extends StatelessWidget {
  final String code;
  const _CouponCodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              size: 16, color: AppColors.brandYellow),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              code,
              style: GoogleFonts.firaMono(
                fontSize: 14,
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('쿠폰 코드를 복사했어요'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '복사',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimedFooter extends StatelessWidget {
  final DateTime? claimedAt;
  const _ClaimedFooter({required this.claimedAt});

  @override
  Widget build(BuildContext context) {
    final text = claimedAt != null
        ? '${_fmtDate(claimedAt!)} 수령'
        : '수령 완료';
    return Row(
      children: [
        const Icon(Icons.check_circle,
            size: 14, color: AppColors.brandGreen),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            color: AppColors.brandGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 헬퍼
// ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandRed,
        borderRadius: BorderRadius.circular(9999),
      ),
      constraints: const BoxConstraints(minWidth: 18),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.notoSansKr(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('클루 탐색하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'coupon':
      return Icons.local_activity;
    case 'prize':
      return Icons.redeem;
    case 'points':
      return Icons.stars;
    case 'badge':
      return Icons.military_tech;
    case 'raffle':
      return Icons.casino_outlined;
    default:
      return Icons.card_giftcard;
  }
}

Color _accentFor(String type) {
  switch (type) {
    case 'coupon':
      return AppColors.brandYellow;
    case 'prize':
      return AppColors.brandOrange;
    case 'points':
      return AppColors.brandBlue;
    case 'badge':
      return AppColors.brandPurple;
    case 'raffle':
      return AppColors.brandGreen;
    default:
      return AppColors.brandYellow;
  }
}

String _valueLabel(String type, int value) {
  switch (type) {
    case 'points':
      return '$value P';
    case 'coupon':
    case 'prize':
      return '₩$value';
    default:
      return '$value';
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

String _fmtDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}.$m.$day';
}

String _expiryLabel(DateTime expiresAt, bool isExpired) {
  if (isExpired) return '만료됨 (${_fmtDate(expiresAt)})';
  final diff = expiresAt.difference(DateTime.now());
  if (diff.inDays >= 1) return 'D-${diff.inDays} · ${_fmtDate(expiresAt)} 만료';
  if (diff.inHours >= 1) return '${diff.inHours}시간 후 만료';
  return '곧 만료';
}
