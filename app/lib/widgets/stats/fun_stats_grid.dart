import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 4-card grid showing fun statistics (distance, earnings, places, time).
class FunStatsGrid extends StatelessWidget {
  final List<FunStat> stats;

  const FunStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.6,
        children: stats.map((s) => _StatCard(stat: s)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final FunStat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, size: 18, color: stat.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stat.value,
            style: AppTextStyles.headingMd.copyWith(
              color: AppColors.brandYellow,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            stat.label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class FunStat {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const FunStat({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.brandYellow,
  });

  static List<FunStat> defaults({
    String distance = '0km',
    String earnings = '₩0',
    String places = '0곳',
    String time = '0시간',
  }) =>
      [
        FunStat(
          icon: Icons.directions_walk,
          value: distance,
          label: '총 이동거리',
          color: AppColors.brandBlue,
        ),
        FunStat(
          icon: Icons.account_balance_wallet,
          value: earnings,
          label: '총 수익',
          color: AppColors.brandGreen,
        ),
        FunStat(
          icon: Icons.location_on,
          value: places,
          label: '방문 장소',
          color: AppColors.brandOrange,
        ),
        FunStat(
          icon: Icons.access_time,
          value: time,
          label: '참여 시간',
          color: AppColors.brandPurple,
        ),
      ];
}
