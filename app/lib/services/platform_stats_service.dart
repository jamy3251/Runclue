import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_safe.dart';

/// 플랫폼 전체 통계 — ExploreScreen 상단 스탯 바에 표시
class PlatformStats {
  final int totalParticipants;
  final int cumulativeEarnings; // ₩ 단위
  final int activeMissions;
  final int totalClues; // 등급제 (#25)용 — 모든 상태 포함

  const PlatformStats({
    this.totalParticipants = 0,
    this.cumulativeEarnings = 0,
    this.activeMissions = 0,
    this.totalClues = 0,
  });
}

class PlatformStatsService {
  final _client = safeClient;

  /// 플랫폼 전체 통계 조회.
  /// Supabase RPC `get_platform_stats` 가 있으면 사용, 없으면 개별 쿼리.
  Future<PlatformStats> getStats() async {
    try {
      // RPC 시도
      final result = await _client.rpc('get_platform_stats');
      if (result is Map<String, dynamic>) {
        return PlatformStats(
          totalParticipants: (result['total_participants'] as num?)?.toInt() ?? 0,
          cumulativeEarnings: (result['cumulative_earnings'] as num?)?.toInt() ?? 0,
          activeMissions: (result['active_missions'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {
      // RPC 없으면 개별 쿼리 fallback
    }

    try {
      final participantsResult = await _client
          .from('profiles')
          .select('id')
          .count();
      final missionsResult = await _client
          .from('clues')
          .select('id')
          .eq('status', 'active')
          .count();
      final allCluesResult = await _client.from('clues').select('id').count();

      return PlatformStats(
        totalParticipants: participantsResult.count,
        activeMissions: missionsResult.count,
        totalClues: allCluesResult.count,
        cumulativeEarnings: 0, // 별도 집계 테이블 필요
      );
    } catch (_) {
      return const PlatformStats();
    }
  }
}

/// Riverpod provider
final platformStatsProvider = FutureProvider<PlatformStats>((ref) async {
  return PlatformStatsService().getStats();
});
