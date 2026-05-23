import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 일일 출석 + 일일 미션 (트랙 E).
///
/// quest_key 4종:
///   attendance     · +5 코인, 7일 streak +30 보너스
///   first_clue     · 오늘 첫 클루 완료 +20
///   first_comment  · 오늘 첫 댓글 +20
///   first_minigame · 오늘 첫 미니게임 플레이 +10
///
/// 모든 검증은 서버 측 (claim_quest_reward RPC).
class QuestService {
  final SupabaseClient _client = safeClient;

  /// 오늘 미션 진행 + 보상 수령 상태. UI 카드 렌더용.
  Future<Map<String, dynamic>> todayStatus() async {
    final res = await _client.rpc('today_quest_status');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// quest_key 보상 수령. 조건 미충족 / 이미 받음 시 ok=false + reason.
  Future<Map<String, dynamic>> claim(String questKey) async {
    final res = await _client.rpc('claim_quest_reward', params: {
      'quest_key_in': questKey,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }
}
