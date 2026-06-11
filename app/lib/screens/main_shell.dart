import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// 바텀 네비게이션 쉘 — IA 재정비 (2026-06-11)
/// 5탭 한글 라벨: 홈 / 탐색 / 플레이 / 랭킹 / 내 정보
/// '플레이' = 배틀·미니게임·시즌·상점 게임 허브 (흩어진 진입점 통합)
/// 활성: #FACC15 + glow / 비활성: #555
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    void switchTab(int index, int current) {
      HapticFeedback.selectionClick();
      navigationShell.goBranch(index, initialLocation: index == current);
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.bgBase.withValues(alpha: 0.96),
                  AppColors.bgBase.withValues(alpha: 0.70),
                  AppColors.bgBase.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.local_fire_department_outlined,
                      activeIcon: Icons.local_fire_department,
                      label: '홈',
                      isActive: currentIndex == 0,
                      onTap: () => switchTab(0, currentIndex),
                    ),
                    _NavItem(
                      icon: Icons.search_outlined,
                      activeIcon: Icons.search,
                      label: '탐색',
                      isActive: currentIndex == 1,
                      onTap: () => switchTab(1, currentIndex),
                    ),
                    _NavItem(
                      icon: Icons.sports_esports_outlined,
                      activeIcon: Icons.sports_esports,
                      label: '플레이',
                      isActive: currentIndex == 2,
                      onTap: () => switchTab(2, currentIndex),
                    ),
                    _NavItem(
                      icon: Icons.emoji_events_outlined,
                      activeIcon: Icons.emoji_events,
                      label: '랭킹',
                      isActive: currentIndex == 3,
                      onTap: () => switchTab(3, currentIndex),
                    ),
                    _NavItem(
                      icon: Icons.star_outline,
                      activeIcon: Icons.star,
                      label: '내 정보',
                      isActive: currentIndex == 4,
                      onTap: () => switchTab(4, currentIndex),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandYellow : AppColors.textDisabled;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: color,
              shadows: isActive
                  ? [
                      Shadow(
                        color: AppColors.brandYellow.withValues(alpha: 0.6),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
