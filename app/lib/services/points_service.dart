import '../config/supabase_safe.dart';

/// 미니게임/이벤트에서 호출 — 사용자 포인트 적립.
/// 1회 100p 제한 (악용 방지). 음수도 가능 (감점).
class PointsService {
  final _client = safeClient;

  Future<int?> add({
    required String userId,
    required int delta,
    String? reason,
  }) async {
    try {
      final res = await _client.rpc('add_user_points', params: {
        'user_id_in': userId,
        'delta_in': delta.clamp(-100, 100),
        'reason_in': reason,
      },);
      if (res is num) return res.toInt();
      return null;
    } catch (_) {
      // 적립 실패는 silent — 게임 흐름 안 막음
      return null;
    }
  }

  /// 만료 클루 일괄 정리 (운영 자동화).
  /// 홈 진입 시 호출 권장.
  Future<int> expireOverdueClues() async {
    try {
      final res = await _client.rpc('expire_overdue_clues');
      if (res is num) return res.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
