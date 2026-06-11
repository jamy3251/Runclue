import '../config/supabase_safe.dart';

/// 위치 기반 + 개인화 클루 추천 서비스.
/// Supabase RPC를 호출해서 점수 정렬된 추천 리스트를 반환.
class RecommendationService {
  final _client = safeClient;

  /// 사용자 위치 + ID 기반 추천 (홈 화면 "내 주변 추천" 섹션용).
  /// 점수: 거리 + 보상가치 + 인기 + 신선도 + 미참여 보너스 가중합.
  Future<List<Map<String, dynamic>>> recommendedForUser({
    required double lat,
    required double lng,
    required String userId,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final response = await _client.rpc('recommended_clues', params: {
        'user_lat': lat,
        'user_lng': lng,
        'user_id_in': userId,
        'radius_km': radiusKm,
        'max_results': limit,
      },);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // RPC 실패 시 빈 리스트 — 추천은 부수효과라 사용자 흐름 안 막음
      return [];
    }
  }

  /// 같은 상권 (특정 클루 위치 기준 N km 안의 다른 클루) — 클루 상세 페이지용.
  Future<List<Map<String, dynamic>>> sameDistrict({
    required String clueId,
    double radiusKm = 1.0,
    int limit = 6,
  }) async {
    try {
      final response = await _client.rpc('same_district_clues', params: {
        'origin_clue_id': clueId,
        'radius_km': radiusKm,
        'max_results': limit,
      },);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
