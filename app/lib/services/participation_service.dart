import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipationService {
  final SupabaseClient _client = safeClient;

  /// Join a clue — participation 생성 + clues.current_participants 증가
  Future<Map<String, dynamic>> joinClue({
    required String clueId,
    required String userId,
    String? clanId,
  }) async {
    try {
      // 이미 참여한 적이 있는지 확인 — 중복 join 방지
      final existing = await _client
          .from('participations')
          .select('*')
          .eq('clue_id', clueId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) {
        // 기존 참여 row 반환 (재진입)
        return existing;
      }

      final data = {
        'clue_id': clueId,
        'user_id': userId,
        'status': 'in_progress',
        'current_step_index': 0,
        if (clanId != null) 'clan_id': clanId,
      };

      final response = await _client
          .from('participations')
          .insert(data)
          .select()
          .single();

      // current_participants +1 (실패해도 무시 — 카운터는 부수효과)
      try {
        await _client.rpc('increment_clue_participants',
            params: {'clue_id_param': clueId});
      } catch (_) {
        // RPC 없으면 직접 UPDATE
        try {
          final clue = await _client
              .from('clues')
              .select('current_participants')
              .eq('id', clueId)
              .maybeSingle();
          final cur = (clue?['current_participants'] as int?) ?? 0;
          await _client
              .from('clues')
              .update({'current_participants': cur + 1}).eq('id', clueId);
        } catch (_) {/* 스키마 없어도 무시 */}
      }

      return response;
    } catch (e) {
      throw Exception('참여 등록 실패: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyParticipations(String userId) async {
    try {
      final response = await _client
          .from('participations')
          .select('*, clues(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch participations: $e');
    }
  }

  Future<Map<String, dynamic>?> getParticipation(
    String clueId,
    String userId,
  ) async {
    try {
      final response = await _client
          .from('participations')
          .select('*, clues(*), steps(*)')
          .eq('clue_id', clueId)
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch participation: $e');
    }
  }

  Future<Map<String, dynamic>> updateProgress(
    String participationId,
    int stepIndex,
  ) async {
    var payload = <String, dynamic>{
      'current_step_index': stepIndex,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return _safeUpdate(participationId, payload);
  }

  /// 클루 완료 + 자동 랭킹 계산 + 분배 방식별 보상 산정
  Future<Map<String, dynamic>> completeParticipation(
    String participationId,
  ) async {
    final now = DateTime.now().toIso8601String();

    // 1) 우선 status='completed' 만 업데이트
    final base = await _safeUpdate(participationId, {
      'status': 'completed',
      'completed_at': now,
      'updated_at': now,
    });

    // 2) clue 정보 조회 (보상 분배 결정용)
    final clueId = base['clue_id'] as String?;
    if (clueId == null) return base;

    Map<String, dynamic>? clue;
    try {
      clue = await _client.from('clues').select('*').eq('id', clueId).maybeSingle();
    } catch (_) {/* 무시 */}
    if (clue == null) return base;

    // 3) 랭킹 계산 — 본인보다 먼저 완료한 사람 수 + 1
    int rank = 1;
    try {
      final earlier = await _client
          .from('participations')
          .select('id')
          .eq('clue_id', clueId)
          .eq('status', 'completed')
          .lt('completed_at', now);
      rank = earlier.length + 1;
    } catch (_) {/* 무시, rank=1 유지 */}

    // 4) 분배 방식별 보상 산정
    final mode = clue['distribution_mode']?.toString() ?? 'first_come';
    final maxWinners = (clue['max_participants'] as int?) ?? 99999;
    final rewardValue = (clue['reward_value'] as num?)?.toInt() ?? 0;

    int earnedPoints = 0;
    String rewardStatus = 'not_eligible';

    switch (mode) {
      case 'all':
        earnedPoints = rewardValue;
        rewardStatus = 'eligible';
        break;
      case 'first_come':
        if (rank <= maxWinners) {
          earnedPoints = rewardValue;
          rewardStatus = 'eligible';
        }
        break;
      case 'rank':
        // 1등 100%, N등 비율 (선형)
        if (rank <= maxWinners) {
          final ratio = (maxWinners - rank + 1) / maxWinners;
          earnedPoints = (rewardValue * ratio).round();
          rewardStatus = 'eligible';
        }
        break;
      case 'random':
        // MVP: 추첨은 별도 배치, 일단 eligible 후보로 표시
        rewardStatus = 'pending_lottery';
        earnedPoints = 0;
        break;
    }

    // 5) 랭킹·보상 정보 저장 (해당 컬럼 없으면 자동 drop)
    final final_ = await _safeUpdate(participationId, {
      'rank': rank,
      'total_points_earned': earnedPoints,
      'reward_status': rewardStatus,
      'updated_at': now,
    });

    // 응답에 계산 결과 합쳐서 반환 (DB에 저장 안 됐어도 UI에 보여주려고)
    final merged = Map<String, dynamic>.from(final_);
    merged['rank'] = rank;
    merged['total_points_earned'] = earnedPoints;
    merged['reward_status'] = rewardStatus;
    merged['_clue_reward_label'] = clue['reward_label'];
    merged['_clue_reward_type'] = clue['reward_type'];
    merged['_clue_distribution_mode'] = mode;
    merged['_clue_max_winners'] = maxWinners;
    return merged;
  }

  Future<Map<String, dynamic>> abandonParticipation(
    String participationId,
  ) async {
    return _safeUpdate(participationId, {
      'status': 'abandoned',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String clueId) async {
    // 1차: 풀 조인 + total_points_earned 정렬
    try {
      final response = await _client
          .from('participations')
          .select('*, profiles:user_id(nickname, avatar_url)')
          .eq('clue_id', clueId)
          .eq('status', 'completed')
          .order('total_points_earned', ascending: false)
          .order('completed_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {/* 2차로 */}

    // 2차: 정렬 컬럼 단순화
    try {
      final response = await _client
          .from('participations')
          .select('*')
          .eq('clue_id', clueId)
          .eq('status', 'completed')
          .order('completed_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 견고한 UPDATE — PGRST204 (컬럼 없음) 발생 시 해당 컬럼 제거 후 재시도
  Future<Map<String, dynamic>> _safeUpdate(
    String participationId,
    Map<String, dynamic> payload,
  ) async {
    var p = Map<String, dynamic>.from(payload);
    final dropped = <String>[];

    for (int attempt = 0; attempt < 8; attempt++) {
      try {
        final response = await _client
            .from('participations')
            .update(p)
            .eq('id', participationId)
            .select()
            .single();
        return response;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204') {
          final match = RegExp(r"'([^']+)' column").firstMatch(e.message);
          final col = match?.group(1);
          if (col != null && p.containsKey(col)) {
            p.remove(col);
            dropped.add(col);
            continue;
          }
        }
        // 다른 에러 — 빈 페이로드면 무시
        if (p.isEmpty) {
          return {'id': participationId, ...payload};
        }
        throw Exception(
            'participation 업데이트 실패 [code=${e.code}]: ${e.message} | drop=$dropped');
      } catch (e) {
        throw Exception('participation 업데이트 실패: $e');
      }
    }
    // 모든 컬럼 드롭됐으면 응답 합성
    return {'id': participationId, ...payload};
  }
}
