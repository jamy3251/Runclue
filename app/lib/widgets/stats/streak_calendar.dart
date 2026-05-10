import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 7-day streak calendar showing daily mission completion.
class StreakCalendar extends StatelessWidget {
  /// Which of the last 7 days are completed (index 0 = oldest, 6 = today)
  final List<bool> completedDays;
  final int streakCount;

  const StreakCalendar({
    super.key,
    required this.completedDays,
    this.streakCount = 0,
  });

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1; // 0=Mon

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          // Streak count
          if (streakCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 16, color: AppColors.brandRed),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCount일 연속!',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          // 7-day grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final done = index < completedDays.length && completedDays[index];
              final isToday = index == today;

              return Column(
                children: [
                  Text(
                    _weekdays[index],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.brandYellow : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? AppColors.brandYellow
                            : isToday
                                ? AppColors.brandYellow
                                : const Color(0xFF333333),
                        width: isToday && !done ? 1.5 : 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 18, color: Colors.black)
                          : Text(
                              '${index + 1}',
                              style: AppTextStyles.caption.copyWith(
                                color: isToday
                                    ? AppColors.brandYellow
                                    : AppColors.textDisabled,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
