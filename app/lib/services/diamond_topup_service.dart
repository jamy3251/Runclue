import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 사용자 다이아 충전 (032) — 토스 결제로 다이아 패키지 구매.
///
/// 플로우:
///   1. [fetchPackages] 카탈로그 표시
///   2. [createOrder] pending 주문 생성 → order_id/amount 반환
///   3. 외부 브라우저에서 토스 결제 (pay.html)
///   4. pay-success.html → toss-diamond-confirm Edge Function → 적립
///   5. 앱 복귀 시 balancesProvider invalidate로 잔액 갱신
class DiamondTopupService {
  final SupabaseClient _client = safeClient;

  /// 활성 다이아 패키지 목록 (가격 오름차순).
  Future<List<Map<String, dynamic>>> fetchPackages() async {
    final rows = await _client
        .from('diamond_packages')
        .select('id, name, diamond_amount, price_krw, bonus_label')
        .eq('active', true)
        .order('display_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// pending 주문 생성. 반환: {ok, order_id, amount, diamond_amount, order_name}
  Future<Map<String, dynamic>> createOrder(String packageId) async {
    final res = await _client.rpc('create_diamond_order', params: {
      'package_id_in': packageId,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 본인 충전 내역 (최신순).
  Future<List<Map<String, dynamic>>> myTopups({int limit = 30}) async {
    final rows = await _client
        .from('diamond_topups')
        .select('id, diamond_amount, price_krw, order_id, status, '
            'approved_at, created_at')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 주문 상태 polling (결제 후 앱 복귀 시 승인 확인용).
  Future<String?> orderStatus(String orderId) async {
    final row = await _client
        .from('diamond_topups')
        .select('status')
        .eq('order_id', orderId)
        .maybeSingle();
    return row?['status'] as String?;
  }
}
