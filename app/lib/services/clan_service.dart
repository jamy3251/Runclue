import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 클랜 대항전 (041) — 학교/동아리 팀 주간 경쟁.
/// 미션 완료마다 자동으로 클랜 주간 점수 +10 (DB 트리거).
class ClanService {
  final SupabaseClient _client = safeClient;

  /// 내가 속한 클랜 (없으면 null).
  Future<Map<String, dynamic>?> myClan(String userId) async {
    final row = await _client
        .from('clan_members')
        .select('role, clans(id, name, description, member_count, total_points, avatar_url)')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    final clan = row['clans'] as Map<String, dynamic>?;
    if (clan == null) return null;
    return {...clan, 'my_role': row['role']};
  }

  /// 주간 대항전 리더보드.
  Future<List<Map<String, dynamic>>> weeklyLeaderboard({int limit = 30}) async {
    final rows = await _client
        .from('clan_weekly_leaderboard')
        .select('clan_id, name, avatar_url, member_count, week_points, active_members')
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> createClan(String name,
      {String? description,}) async {
    final res = await _client.rpc('create_clan', params: {
      'name_in': name,
      if (description != null) 'description_in': description,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  Future<Map<String, dynamic>> joinClan(String clanId) async {
    final res =
        await _client.rpc('join_clan', params: {'clan_id_in': clanId});
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  Future<Map<String, dynamic>> leaveClan() async {
    final res = await _client.rpc('leave_clan');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }
}
