import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';

/// 사장 wallet 대시보드 — 충전·수수료·풀 잔액·가게 매출 종합 (Step 17).
class WalletHistoryScreen extends ConsumerWidget {
  const WalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(topupSummaryProvider).valueOrNull;
    final pools = ref.watch(myCluePoolsProvider).valueOrNull ?? const [];
    final topups = ref.watch(myTopupsProvider).valueOrNull ?? const [];
    final revenue = ref.watch(storeRevenueProvider).valueOrNull ?? const [];
    final revenueSum = ref.watch(storeRevenueSumProvider).valueOrNull ?? 0;
    final dia = ref.watch(balancesProvider).valueOrNull?.diamond ?? 0;

    final poolRemain = pools.fold<int>(0, (acc, p) {
      final net = (p['reward_pool_net'] as int?) ?? 0;
      final committed = (p['reward_pool_committed'] as int?) ?? 0;
      return acc + (net - committed);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 지갑'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topupSummaryProvider);
          ref.invalidate(myTopupsProvider);
          ref.invalidate(myCluePoolsProvider);
          ref.invalidate(storeRevenueProvider);
          ref.invalidate(storeRevenueSumProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            // ── 4 stats 카드 ──
            _StatsRow(
              gross: summary?.gross ?? 0,
              fee: summary?.fee ?? 0,
              poolRemain: poolRemain,
              diamond: dia,
              revenueSum: revenueSum,
            ),
            const SizedBox(height: 16),

            // ── 내 클루 풀 ──
            _SectionHeader(title: '내 클루 풀 잔액', count: pools.length),
            ...pools.map((p) => _CluePoolTile(row: p)),
            if (pools.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('아직 만든 클루가 없어요.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            const SizedBox(height: 16),

            // ── 가게 매출 (Step 16) ──
            _SectionHeader(title: '가게 매출 (다이아)', count: revenue.length),
            ...revenue.map((r) => _RevenueTile(row: r)),
            if (revenue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('아직 가게 매출이 없어요.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            const SizedBox(height: 16),

            // ── 충전 기록 ──
            _SectionHeader(title: '충전 기록', count: topups.length),
            ...topups.map((t) => _TopupTile(row: t)),
            if (topups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('아직 충전 기록이 없어요.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.gross,
    required this.fee,
    required this.poolRemain,
    required this.diamond,
    required this.revenueSum,
  });
  final int gross;
  final int fee;
  final int poolRemain;
  final int diamond;
  final int revenueSum;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: '총 충전',
                    value: '₩${_formatKrw(gross)}',
                    color: AppColors.brandBlue,
                    icon: Icons.account_balance_wallet)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: '수수료 15%',
                    value: '₩${_formatKrw(fee)}',
                    color: AppColors.brandRed,
                    icon: Icons.percent)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: '남은 클루 풀',
                    value: '${_formatKrw(poolRemain)}p',
                    color: AppColors.brandYellow,
                    icon: Icons.savings)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: '내 다이아',
                    value: '${_formatKrw(diamond)}',
                    color: AppColors.brandBlue,
                    icon: Icons.diamond)),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(
            label: '가게 매출 누계 (다이아)',
            value: '+${_formatKrw(revenueSum)}',
            color: AppColors.brandGreen,
            icon: Icons.storefront),
      ],
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Text('($count)',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CluePoolTile extends StatelessWidget {
  const _CluePoolTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final net = (row['reward_pool_net'] as int?) ?? 0;
    final committed = (row['reward_pool_committed'] as int?) ?? 0;
    final remain = net - committed;
    final title = row['title'] as String? ?? '';
    final status = row['status'] as String? ?? '';
    final progress = net <= 0 ? 0.0 : (committed / net).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${_format(remain)} / ${_format(net)}',
              style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandYellow)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.brandYellow),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return AppColors.brandGreen;
      case 'completed':
        return AppColors.textMuted;
      case 'draft':
        return AppColors.brandYellow;
      default:
        return AppColors.textMuted;
    }
  }

  static String _format(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final delta = (row['delta'] as int?) ?? 0;
    final created = row['created_at'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond,
              size: 14, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Text('+$delta',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandGreen)),
          const Spacer(),
          if (created != null)
            Text(
              timeago.format(DateTime.parse(created), locale: 'ko'),
              style: GoogleFonts.notoSansKr(
                  fontSize: 10, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _TopupTile extends StatelessWidget {
  const _TopupTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final gross = (row['gross_amount'] as int?) ?? 0;
    final fee = (row['fee_amount'] as int?) ?? 0;
    final net = (row['net_amount'] as int?) ?? 0;
    final status = row['status'] as String? ?? '';
    final clueTitle =
        (row['clues'] as Map?)?['title'] as String? ?? '풀 직접 충전';
    final created = row['created_at'] as String?;
    final raw = (row['raw_response'] as Map?)?.cast<String, dynamic>();
    final receiptUrl =
        (raw?['receipt'] as Map?)?['url'] as String? ??
            (raw?['cashReceipt'] as Map?)?['receiptUrl'] as String?;
    final orderId = row['toss_order_id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: status == 'approved'
                ? AppColors.borderDefault
                : AppColors.brandRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(clueTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              _topupStatusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _kv('충전', '₩${_format(gross)}', AppColors.brandBlue),
              _kv('수수료', '₩${_format(fee)}', AppColors.brandRed),
              _kv('풀 적립', '${_format(net)}p', AppColors.brandYellow),
            ],
          ),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('주문번호: $orderId',
                style: GoogleFonts.robotoMono(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
          if (created != null) ...[
            const SizedBox(height: 2),
            Text(
              timeago.format(DateTime.parse(created), locale: 'ko'),
              style: GoogleFonts.notoSansKr(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
          if (receiptUrl != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  final uri = Uri.parse(receiptUrl);
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('영수증 보기'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k ',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: AppColors.textMuted)),
          Text(v,
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, fontWeight: FontWeight.w800, color: c)),
        ],
      );

  Widget _topupStatusBadge(String status) {
    final (label, color) = switch (status) {
      'approved' => ('완료', AppColors.brandGreen),
      'pending' => ('대기', AppColors.brandYellow),
      'failed' => ('실패', AppColors.brandRed),
      'cancelled' => ('취소', AppColors.textMuted),
      _ => (status, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.notoSansKr(
              fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }

  static String _format(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
