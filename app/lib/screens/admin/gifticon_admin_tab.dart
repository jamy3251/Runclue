import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/admin_provider.dart';

/// 어드민 — 기프티콘 운영 탭 (수동 SQL 대체).
/// 위: 발급 대기 큐 (쿠폰코드 입력 → issued) / 아래: 카탈로그 관리 (등록·재고·활성).
class GifticonAdminTab extends ConsumerWidget {
  const GifticonAdminTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(adminPendingRedemptionsProvider).valueOrNull ?? const [];
    final gifticons = ref.watch(adminGifticonsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminPendingRedemptionsProvider);
        ref.invalidate(adminGifticonsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 발급 대기 큐 ──
          Row(
            children: [
              Text('발급 대기',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 15, fontWeight: FontWeight.w900,),),
              const SizedBox(width: 6),
              if (pending.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${pending.length}',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,),),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('대기 중인 교환 요청이 없습니다',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: AppColors.textMuted,),),
            )
          else
            ...pending.map((r) => _PendingTile(row: r)),

          const SizedBox(height: 24),

          // ── 카탈로그 관리 ──
          Row(
            children: [
              Text('카탈로그',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 15, fontWeight: FontWeight.w900,),),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('등록'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandYellow,),
              ),
            ],
          ),
          const SizedBox(height: 4),
          gifticons.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child:
                  CircularProgressIndicator(color: AppColors.brandYellow),
            ),),
            error: (e, _) => Text('로드 실패: $e',
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, color: AppColors.brandRed,),),
            data: (list) => list.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        '등록된 기프티콘이 없습니다.\n위 [등록] 버튼으로 첫 상품을 추가하세요 (권장: 카페·편의점·치킨 5~10개)',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.5,),),
                  )
                : Column(
                    children:
                        list.map((g) => _GifticonTile(row: g)).toList(),),
          ),
        ],
      ),
    );
  }

  static Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref,) async {
    final brand = TextEditingController();
    final name = TextEditingController();
    final value = TextEditingController();
    final cost = TextEditingController();
    final stock = TextEditingController(text: '30');
    final image = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('기프티콘 등록',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(brand, '브랜드 (예: 스타벅스)'),
              _field(name, '상품명 (예: 아메리카노 Tall)'),
              _field(value, '정가 (원, 예: 4500)', number: true),
              _field(cost, '다이아 가격 (예: 450)', number: true),
              _field(stock, '재고', number: true),
              _field(image, '이미지 URL (선택)'),
              const SizedBox(height: 4),
              Text(
                  '가격 룰: 다이아 가격 = 정가 ÷ 10 (1다이아=10원 기준).\n'
                  '마진은 충전 보너스(≤10%)가 도매할인율(~10%)을 넘지 않는 데서 나옴 — '
                  '도매가율이 90%를 넘는 상품은 등록 금지.',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11, color: AppColors.textMuted, height: 1.5,),),
            ],
          ),
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
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ref.read(adminServiceProvider).createGifticon(
            partnerBrand: brand.text.trim(),
            name: name.text.trim(),
            valueKrw: int.tryParse(value.text.trim()) ?? 0,
            diamondCost: int.tryParse(cost.text.trim()) ?? 0,
            stock: int.tryParse(stock.text.trim()) ?? 0,
            imageUrl: image.text.trim(),
          );
      ref.invalidate(adminGifticonsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('등록 완료')),);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('등록 실패: $e')));
      }
    }
  }

  static Widget _field(TextEditingController c, String label,
      {bool number = false,}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: GoogleFonts.notoSansKr(fontSize: 13),
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}

/// 발급 대기 행 — 쿠폰코드 입력 → issued.
class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = row['user'] as Map<String, dynamic>?;
    final gifticon = row['gifticon'] as Map<String, dynamic>?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.brandYellow.withValues(alpha: 0.35),),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${gifticon?['partner_brand'] ?? ''} ${gifticon?['name'] ?? '?'}',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: FontWeight.w800,),),
                Text(
                    '${user?['nickname'] ?? '?'} · ${row['diamond_cost'] ?? '?'}다이아',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.textMuted,),),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _issueDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('발급'),
          ),
        ],
      ),
    );
  }

  Future<void> _issueDialog(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('쿠폰코드 발급',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: code,
          autofocus: true,
          style: GoogleFonts.notoSansKr(fontSize: 14),
          decoration: const InputDecoration(
              labelText: '쿠폰코드 (예: XXXX-XXXX-XXXX)', isDense: true,),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,),
            child: const Text('발급 완료'),
          ),
        ],
      ),
    );
    if (ok != true || code.text.trim().isEmpty) return;
    try {
      await ref
          .read(adminServiceProvider)
          .issueRedemption(row['id'] as String, code.text.trim());
      ref.invalidate(adminPendingRedemptionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('발급 완료 — 사용자에게 표시됩니다')),);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('발급 실패: $e')));
      }
    }
  }
}

/// 카탈로그 행 — 재고/활성 토글.
class _GifticonTile extends ConsumerWidget {
  const _GifticonTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = row['active'] == true;
    final stock = row['stock'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active
                ? AppColors.brandGreen.withValues(alpha: 0.3)
                : AppColors.borderDefault,),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${row['partner_brand']} ${row['name']}',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textMuted,),),
                Text(
                    '${row['diamond_cost']}다이아 · 재고 $stock',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.textMuted,),),
              ],
            ),
          ),
          IconButton(
            tooltip: '재고 +10',
            icon: const Icon(Icons.add_box_outlined,
                size: 20, color: AppColors.brandBlue,),
            onPressed: () async {
              await ref
                  .read(adminServiceProvider)
                  .updateGifticon(row['id'] as String, {'stock': stock + 10});
              ref.invalidate(adminGifticonsProvider);
            },
          ),
          Switch(
            value: active,
            activeColor: AppColors.brandGreen,
            onChanged: (v) async {
              await ref
                  .read(adminServiceProvider)
                  .updateGifticon(row['id'] as String, {'active': v});
              ref.invalidate(adminGifticonsProvider);
            },
          ),
        ],
      ),
    );
  }
}
