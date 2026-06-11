import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_safe.dart';

/// versus/coop 레이스 — 같은 클루 참가자들의 실시간 진행률 (033 RLS 필요).
///
/// 4초 폴링. coopStateProvider(5초)와 같은 패턴 — Realtime 구독보다 단순하고
/// 레이스 화면이 떠 있는 동안만 동작.
class RaceParticipant {
  final String userId;
  final String nickname;
  final int currentStepIndex;
  final String status;
  final DateTime? completedAt;

  const RaceParticipant({
    required this.userId,
    required this.nickname,
    required this.currentStepIndex,
    required this.status,
    this.completedAt,
  });

  bool get isFinished => status == 'completed';

  /// 완료자는 진행률 최댓값으로, 진행 중은 current_step_index 기준.
  int progressValue(int totalSteps) =>
      isFinished ? totalSteps : currentStepIndex;
}

final raceParticipantsProvider =
    StreamProvider.family<List<RaceParticipant>, String>((ref, clueId) async* {
  while (true) {
    try {
      final rows = await safeClient
          .from('participations')
          .select(
              'user_id, current_step_index, status, completed_at, profiles:user_id(nickname)',)
          .eq('clue_id', clueId)
          .inFilter('status', ['in_progress', 'completed']);
      final list = List<Map<String, dynamic>>.from(rows).map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        return RaceParticipant(
          userId: r['user_id'] as String,
          nickname: profile?['nickname'] as String? ?? '익명',
          currentStepIndex: r['current_step_index'] as int? ?? 0,
          status: r['status'] as String? ?? 'in_progress',
          completedAt: r['completed_at'] != null
              ? DateTime.tryParse(r['completed_at'] as String)
              : null,
        );
      }).toList();
      // 완료자 먼저 (완료 시간순), 다음 진행률 내림차순
      list.sort((a, b) {
        if (a.isFinished != b.isFinished) return a.isFinished ? -1 : 1;
        if (a.isFinished && b.isFinished) {
          return (a.completedAt ?? DateTime(2100))
              .compareTo(b.completedAt ?? DateTime(2100));
        }
        return b.currentStepIndex.compareTo(a.currentStepIndex);
      });
      yield list;
    } catch (_) {
      yield const <RaceParticipant>[];
    }
    await Future<void>.delayed(const Duration(seconds: 4));
  }
});
