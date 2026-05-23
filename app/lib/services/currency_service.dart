import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 코인 + 다이아 이중 통화 (트랙 E).
/// - 코인: 무료 채널(광고/미니게임/걸음수/출석·미션) — grantCoin RPC + 일일 캡 500
/// - 다이아: 토스 결제로만 적립 — 클라이언트는 잔액 조회만 (적립은 Edge Function)
class CurrencyService {
  final SupabaseClient _client = safeClient;

  /// 코인 적립/차감. delta ±100 단발 한도, 일일 +500 캡.
  /// reason: 'ad' | 'minigame_win' | 'minigame_lose' | 'walk' | 'attendance'
  ///       | 'quest' | 'spend_*' | 'admin_grant'
  Future<Map<String, dynamic>> grantCoin({
    required String userId,
    required int delta,
    required String reason,
    String? sourceId,
  }) async {
    final res = await _client.rpc('grant_coin', params: {
      'user_id_in': userId,
      'delta_in': delta,
      'reason_in': reason,
      if (sourceId != null) 'source_id_in': sourceId,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 현재 잔액 조회 — profiles 한 줄.
  Future<({int coin, int diamond})> fetchBalances(String userId) async {
    final row = await _client
        .from('profiles')
        .select('coin_balance, diamond_balance')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return (coin: 0, diamond: 0);
    return (
      coin: (row['coin_balance'] as int?) ?? 0,
      diamond: (row['diamond_balance'] as int?) ?? 0,
    );
  }

  /// 오늘 코인 적립 누계 — 일일 캡 도달 여부 클라이언트 표시용.
  Future<int> todayCoinEarned(String userId) async {
    // KST 자정 (UTC -9 -> +9이므로 Asia/Seoul 기준)
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final today =
        DateTime(nowKst.year, nowKst.month, nowKst.day).toIso8601String();
    final rows = await _client
        .from('coin_ledger')
        .select('delta')
        .eq('user_id', userId)
        .gte('day_date', today.substring(0, 10))
        .gt('delta', 0);
    int sum = 0;
    for (final r in rows) {
      sum += (r['delta'] as int? ?? 0);
    }
    return sum;
  }

  /// 최근 코인 ledger 항목 — 프로필 화면 "최근 적립" 리스트용.
  Future<List<Map<String, dynamic>>> recentCoinLedger(
    String userId, {
    int limit = 30,
  }) async {
    final rows = await _client
        .from('coin_ledger')
        .select('id, delta, reason, source_id, balance_after, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 최근 다이아 ledger 항목.
  Future<List<Map<String, dynamic>>> recentDiamondLedger(
    String userId, {
    int limit = 30,
  }) async {
    final rows = await _client
        .from('diamond_ledger')
        .select('id, delta, source, source_id, balance_after, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
