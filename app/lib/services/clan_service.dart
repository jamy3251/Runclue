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

  // ── 클랜 상세 (042) ──

  /// 클랜 정보 단건.
  Future<Map<String, dynamic>?> clanById(String clanId) async {
    final row = await _client
        .from('clans')
        .select('id, name, description, member_count, total_points, '
            'avatar_url, leader_id, created_at')
        .eq('id', clanId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  /// 멤버 목록 + 이번 주 기여 점수.
  Future<List<Map<String, dynamic>>> clanMembers(String clanId) async {
    final rows = await _client
        .from('clan_members')
        .select('user_id, role, joined_at, profiles(nickname, avatar_url)')
        .eq('clan_id', clanId)
        .order('joined_at');
    final members = List<Map<String, dynamic>>.from(rows);

    // 이번 주 기여 점수 (clan_war_scores 합산)
    try {
      final scores = await _client
          .from('clan_war_scores')
          .select('user_id, points')
          .eq('clan_id', clanId);
      final byUser = <String, int>{};
      for (final s in scores) {
        final uid = s['user_id'] as String;
        byUser[uid] = (byUser[uid] ?? 0) + (s['points'] as int? ?? 0);
      }
      for (final m in members) {
        m['week_points'] = byUser[m['user_id']] ?? 0;
      }
    } catch (_) {/* 점수 없으면 0 */}
    members.sort((a, b) =>
        (b['week_points'] as int? ?? 0).compareTo(a['week_points'] as int? ?? 0),);
    return members;
  }

  // ── 클랜 채팅 (042) ──

  /// 실시간 메시지 스트림 (초기 로드 + INSERT 실시간 수신).
  Stream<List<Map<String, dynamic>>> messageStream(String clanId) {
    return _client
        .from('clan_messages')
        .stream(primaryKey: ['id'])
        .eq('clan_id', clanId)
        .order('created_at')
        .limit(100)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  Future<void> sendMessage({
    required String clanId,
    required String userId,
    required String nickname,
    required String content,
  }) async {
    await _client.from('clan_messages').insert({
      'clan_id': clanId,
      'user_id': userId,
      'nickname': nickname,
      'content': content,
    });
  }
}
