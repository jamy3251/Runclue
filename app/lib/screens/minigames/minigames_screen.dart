import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

/// 미니게임 허브 — 4종.
/// 솔로/CPU 연습 모드 + PvP 베팅 대전 진입 (battle 모드, #22/#24).
/// 오셀로는 턴제 특성상 PvP 미지원 (솔로 전용).
class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key});

  static const _games = <_GameMeta>[
    _GameMeta(
      title: '가위바위보',
      subtitle: '3초 안에 결판',
      icon: Icons.front_hand,
      color: AppColors.brandRed,
      route: '/minigames/rps',
    ),
    _GameMeta(
      title: '동전 줍기',
      subtitle: '15초 탭 경쟁',
      icon: Icons.monetization_on,
      color: AppColors.brandYellow,
      route: '/minigames/coin',
    ),
    _GameMeta(
      title: '서로 때리기',
      subtitle: '탭 연사 vs 방어',
      icon: Icons.sports_mma,
      color: AppColors.brandOrange,
      route: '/minigames/tap',
    ),
    _GameMeta(
      title: '오셀로',
      subtitle: '6×6 미니 보드',
      icon: Icons.grid_4x4,
      color: AppColors.brandPurple,
      route: '/minigames/othello',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '미니게임',
          style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/battle');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.brandRed.withValues(alpha: 0.14),
                  AppColors.brandYellow.withValues(alpha: 0.08),
                ],),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.brandRed.withValues(alpha: 0.35),),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_kabaddi,
                      color: AppColors.brandRed, size: 20,),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PvP 베팅 대전',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandRed,),
                        ),
                        Text(
                          '코인을 걸고 실시간 대결 — 이기면 베팅 × 1.9',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 11, color: AppColors.textSecondary,),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.brandRed, size: 20,),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.brandPurple, size: 16,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '아래는 솔로 연습 모드 — 무료로 플레이하고 코인 적립',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 11, color: AppColors.brandPurple,),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _games.length,
            itemBuilder: (_, i) {
              final g = _games[i];
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(g.route);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: g.color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(g.icon, color: g.color, size: 26),
                      ),
                      const Spacer(),
                      Text(
                        g.title,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g.subtitle,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 11, color: AppColors.textMuted,),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _GameMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
