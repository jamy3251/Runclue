import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/gifticon_provider.dart';
import '../../widgets/common/currency_balance_chip.dart';

/// 다이아로 외부 기프티콘 교환하는 카탈로그 화면.
/// 운영자가 미리 등록한 활성 기프티콘만 노출.
class GifticonShopScreen extends ConsumerWidget {
  const GifticonShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(gifticonCatalogProvider);
    final balancesAsync = ref.watch(balancesProvider);
    final diamond = balancesAsync.valueOrNull?.diamond ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기프티콘 상점'),
        actions: [
          IconButton(
            tooltip: '다이아 충전',
            icon: const Icon(Icons.add_card),
            onPressed: () => context.push('/shop/diamonds'),
          ),
          IconButton(
            tooltip: '내 교환 내역',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/profile/redemptions'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: CurrencyBalanceChips()),
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러올 수 없습니다: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('지금은 교환 가능한 기프티콘이 없어요. 곧 추가됩니다.'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(gifticonCatalogProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, i) => _GifticonTile(
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

class _GifticonTile extends ConsumerStatefulWidget {
  const _GifticonTile({required this.row, required this.userDiamond});
  final Map<String, dynamic> row;
  final int userDiamond;

  @override
  ConsumerState<_GifticonTile> createState() => _GifticonTileState();
}

class _GifticonTileState extends ConsumerState<_GifticonTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final cost = (r['diamond_cost'] as int?) ?? 0;
    final stock = (r['stock'] as int?) ?? 0;
    final value = (r['value_krw'] as int?) ?? 0;
    final canAfford = widget.userDiamond >= cost;
    final inStock = stock > 0;
    final disabled = !canAfford || !inStock || _busy;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: r['image_url'] != null
                ? CachedNetworkImage(
                    imageUrl: r['image_url'] as String,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.bgElevated),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.bgElevated,
                      child: const Icon(Icons.card_giftcard,
                          size: 36, color: AppColors.textMuted),
                    ),
                  )
                : Container(
                    color: AppColors.bgElevated,
                    child: const Icon(Icons.card_giftcard,
                        size: 36, color: AppColors.textMuted),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r['partner_brand'] as String? ?? '',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r['name'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₩${_formatKrw(value)}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        size: 12, color: AppColors.brandBlue),
                    const SizedBox(width: 3),
                    Text(
                      '$cost',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      inStock ? '재고 $stock' : '품절',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 10,
                        color: inStock
                            ? AppColors.textMuted
                            : AppColors.brandRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: disabled ? null : _onRedeem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: disabled
                          ? AppColors.bgElevated
                          : AppColors.brandBlue,
                      foregroundColor:
                          disabled ? AppColors.textMuted : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            !inStock
                                ? '품절'
                                : !canAfford
                                    ? '다이아 부족'
                                    : '교환',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatKrw(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _onRedeem() async {
    final r = widget.row;
    final cost = (r['diamond_cost'] as int?) ?? 0;
    final name = r['name'] as String? ?? '';
    final brand = r['partner_brand'] as String? ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('교환할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$brand · $name'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.diamond,
                    size: 14, color: AppColors.brandBlue),
                const SizedBox(width: 4),
                Text('$cost 다이아 차감',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 교환 후 환불은 불가합니다. 쿠폰 코드는 발급 완료 시\n내 교환 내역에서 확인할 수 있어요.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('교환'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res =
          await ref.read(gifticonServiceProvider).redeem(r['id'] as String);
      if (!mounted) return;
      if (res['ok'] == true) {
        HapticFeedback.heavyImpact();
        ref.invalidate(balancesProvider);
        ref.invalidate(gifticonCatalogProvider);
        ref.invalidate(myRedemptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 교환 신청 완료 — 내 교환 내역에서 발급을 기다려주세요'),
            backgroundColor: AppColors.brandGreen,
            duration: Duration(seconds: 2),
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
        return '다이아가 부족합니다 (보유 ${res['have']}/필요 ${res['need']})';
      case 'out_of_stock':
        return '품절되었습니다';
      case 'gifticon_inactive':
        return '판매가 종료된 기프티콘입니다';
      case 'gifticon_not_found':
        return '카탈로그에서 찾을 수 없습니다';
      case 'auth_required':
        return '로그인이 필요합니다';
      default:
        return '교환 실패: $reason';
    }
  }
}
