import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Horizontal scrollable pill filter tabs
class CategoryFilterTabs extends StatelessWidget {
  final List<FilterTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryFilterTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;
          final tab = tabs[index];
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandYellow
                    : const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.icon != null) ...[
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isActive ? Colors.black : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    tab.label,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? Colors.black : AppColors.textMuted,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FilterTab {
  final String label;
  final IconData? icon;
  const FilterTab({required this.label, this.icon});
}

/// Sort filter tabs — underline style
class SortFilterTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SortFilterTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.brandYellow
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive
                        ? AppColors.brandYellow
                        : AppColors.textDisabled,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
