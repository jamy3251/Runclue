import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 사장 wallet 대시보드 데이터 (Step 17).
///
/// - wallet_topups: 사장 본인 토스 충전 기록 (RLS owner SELECT)
/// - clues.reward_pool_net/committed: 사장이 만든 클루별 남은 풀
/// - diamond_ledger source='store_revenue': 가게 메뉴 매출
class WalletService {
  final SupabaseClient _client = safeClient;

  /// 충전 요약 — gross/fee/net 합계.
  Future<({int gross, int fee, int net, int topupCount})> topupSummary(
      String ownerId,) async {
    final rows = await _client
        .from('wallet_topups')
        .select('gross_amount, fee_amount, net_amount, status')
        .eq('user_id', ownerId)
        .eq('status', 'approved');
    int gross = 0, fee = 0, net = 0;
    for (final r in rows) {
      gross += (r['gross_amount'] as int? ?? 0);
      fee += (r['fee_amount'] as int? ?? 0);
      net += (r['net_amount'] as int? ?? 0);
    }
    return (gross: gross, fee: fee, net: net, topupCount: rows.length);
  }

  /// 사장 충전 기록 (최신순).
  Future<List<Map<String, dynamic>>> myTopups(String ownerId,
      {int limit = 50,}) async {
    final rows = await _client
        .from('wallet_topups')
        .select('id, clue_id, gross_amount, fee_amount, net_amount, '
            'fee_rate_bps, toss_payment_key, toss_order_id, status, '
            'approved_at, raw_response, created_at, '
            'clues(title)')
        .eq('user_id', ownerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 내 클루별 남은 풀 (active 위주).
  Future<List<Map<String, dynamic>>> myCluePools(String ownerId,
      {int limit = 30,}) async {
    final rows = await _client
        .from('clues')
        .select('id, title, status, reward_pool_net, reward_pool_committed, '
            'current_participants, created_at, ends_at, game_mode, coop_state')
        .eq('creator_id', ownerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 가게 매출 — diamond_ledger source='store_revenue' (사장이 받은 다이아).
  Future<List<Map<String, dynamic>>> storeRevenue(String ownerId,
      {int limit = 50,}) async {
    final rows = await _client
        .from('diamond_ledger')
        .select('id, delta, source, source_id, balance_after, created_at')
        .eq('user_id', ownerId)
        .eq('source', 'store_revenue')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 방문→구매 전환 리포트 (K5) — 내 클루별 방문자/구매인증/전환율.
  /// security_invoker 뷰라 RLS로 본인 클루만 반환됨.
  Future<List<Map<String, dynamic>>> purchaseConversion(String ownerId,
      {int limit = 20,}) async {
    try {
      final rows = await _client
          .from('clue_purchase_conversion_v1')
          .select('clue_id, title, visitors, purchase_proofs, conversion_pct')
          .eq('creator_id', ownerId)
          .order('visitors', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  /// 가게 매출 합계.
  Future<int> storeRevenueSum(String ownerId) async {
    final rows = await _client
        .from('diamond_ledger')
        .select('delta')
        .eq('user_id', ownerId)
        .eq('source', 'store_revenue');
    int sum = 0;
    for (final r in rows) {
      sum += (r['delta'] as int? ?? 0);
    }
    return sum;
  }
}
