import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 보상함(rewards 테이블) 조회·수령 서비스.
///
/// rewards 테이블:
///   type ∈ ('points','badge','coupon','prize','raffle')
///   is_claimed: 미수령(false=선물함) / 수령(true=인벤토리)
///   expires_at: 만료 (null이면 무기한)
class RewardService {
  final SupabaseClient _client = safeClient;

  /// 내 미수령 보상(선물함). clue 메타 조인은 실패하면 자동 폴백.
  Future<List<Map<String, dynamic>>> getUnclaimed(String userId) =>
      _fetch(userId, claimed: false);

  /// 내 수령한 보상(인벤토리).
  Future<List<Map<String, dynamic>>> getClaimed(String userId) =>
      _fetch(userId, claimed: true);

  /// 선물함 미수령 카운트 (배지용). 실패 시 0.
  Future<int> unclaimedCount(String userId) async {
    try {
      final r = await _client
          .from('rewards')
          .select('id')
          .eq('user_id', userId)
          .eq('is_claimed', false);
      return (r as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// 보상 수령 — is_claimed=true, claimed_at=now.
  /// 이미 수령한 row여도 idempotent하게 처리.
  Future<Map<String, dynamic>> claim(String rewardId) async {
    try {
      final response = await _client
          .from('rewards')
          .update({
            'is_claimed': true,
            'claimed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rewardId)
          .select()
          .single();
      return response;
    } on PostgrestException catch (e) {
      // claimed_at 컬럼이 없는 환경에서도 동작하도록 폴백
      if (e.code == 'PGRST204') {
        final response = await _client
            .from('rewards')
            .update({'is_claimed': true})
            .eq('id', rewardId)
            .select()
            .single();
        return response;
      }
      throw Exception('보상 수령 실패 [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('보상 수령 실패: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(
    String userId, {
    required bool claimed,
  }) async {
    // 1차: clue 메타 함께 (선물함에 클루 제목·썸네일 노출용)
    try {
      final response = await _client
          .from('rewards')
          .select('*, clue:clues(id, title, thumbnail_url, reward_label)')
          .eq('user_id', userId)
          .eq('is_claimed', claimed)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {/* 2차 폴백 */}

    // 2차: 단순 조회 (FK 없거나 RLS 영향)
    try {
      final response = await _client
          .from('rewards')
          .select('*')
          .eq('user_id', userId)
          .eq('is_claimed', claimed)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
