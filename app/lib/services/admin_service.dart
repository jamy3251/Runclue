import '../config/supabase_safe.dart';

/// 관리자 전용 서비스. is_admin() RPC + admin RLS 정책에 의존.
/// 일반 사용자가 호출 시 RLS가 차단해서 빈 결과/실패 반환.
class AdminService {
  final _client = safeClient;

  /// 현재 사용자가 admin인지 확인.
  Future<bool> isCurrentUserAdmin() async {
    try {
      final res = await _client.rpc('is_admin');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// 전체 클루 목록 (모든 status 포함).
  Future<List<Map<String, dynamic>>> listAllClues({int limit = 100}) async {
    try {
      final res = await _client
          .from('clues')
          .select('*, creator:profiles!creator_id(nickname)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// 클루 상태 변경 (active / suspended / pending / completed 등).
  Future<void> updateClueStatus(String clueId, String status) async {
    await _client.from('clues').update({'status': status}).eq('id', clueId);
  }

  /// 클루 강제 삭제 (admin 권한 — soft delete가 아니라 row 제거).
  Future<void> hardDeleteClue(String clueId) async {
    await _client.from('clues').delete().eq('id', clueId);
  }

  /// 전체 보상 목록 (최근 발급 순).
  Future<List<Map<String, dynamic>>> listAllRewards({int limit = 100}) async {
    try {
      final res = await _client
          .from('rewards')
          .select('*, user:profiles!user_id(nickname), clue:clues!clue_id(title)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  // ── 기프티콘 운영 (수동 SQL 대체 — OWNER_TODO §7) ──

  /// 전체 기프티콘 카탈로그 (비활성 포함 — admin RLS).
  Future<List<Map<String, dynamic>>> listGifticons() async {
    try {
      final res = await _client
          .from('gifticons')
          .select('*')
          .order('display_order');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// 기프티콘 등록.
  Future<void> createGifticon({
    required String partnerBrand,
    required String name,
    required int valueKrw,
    required int diamondCost,
    required int stock,
    String? imageUrl,
  }) async {
    await _client.from('gifticons').insert({
      'partner_brand': partnerBrand,
      'name': name,
      'value_krw': valueKrw,
      'diamond_cost': diamondCost,
      'stock': stock,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      'display_order': 100,
      'active': true,
    });
  }

  /// 기프티콘 수정 (재고/활성 토글 등).
  Future<void> updateGifticon(String id, Map<String, dynamic> fields) async {
    await _client.from('gifticons').update(fields).eq('id', id);
  }

  /// 발급 대기 중인 교환 요청 (pending) — 운영자 발급 큐.
  Future<List<Map<String, dynamic>>> pendingRedemptions(
      {int limit = 50,}) async {
    try {
      final res = await _client
          .from('redemptions')
          .select('*, user:profiles!user_id(nickname), '
              'gifticon:gifticons!gifticon_id(name, partner_brand)')
          .eq('status', 'pending')
          .order('created_at')
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// 쿠폰코드 입력 → 발급 완료 처리.
  Future<void> issueRedemption(String redemptionId, String couponCode) async {
    await _client.from('redemptions').update({
      'coupon_code': couponCode,
      'status': 'issued',
      'issued_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(days: 90))
          .toIso8601String(),
    }).eq('id', redemptionId);
  }

  /// 플랫폼 통계 — 핵심 KPI 한 번에.
  Future<Map<String, int>> getStats() async {
    int countSafe(dynamic v) =>
        v is List ? v.length : (v is num ? v.toInt() : 0);
    try {
      final clues = await _client.from('clues').select('id');
      final activeClues =
          await _client.from('clues').select('id').eq('status', 'active');
      final users = await _client.from('profiles').select('id');
      final participations =
          await _client.from('participations').select('id');
      final rewards = await _client.from('rewards').select('id');
      final unclaimedRewards =
          await _client.from('rewards').select('id').eq('is_claimed', false);

      return {
        'totalClues': countSafe(clues),
        'activeClues': countSafe(activeClues),
        'totalUsers': countSafe(users),
        'totalParticipations': countSafe(participations),
        'totalRewards': countSafe(rewards),
        'unclaimedRewards': countSafe(unclaimedRewards),
      };
    } catch (e) {
      return {};
    }
  }
}
