import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 기프티콘 카탈로그 + 교환 (트랙 E, Step 15).
class GifticonService {
  final SupabaseClient _client = safeClient;

  /// 활성 카탈로그 — 다이아 사용처.
  Future<List<Map<String, dynamic>>> catalog() async {
    final rows = await _client
        .from('gifticons')
        .select('id, partner_brand, name, description, value_krw, '
            'diamond_cost, image_url, stock, display_order')
        .eq('active', true)
        .order('display_order')
        .order('diamond_cost');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// 다이아 차감 + 재고 차감 + redemption pending 생성.
  /// 반환: {ok, redemption_id, diamond_cost, balance_after, partner_brand, name}
  Future<Map<String, dynamic>> redeem(String gifticonId) async {
    final res = await _client.rpc('redeem_gifticon', params: {
      'gifticon_id_in': gifticonId,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 내 교환 내역 (최신순).
  Future<List<Map<String, dynamic>>> myRedemptions({int limit = 50}) async {
    final rows = await _client
        .from('redemptions')
        .select('id, gifticon_id, diamond_cost, status, coupon_code, '
            'issued_at, expires_at, created_at, '
            'gifticons(partner_brand, name, value_krw, image_url)')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
