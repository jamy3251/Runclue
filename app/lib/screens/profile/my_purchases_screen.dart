import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../providers/store_provider.dart';

/// 내 가게 구매 내역 — 사용 가능한 QR + 사용 완료된 항목 표시.
class MyPurchasesScreen extends ConsumerWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPurchasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 가게 구매')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러올 수 없습니다: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '아직 구매한 가게 메뉴가 없어요.\n클루 가게에서 다이아로 결제해 보세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPurchasesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _PurchaseTile(row: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.row});
  final Map<String, dynamic> row;

  bool get _redeemed => row['redeemed_at'] != null;
  bool get _expired {
    final exp = row['expires_at'] as String?;
    if (exp == null) return false;
    return DateTime.parse(exp).isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final menu = (row['store_menus'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final name = menu['name'] as String? ?? '메뉴';
    final image = menu['image_url'] as String?;
    final cost = (row['diamond_cost'] as int?) ?? 0;
    final qrToken = row['qr_token'] as String? ?? '';
    final createdAt = row['created_at'] as String?;
    final usable = !_redeemed && !_expired;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: usable ? AppColors.brandBlue : AppColors.borderDefault,
            width: usable ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: image != null
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const ColoredBox(
                              color: AppColors.bgElevated,
                              child: Icon(Icons.restaurant)),
                        )
                      : const ColoredBox(
                          color: AppColors.bgElevated,
                          child: Icon(Icons.restaurant,
                              color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.diamond,
                            size: 12, color: AppColors.brandBlue),
                        const SizedBox(width: 3),
                        Text('$cost',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandBlue)),
                        const Spacer(),
                        if (createdAt != null)
                          Text(
                              timeago.format(DateTime.parse(createdAt), locale: 'ko'),
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(redeemed: _redeemed, expired: _expired),
            ],
          ),
          if (usable) ...[
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => _showFullQr(context, name, qrToken),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: QrImageView(
                    data: qrToken,
                    size: 120,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '가게에 보여주세요 — 탭하면 크게 보기',
                style: GoogleFonts.notoSansKr(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullQr(BuildContext context, String name, String qrToken) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
              const SizedBox(height: 12),
              QrImageView(
                data: qrToken,
                size: 260,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 8),
              const Text('이 QR을 가게 사장님께 보여주세요',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기')),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.redeemed, required this.expired});
  final bool redeemed;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final (label, color) = redeemed
        ? ('사용 완료', AppColors.brandGreen)
        : expired
            ? ('만료', AppColors.textMuted)
            : ('사용 가능', AppColors.brandBlue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: GoogleFonts.notoSansKr(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
