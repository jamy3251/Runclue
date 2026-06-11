import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 주간 시즌 #16 — 리더보드 + 보상.
/// KST 월~일 1주, 점수 = 완료 클루 × 100 + 코인 적립 합.
/// 종료 시 Top 10에 다이아 자동 분배 (500/300/200/100/100/50/50/50/50/50).
class SeasonService {
  final SupabaseClient _client = safeClient;

  /// 현재 KST 주의 시즌 보장 (없으면 자동 생성).
  /// 홈 진입 시 한 번 호출 권장 — cron 누락 대비.
  Future<Map<String, dynamic>> ensureCurrent() async {
    final res = await _client.rpc('ensure_current_season');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 시즌 리더보드 — season_id 없으면 활성 시즌.
  Future<List<Map<String, dynamic>>> leaderboard({
    String? seasonId,
    int topN = 100,
  }) async {
    final res = await _client.rpc('season_leaderboard', params: {
      'season_id_in': seasonId,
      'top_n': topN,
    },);
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// 내 시즌 보상 내역.
  Future<List<Map<String, dynamic>>> myRewards(String userId,
      {int limit = 30,}) async {
    final rows = await _client
        .from('season_rewards')
        .select('id, season_id, rank, score, reward_diamond, awarded_at, '
            'seasons(slug, start_at, end_at)')
        .eq('user_id', userId)
        .order('awarded_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 현재 활성 시즌 row.
  Future<Map<String, dynamic>?> currentSeason() async {
    final rows = await _client
        .from('seasons')
        .select('id, slug, start_at, end_at, status')
        .eq('status', 'active')
        .order('start_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }
}
