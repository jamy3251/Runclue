import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import 'common/badge_chip.dart';

class ClueCard extends StatelessWidget {
  final String title;
  final String creatorName;
  final String category;
  final String locationText;
  final int participantCount;
  final String? thumbnailUrl;
  final String? rewardText;
  final String? statusBadge; // LIVE, HOT, NEW, ACTIVE, CLOSED
  final double? progressPercent; // 0.0 ~ 1.0
  final String? distanceText; // e.g. "0.3km"
  final String? creatorAvatarUrl;
  final String? timeRemaining; // e.g. "23분 남음"
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const ClueCard({
    super.key,
    required this.title,
    required this.creatorName,
    required this.category,
    this.locationText = '온라인',
    this.participantCount = 0,
    this.thumbnailUrl,
    this.rewardText,
    this.statusBadge,
    this.progressPercent,
    this.distanceText,
    this.creatorAvatarUrl,
    this.timeRemaining,
    this.compact = false,
    this.onTap,
    this.onLike,
  });

  Color get _statusColor => switch (statusBadge) {
    'LIVE' => AppColors.brandRed,
    'HOT' => AppColors.brandOrange,
    'NEW' => AppColors.brandGreen,
    'ACTIVE' => AppColors.brandBlue,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact() : _buildFull();
  }

  Widget _buildCompact() {
    return _TapWrapper(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [AppShadows.card],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (statusBadge != null)
                  BadgeChip(label: statusBadge!, color: _statusColor, small: true),
                const Spacer(),
                if (rewardText != null)
                  Text(
                    rewardText!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandYellow,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                if (distanceText != null) ...[
                  Icon(Icons.location_on, size: 10, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    distanceText!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull() {
    return _TapWrapper(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [AppShadows.card],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: badges + like
            Row(
              children: [
                BadgeChip(label: category, color: AppColors.brandBlue, small: true),
                if (statusBadge != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  BadgeChip(label: statusBadge!, color: _statusColor, small: true),
                ],
                const Spacer(),
                if (onLike != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onLike?.call();
                    },
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Row 2: title
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Row 3: location · distance · participants
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    locationText,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceText != null) ...[
                  Text(
                    ' · $distanceText',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.people, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text(
                  '$participantCount명',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),

            // Row 4: progress bar (optional)
            if (progressPercent != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: const Color(0x14FFFFFF)),
                            FractionallySizedBox(
                              widthFactor: progressPercent!.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppGradients.progress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(progressPercent! * 100).toInt()}%',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  if (timeRemaining != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      timeRemaining!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ],

            // Row 5: creator + reward
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Creator avatar
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.bgElevated,
                  backgroundImage: creatorAvatarUrl != null
                      ? NetworkImage(creatorAvatarUrl!)
                      : null,
                  child: creatorAvatarUrl == null
                      ? Text(
                          creatorName.isNotEmpty ? creatorName[0] : '?',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '@$creatorName',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (rewardText != null)
                  Text(
                    rewardText!,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandYellow,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap scale + haptic wrapper
class _TapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapWrapper({required this.child, this.onTap});

  @override
  State<_TapWrapper> createState() => _TapWrapperState();
}

class _TapWrapperState extends State<_TapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
