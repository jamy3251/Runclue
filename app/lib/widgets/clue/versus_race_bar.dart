import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/race_provider.dart';

/// versus 클루 플레이 중 상단에 표시되는 실시간 레이스 바.
/// 참가자별 진행률을 가로 막대로 보여줘 "누가 앞섰는지" 경쟁감을 만든다.
/// 1등 독식이므로 1위 강조. 4초 폴링 (raceParticipantsProvider).
class VersusRaceBar extends ConsumerWidget {
  const VersusRaceBar({
    super.key,
    required this.clueId,
    required this.totalSteps,
  });

  final String clueId;
  final int totalSteps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final race = ref.watch(raceParticipantsProvider(clueId)).valueOrNull;
    final myId = ref.watch(currentUserIdProvider);
    if (race == null || race.length < 2) return const SizedBox.shrink();

    final someoneFinished = race.any((p) => p.isFinished);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.brandRed.withValues(alpha: 0.30),),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  size: 14, color: AppColors.brandRed,),
              const SizedBox(width: 4),
              Text(
                someoneFinished ? '경쟁 종료 — 1등 확정!' : '실시간 레이스 (1등 독식)',
                style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandRed,),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...race.take(4).map((p) {
            final isMe = p.userId == myId;
            final progress =
                (p.progressValue(totalSteps) / totalSteps).clamp(0.0, 1.0);
            final color = p.isFinished
                ? AppColors.brandYellow
                : (isMe ? AppColors.brandBlue : AppColors.textMuted);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      isMe ? '나' : p.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 10,
                          fontWeight:
                              isMe ? FontWeight.w900 : FontWeight.w500,
                          color: isMe
                              ? AppColors.brandBlue
                              : AppColors.textSecondary,),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.borderDefault,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.isFinished
                        ? '🏁'
                        : '${p.currentStepIndex + 1}/$totalSteps',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 10, color: AppColors.textMuted,),
                  ),
                ],
              ),
            );
          }),
          if (race.length > 4)
            Text('+${race.length - 4}명 경쟁 중',
                style: GoogleFonts.notoSansKr(
                    fontSize: 9, color: AppColors.textMuted,),),
        ],
      ),
    );
  }
}
