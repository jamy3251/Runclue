import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Sticky banner showing real-time earnings: "[Name] just earned ₩[Amount]"
class EarningsNotificationBanner extends StatefulWidget {
  final String userName;
  final String amount;

  const EarningsNotificationBanner({
    super.key,
    required this.userName,
    required this.amount,
  });

  @override
  State<EarningsNotificationBanner> createState() =>
      _EarningsNotificationBannerState();
}

class _EarningsNotificationBannerState
    extends State<EarningsNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant EarningsNotificationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName ||
        oldWidget.amount != widget.amount) {
      _slideCtrl.reset();
      _slideCtrl.forward();
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.brandGreen.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SlideTransition(
        position: _slideAnim,
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                size: 14, color: AppColors.brandGreen),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${widget.userName}님 방금 ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.amount,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.brandGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              ' 획득',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
