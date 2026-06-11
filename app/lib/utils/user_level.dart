import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 유저 레벨 — total_points 기반 순수 함수.
/// 인터뷰 (CTO) "유저 레벨 별 차등이 필요" 반영.
/// 차등 보상 시스템은 v2에서. 지금은 표시만 (게이미피케이션 동기 부여).

class UserLevel {
  final int level;
  final String name;
  final IconData icon;
  final Color color;
  final int currentTier;     // 이번 레벨 진입 점수
  final int nextTier;        // 다음 레벨 진입 점수 (-1 if 만렙)
  final double progress;     // 0.0 ~ 1.0 (현재 → 다음까지 비율)
  final int points;          // 사용자 누적 점수 (계산 input)
  final int multiplierBps;   // 코인 적립 배수 (basis points, 10000=1.0×)

  const UserLevel({
    required this.level,
    required this.name,
    required this.icon,
    required this.color,
    required this.currentTier,
    required this.nextTier,
    required this.progress,
    required this.points,
    required this.multiplierBps,
  });

  bool get isMax => nextTier < 0;
  int get pointsToNext => isMax ? 0 : nextTier - points;

  /// "+20%" 처럼 표시할 텍스트 (1.0×면 빈 문자열).
  String get multiplierLabel {
    if (multiplierBps <= 10000) return '';
    final pct = ((multiplierBps - 10000) / 100).round();
    return '+$pct%';
  }
}

/// 레벨 임계값 (point, 한국어 이름, 아이콘, 컬러, multiplier bps).
/// multiplier는 user_level_multiplier_bps RPC와 일관 유지 (마이그레이션 027).
const _tiers = <(int, String, IconData, Color, int)>[
  (0,     '새싹',     Icons.eco,                     AppColors.brandGreen,    10000),
  (100,   '브론즈',    Icons.workspace_premium,       Color(0xFFCD7F32),       10500),
  (500,   '실버',     Icons.workspace_premium,       Color(0xFFC0C0C0),       11000),
  (2000,  '골드',     Icons.workspace_premium,       AppColors.brandYellow,   12000),
  (5000,  '플래티넘',  Icons.diamond,                 Color(0xFF38BDF8),       13500),
  (10000, '다이아',   Icons.diamond,                 AppColors.brandPurple,   15000),
];

UserLevel computeLevel(int points) {
  // 가장 큰 임계 통과한 인덱스 찾기.
  int idx = 0;
  for (int i = 0; i < _tiers.length; i++) {
    if (points >= _tiers[i].$1) idx = i;
  }
  final tier = _tiers[idx];
  final hasNext = idx + 1 < _tiers.length;
  final nextThr = hasNext ? _tiers[idx + 1].$1 : -1;
  final span = hasNext ? (nextThr - tier.$1) : 1;
  final inLevel = (points - tier.$1).clamp(0, span);
  final progress = hasNext ? inLevel / span : 1.0;

  return UserLevel(
    level: idx + 1,
    name: tier.$2,
    icon: tier.$3,
    color: tier.$4,
    currentTier: tier.$1,
    nextTier: nextThr,
    progress: progress.toDouble(),
    points: points,
    multiplierBps: tier.$5,
  );
}

/// 작은 레벨 뱃지 (이름 옆에 붙는 칩).
class UserLevelChip extends StatelessWidget {
  final int points;
  final bool dense;
  const UserLevelChip({super.key, required this.points, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final lv = computeLevel(points);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8, vertical: dense ? 2 : 3,),
      decoration: BoxDecoration(
        color: lv.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(dense ? 4 : 6),
        border: Border.all(color: lv.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lv.icon, size: dense ? 10 : 12, color: lv.color),
          SizedBox(width: dense ? 3 : 4),
          Text(
            'Lv${lv.level} ${lv.name}',
            style: TextStyle(
              fontSize: dense ? 9 : 11,
              color: lv.color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (lv.multiplierLabel.isNotEmpty) ...[
            SizedBox(width: dense ? 3 : 4),
            Text(
              lv.multiplierLabel,
              style: TextStyle(
                fontSize: dense ? 8 : 10,
                color: lv.color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 큰 레벨 카드 (프로필 화면용 — 진행도 바 포함).
class UserLevelCard extends StatelessWidget {
  final int points;
  const UserLevelCard({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final lv = computeLevel(points);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lv.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lv.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(lv.icon, color: lv.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Lv ${lv.level} · ${lv.name}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: lv.color,),),
                        if (lv.multiplierLabel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2,),
                            decoration: BoxDecoration(
                              color: lv.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🪙 ${lv.multiplierLabel} 보너스',
                              style: TextStyle(
                                fontSize: 10,
                                color: lv.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('$points P 누적',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,),),
                  ],
                ),
              ),
              if (!lv.isMax)
                Text('${lv.nextTier - points} P 남음',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted,),)
              else
                const Text('만렙 🎉',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.brandYellow,
                        fontWeight: FontWeight.w700,),),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lv.progress,
              minHeight: 6,
              backgroundColor: AppColors.borderDefault,
              valueColor: AlwaysStoppedAnimation<Color>(lv.color),
            ),
          ),
        ],
      ),
    );
  }
}
