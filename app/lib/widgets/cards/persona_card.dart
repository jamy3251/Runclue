import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Persona recommendation card for horizontal scroll section.
class PersonaCard extends StatelessWidget {
  final String name;
  final String role;
  final String monthlyEarnings;
  final String empathyText;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onTap;

  const PersonaCard({
    super.key,
    required this.name,
    required this.role,
    required this.monthlyEarnings,
    required this.empathyText,
    this.accentColor = AppColors.brandYellow,
    this.icon = Icons.person,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: accentColor),
            ),
            const SizedBox(height: AppSpacing.md),

            // Name
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),

            // Role label
            Text(
              role,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Monthly earnings
            Text(
              monthlyEarnings,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Empathy text
            Text(
              empathyText,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of persona cards.
class PersonaCardList extends StatelessWidget {
  final List<PersonaCard> cards;

  const PersonaCardList({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) => cards[index],
      ),
    );
  }
}
