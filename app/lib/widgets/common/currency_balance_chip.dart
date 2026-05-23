import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/currency_provider.dart';

/// 코인 + 다이아 잔액을 한 쌍의 chip으로 표시.
/// AppBar action / 프로필 헤더 / 홈 인사 영역에 통일된 룩으로 끼울 수 있도록.
///
/// loading 동안 placeholder 0을 표시 (UX 끊김 방지).
class CurrencyBalanceChips extends ConsumerWidget {
  const CurrencyBalanceChips({super.key, this.compact = false, this.onTap});

  /// true면 아이콘만, false면 숫자까지.
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(balancesProvider);
    final coin = async.valueOrNull?.coin ?? 0;
    final diamond = async.valueOrNull?.diamond ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            icon: Icons.savings,
            color: AppColors.brandYellow,
            value: coin,
            compact: compact,
          ),
          const SizedBox(width: 6),
          _Chip(
            icon: Icons.diamond,
            color: AppColors.brandBlue,
            value: diamond,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.color,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(value),
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 10000) return '${(n / 1000).floor() / 10}만';
    if (n >= 1000) return '${(n / 100).floor() / 10}k';
    return n.toString();
  }
}
