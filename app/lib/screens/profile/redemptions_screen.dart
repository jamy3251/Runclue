import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../providers/gifticon_provider.dart';

/// 내 기프티콘 교환 내역 — pending / issued / failed / expired.
/// issued면 coupon_code 표시 + 복사 버튼.
class RedemptionsScreen extends ConsumerWidget {
  const RedemptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRedemptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 교환 내역')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러올 수 없습니다: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('아직 교환한 기프티콘이 없어요.'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRedemptionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _RedemptionTile(row: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  const _RedemptionTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final g = (row['gifticons'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final brand = g['partner_brand'] as String? ?? '';
    final name = g['name'] as String? ?? '';
    final status = row['status'] as String? ?? 'pending';
    final couponCode = row['coupon_code'] as String?;
    final createdAt = row['created_at'] as String?;
    final cost = (row['diamond_cost'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(brand,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
              const Spacer(),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text(name,
              style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
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
                      fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
          if (status == 'issued' && couponCode != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.brandGreen.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      couponCode,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: couponCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('쿠폰 코드 복사됨'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Text('운영팀 발급 대기 중 — 보통 24시간 이내 완료',
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
          if (status == 'failed') ...[
            const SizedBox(height: 8),
            Text('발급 실패 — 다이아가 자동 환불됩니다. 운영팀이 처리합니다.',
                style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: AppColors.brandRed)),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('발급 대기', AppColors.brandYellow),
      'issued' => ('발급 완료', AppColors.brandGreen),
      'failed' => ('실패', AppColors.brandRed),
      'expired' => ('만료', AppColors.textMuted),
      _ => (status, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: GoogleFonts.notoSansKr(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color)),
    );
  }
}
