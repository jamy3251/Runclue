import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/common/currency_balance_chip.dart';

/// 다른 사용자(사장) 가게 메뉴 보기 + 다이아 결제.
/// owner_id를 path로 받음 — clue.creator_id에서 진입 가능.
class StoreMenuListScreen extends ConsumerWidget {
  const StoreMenuListScreen({super.key, required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeMenusProvider(ownerId));
    final diamond = ref.watch(balancesProvider).valueOrNull?.diamond ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('가게 메뉴'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: CurrencyBalanceChips()),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러올 수 없습니다: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('이 가게는 아직 등록된 메뉴가 없어요.'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(storeMenusProvider(ownerId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _MenuRow(
                row: items[i],
                userDiamond: diamond,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuRow extends ConsumerStatefulWidget {
  const _MenuRow({required this.row, required this.userDiamond});
  final Map<String, dynamic> row;
  final int userDiamond;

  @override
  ConsumerState<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends ConsumerState<_MenuRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final price = (r['price_diamond'] as int?) ?? 0;
    final canAfford = widget.userDiamond >= price;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: (r['image_url'] as String?) != null
                  ? CachedNetworkImage(
                      imageUrl: r['image_url'] as String,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.bgElevated,
                        child: Icon(Icons.restaurant),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.bgElevated,
                      child: Icon(Icons.restaurant,
                          color: AppColors.textMuted,),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, fontWeight: FontWeight.w800,),),
                if ((r['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(r['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: AppColors.textMuted,),),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        size: 14, color: AppColors.brandBlue,),
                    const SizedBox(width: 4),
                    Text('$price',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandBlue,),),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: !canAfford || _busy ? null : _onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canAfford ? AppColors.brandBlue : AppColors.bgElevated,
              foregroundColor:
                  canAfford ? Colors.white : AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,),
                  )
                : Text(canAfford ? '결제' : '부족',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, fontWeight: FontWeight.w800,),),
          ),
        ],
      ),
    );
  }

  Future<void> _onBuy() async {
    final r = widget.row;
    final price = (r['price_diamond'] as int?) ?? 0;
    final name = r['name'] as String? ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메뉴 결제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, fontWeight: FontWeight.w800,),),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.diamond,
                    size: 14, color: AppColors.brandBlue,),
                const SizedBox(width: 4),
                Text('$price 다이아 차감',
                    style: const TextStyle(fontWeight: FontWeight.w700),),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 결제 후 환불 불가. QR 코드를 가게에서 직접 보여주고 받아가세요.\n   QR은 30일 후 만료됩니다.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('결제'),),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res = await ref
          .read(storeServiceProvider)
          .purchase(r['id'] as String);
      if (!mounted) return;
      if (res['ok'] == true) {
        HapticFeedback.heavyImpact();
        ref.invalidate(balancesProvider);
        ref.invalidate(myPurchasesProvider);
        // 구매 직후 QR 화면으로 이동
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('결제 완료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.brandGreen, size: 56,),
                const SizedBox(height: 12),
                Text('"$name" 결제 완료',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, fontWeight: FontWeight.w800,),),
                const SizedBox(height: 6),
                Text('내 구매 내역에서 QR을 가게에 보여주세요',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.textMuted,),),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기'),),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/profile/purchases');
                },
                child: const Text('QR 보기'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_reasonMessage(res))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _reasonMessage(Map<String, dynamic> res) {
    final reason = res['reason']?.toString() ?? 'unknown';
    switch (reason) {
      case 'insufficient_diamond':
        return '다이아 부족 (보유 ${res['have']}/필요 ${res['need']})';
      case 'menu_inactive':
        return '판매 중지된 메뉴입니다';
      case 'menu_not_found':
        return '메뉴를 찾을 수 없습니다';
      case 'own_menu_not_purchasable':
        return '본인 메뉴는 결제할 수 없어요';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '결제 실패: $reason';
    }
  }
}
