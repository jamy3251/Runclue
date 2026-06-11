import '../config/supabase_safe.dart';

class RoutineService {
  final _client = safeClient;

  Future<List<Map<String, dynamic>>> listMyRoutines(String userId) async {
    final res = await _client
        .from('routines')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> createRoutine({
    required String userId,
    required String name,
    required double lat,
    required double lng,
    int radiusM = 100,
    List<int> daysOfWeek = const [1, 2, 3, 4, 5],
    int startHour = 6,
    int endHour = 22,
  }) async {
    final res = await _client.from('routines').insert({
      'user_id': userId,
      'name': name,
      'target_lat': lat,
      'target_lng': lng,
      'radius_m': radiusM,
      'days_of_week': daysOfWeek,
      'start_hour': startHour,
      'end_hour': endHour,
    }).select().single();
    return res;
  }

  Future<void> deleteRoutine(String routineId) async {
    await _client.from('routines').delete().eq('id', routineId);
  }

  /// 체크인 — RPC로 위치 검증 + streak 갱신.
  /// 반환: {ok, streak, longest, distance_m} 또는 {ok:false, reason}
  Future<Map<String, dynamic>> checkin({
    required String routineId,
    required double lat,
    required double lng,
  }) async {
    final res = await _client.rpc('routine_checkin', params: {
      'routine_id_in': routineId,
      'user_lat': lat,
      'user_lng': lng,
    },);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unknown'};
  }
}
