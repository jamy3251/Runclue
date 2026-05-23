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
