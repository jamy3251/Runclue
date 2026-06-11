import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 플랫폼 메타 등급 — 전체 클루수 + 전체 유저수 기반.
/// (둘 중 더 낮은 등급 기준 — 균형 성장 유도)
/// 인터뷰 피드백 "사용자숫자에 따른 등급의 계급화" 반영.

class PlatformGrade {
  final int level;
  final String name;
  final int clueThreshold;
  final int userThreshold;
  final IconData icon;
  final Color color;
  // 다음 등급 임계값 (-1 if 만렙)
  final int nextClueThreshold;
  final int nextUserThreshold;
  // 0~1 진행도 (clue + user 평균)
  final double progress;

  const PlatformGrade({
    required this.level,
    required this.name,
    required this.clueThreshold,
    required this.userThreshold,
    required this.icon,
    required this.color,
    required this.nextClueThreshold,
    required this.nextUserThreshold,
    required this.progress,
  });

  bool get isMax => nextClueThreshold < 0;
}

const _grades = <(int, String, IconData, Color)>[
  // (clueThr, userThr, name, icon, color) — 9단계
  (1,    '시드',         Icons.eco_outlined,           Color(0xFF94A3B8)),
  (10,   '클루',         Icons.explore_outlined,       AppColors.brandGreen),
  (50,   '비기너',       Icons.star_outline,           Color(0xFF60A5FA)),
  (100,  '프로',         Icons.workspace_premium,      Color(0xFFA855F7)),
  (300,  '브론즈',       Icons.emoji_events_outlined,  Color(0xFFCD7F32)),
  (500,  '실버',         Icons.emoji_events,           Color(0xFFC0C0C0)),
  (1000, '골드',         Icons.emoji_events,           AppColors.brandYellow),
  (2000, '플래티넘',     Icons.diamond_outlined,       Color(0xFF38BDF8)),
  (5000, '다이아',       Icons.diamond,                AppColors.brandPurple),
];

const _userThresholds = [10, 1000, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000];

PlatformGrade computePlatformGrade(int totalClues, int totalUsers) {
  // 둘 다 임계값 통과한 마지막 등급 찾기 (둘 중 약한 쪽이 발목)
  int idx = -1;
  for (int i = 0; i < _grades.length; i++) {
    final clueOk = totalClues >= _grades[i].$1;
    final userOk = totalUsers >= _userThresholds[i];
    if (clueOk && userOk) idx = i;
  }
  if (idx < 0) {
    // 시드 미만 — '준비중' 상태
    final clueProg = totalClues / _grades[0].$1;
    final userProg = totalUsers / _userThresholds[0];
    final p = ((clueProg + userProg) / 2).clamp(0.0, 1.0).toDouble();
    return PlatformGrade(
      level: 0,
      name: '준비중',
      clueThreshold: 0,
      userThreshold: 0,
      icon: Icons.hourglass_empty,
      color: AppColors.textMuted,
      nextClueThreshold: _grades[0].$1,
      nextUserThreshold: _userThresholds[0],
      progress: p,
    );
  }
  final cur = _grades[idx];
  final hasNext = idx + 1 < _grades.length;
  final nextClue = hasNext ? _grades[idx + 1].$1 : -1;
  final nextUser = hasNext ? _userThresholds[idx + 1] : -1;

  double progress = 1.0;
  if (hasNext) {
    final clueSpan = nextClue - cur.$1;
    final userSpan = nextUser - _userThresholds[idx];
    final clueIn = (totalClues - cur.$1).clamp(0, clueSpan);
    final userIn = (totalUsers - _userThresholds[idx]).clamp(0, userSpan);
    progress = ((clueIn / clueSpan + userIn / userSpan) / 2)
        .clamp(0.0, 1.0)
        .toDouble();
  }
  return PlatformGrade(
    level: idx + 1,
    name: cur.$2,
    clueThreshold: cur.$1,
    userThreshold: _userThresholds[idx],
    icon: cur.$3,
    color: cur.$4,
    nextClueThreshold: nextClue,
    nextUserThreshold: nextUser,
    progress: progress,
  );
}

/// 큰 카드 (admin dashboard 또는 home 상단용).
class PlatformGradeCard extends StatelessWidget {
  final int totalClues;
  final int totalUsers;
  const PlatformGradeCard({
    super.key,
    required this.totalClues,
    required this.totalUsers,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final g = computePlatformGrade(totalClues, totalUsers);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            g.color.withValues(alpha: 0.12),
            g.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: g.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: g.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(g.icon, color: g.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv ${g.level} · ${g.name} Clue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: g.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '플랫폼 등급',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('클루', _fmt(totalClues),
                  g.isMax ? null : '/ ${_fmt(g.nextClueThreshold)}', g.color,),
              const SizedBox(width: 12),
              _stat('러너', _fmt(totalUsers),
                  g.isMax ? null : '/ ${_fmt(g.nextUserThreshold)}', g.color,),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: g.progress,
              minHeight: 6,
              backgroundColor: AppColors.borderDefault,
              valueColor: AlwaysStoppedAnimation<Color>(g.color),
            ),
          ),
          const SizedBox(height: 6),
          if (!g.isMax)
            Text(
              '${(g.progress * 100).toInt()}% — 다음 등급까지',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            )
          else
            const Text(
              '🏆 만렙',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String now, String? max, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgBase.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  now,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                if (max != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      max,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted,),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
