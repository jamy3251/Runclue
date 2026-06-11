import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// Battle 보상 모드 (#22/#24) — 코인 베팅 1v1 미니게임.
/// 비동기 큐 + 5분 후 CPU fallback (cron).
/// game_type: 'rps'(가위바위보) | 'tap'(서로 때리기) | 'coin_grab'(동전 줍기)
class BattleService {
  final SupabaseClient _client = safeClient;

  /// 큐 진입 + 즉시 매칭 시도. 반환: {ok, match_id, status, opponent_id, vs_cpu, role}
  Future<Map<String, dynamic>> enqueue({
    required int stakeCoin,
    String gameType = 'rps',
    String? clueId,
  }) async {
    final res = await _client.rpc('battle_enqueue', params: {
      'stake_coin_in': stakeCoin,
      'game_type_in': gameType,
      if (clueId != null) 'clue_id_in': clueId,
    },);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 결과 확정. 양측 호출 시 두 번째 호출에서 winner 확정.
  /// choice — rps: 'rock'|'paper'|'scissors', tap/coin_grab: 점수 문자열 (예: '87')
  Future<Map<String, dynamic>> finish({
    required String matchId,
    required String choice,
  }) async {
    final res = await _client.rpc('battle_finish', params: {
      'match_id_in': matchId,
      'my_choice_in': choice,
    },);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  Future<Map<String, dynamic>> cancel(String matchId) async {
    final res = await _client.rpc('battle_cancel', params: {
      'match_id_in': matchId,
    },);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 매치 정보 조회 (polling용).
  Future<Map<String, dynamic>?> fetchMatch(String matchId) async {
    final row = await _client
        .from('battle_matches')
        .select('id, game_type, stake_coin, challenger_id, opponent_id, '
            'vs_cpu, status, challenger_choice, opponent_choice, '
            'winner_id, payout_to_winner, fee_coin, '
            'created_at, matched_at, finished_at')
        .eq('id', matchId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  /// 본인 최근 battle 히스토리.
  Future<List<Map<String, dynamic>>> myHistory(String userId,
      {int limit = 30,}) async {
    final rows = await _client
        .from('battle_matches')
        .select('id, game_type, stake_coin, challenger_id, opponent_id, '
            'vs_cpu, status, winner_id, payout_to_winner, '
            'finished_at, created_at')
        .or('challenger_id.eq.$userId,opponent_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
