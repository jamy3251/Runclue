import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// AI-generated provocation banner to drive competitive engagement.
/// Shows personalized taunts like "You're [N] behind [name]!"
class AIProvocationBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AIProvocationBanner({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.aiProvocation,
          border: Border.all(
            color: AppColors.brandRed.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                size: 18, color: AppColors.brandRed),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
