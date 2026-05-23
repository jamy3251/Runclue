import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

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
      // steps는 clues의 자식이라 participations에서 직접 embed 불가.
      // clues를 통해 중첩 embed로 가져옴. clue_play_screen은 clueDetailProvider로
      // 별도 fetch 하므로 steps 누락돼도 무방.
      final response = await _client
          .from('participations')
          .select('*, clues(*, steps(*))')
          .eq('clue_id', clueId)
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      // 1차 실패 시 steps 없이 재시도 (관계 미정의 등 안전 fallback)
      try {
        return await _client
            .from('participations')
            .select('*, clues(*)')
            .eq('clue_id', clueId)
            .eq('user_id', userId)
            .maybeSingle();
      } catch (e2) {
        throw Exception('Failed to fetch participation: $e2 (1차: $e)');
      }
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
    //    base는 사장 충전 풀(reward_pool_net) 우선, 없으면 reward_value fallback (구버전).
    final mode = clue['distribution_mode']?.toString() ?? 'first_come';
    final maxWinners = (clue['max_participants'] as int?) ?? 99999;
    final poolNet = (clue['reward_pool_net'] as int?) ?? 0;
    final rewardValue = (clue['reward_value'] as num?)?.toInt() ?? 0;
    final prizeBase = poolNet > 0 ? poolNet : rewardValue;
    final minP = (clue['min_participants'] as int?) ?? 1;

    int earnedPoints = 0;
    String rewardStatus = 'not_eligible';

    switch (mode) {
      case 'coop_split':
        // 그룹 미션 #15 — 풀을 min_participants 동등 분배
        // 개별 완료 시 자기 몫 즉시 지급
        earnedPoints = minP > 0 ? (prizeBase / minP).floor() : 0;
        rewardStatus = earnedPoints > 0 ? 'eligible' : 'not_eligible';
        break;
      case 'all':
        earnedPoints = prizeBase;
        rewardStatus = 'eligible';
        break;
      case 'first_come':
        if (rank <= maxWinners) {
          earnedPoints = prizeBase;
          rewardStatus = 'eligible';
        }
        break;
      case 'rank':
        // 1등 100%, N등 비율 (선형)
        if (rank <= maxWinners) {
          final ratio = (maxWinners - rank + 1) / maxWinners;
          earnedPoints = (prizeBase * ratio).round();
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

    // 6) 실 보상 row 발급 — 선물함에 미수령 상태로 도착
    //    자격 있고 0 초과일 때만. 실패는 silently — 결과 화면 표시는 진행.
    //    단 운영 디버깅을 위해 콘솔에는 명확히 남김 (RLS/스키마 누락 조기 발견).
    final userId = base['user_id'] as String?;
    if (rewardStatus == 'eligible' && earnedPoints > 0 && userId != null) {
      try {
        await _issueReward(
          participationId: participationId,
          clueId: clueId,
          userId: userId,
          clue: clue,
          earnedPoints: earnedPoints,
        );
      } catch (e) {
        // 사용자 결과 화면은 막지 않음. 콘솔로만 노출.
        debugPrint('⚠ [reward] _issueReward 실패 (silently swallowed): $e');
        if (e.toString().contains('42501') ||
            e.toString().contains('row-level security')) {
          debugPrint(
              '   → RLS INSERT 정책 누락 가능성. supabase/migrations/002 적용 필요.');
        }
      }
    }

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

  /// clue.reward_type → rewards.type CHECK 호환 매핑.
  /// rewards.type은 ('points','badge','coupon','prize','raffle')만 허용.
  static String mapRewardType(String? clueRewardType) {
    switch (clueRewardType) {
      case 'badge':
        return 'badge';
      case 'points':
        return 'points';
      case 'cash':
      case 'prize':
        return 'prize';
      case 'menu_discount':
      case 'gifticon':
      case 'coupon':
        return 'coupon';
      case 'raffle':
        return 'raffle';
      default:
        return 'coupon'; // 안전한 기본값
    }
  }

  /// 쿠폰 코드 자동 생성 — 사람이 읽기 쉬운 형태 (RC-XXXX-XXXX).
  static String generateCouponCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 헷갈리는 글자 제외 (0/O, 1/I)
    final rng = Random.secure();
    String block(int n) =>
        List.generate(n, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'RC-${block(4)}-${block(4)}';
  }

  /// rewards 테이블에 1건 발급. PGRST204 발생 시 알 수 없는 컬럼 자동 제거.
  Future<void> _issueReward({
    required String participationId,
    required String clueId,
    required String userId,
    required Map<String, dynamic> clue,
    required int earnedPoints,
  }) async {
    final type = mapRewardType(clue['reward_type']?.toString());
    final rewardLabel = clue['reward_label']?.toString();

    var payload = <String, dynamic>{
      'user_id': userId,
      'clue_id': clueId,
      'participation_id': participationId,
      'type': type,
      'value': earnedPoints,
      'is_claimed': false,
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };

    if (type == 'coupon') {
      payload['coupon_code'] = generateCouponCode();
    }
    if (rewardLabel != null && rewardLabel.isNotEmpty) {
      payload['badge_name'] = rewardLabel; // 모든 타입에서 라벨로 활용
    }

    final dropped = <String>[];
    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        await _client.from('rewards').insert(payload);
        // 알림 1건 — RLS / 컬럼 누락 시 silently skip
        unawaited(_notifyRewardEarned(
          userId: userId,
          clueId: clueId,
          rewardLabel: rewardLabel,
          earnedPoints: earnedPoints,
        ));
        return;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204') {
          final match = RegExp(r"'([^']+)' column").firstMatch(e.message);
          final col = match?.group(1);
          if (col != null && payload.containsKey(col)) {
            payload.remove(col);
            dropped.add(col);
            continue;
          }
        }
        // 23514 (type CHECK 위반) — 안전한 기본값으로 폴백
        if (e.code == '23514' && payload['type'] != 'coupon') {
          payload['type'] = 'coupon';
          payload['coupon_code'] ??= generateCouponCode();
          dropped.add('type→coupon');
          continue;
        }
        // 42501: RLS 정책 거부 — 자동 복구 불가, 운영자가 정책 추가해야 함
        if (e.code == '42501') {
          throw Exception(
              'reward INSERT 거부 (RLS 정책 누락) — supabase/migrations/002 적용 필요');
        }
        throw Exception('reward INSERT 실패 [${e.code}]: ${e.message} | drop=$dropped');
      }
    }
  }

  /// 보상 도착 알림 — notifications 테이블에 1건.
  /// 실패는 silently — 알림은 부수효과이고 선물함이 메인 채널.
  /// 002 마이그레이션 적용 전엔 RLS로 거부될 수 있음.
  Future<void> _notifyRewardEarned({
    required String userId,
    required String clueId,
    required String? rewardLabel,
    required int earnedPoints,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': 'reward_earned',
        'title': '🎁 보상이 도착했어요',
        'body': rewardLabel != null && rewardLabel.isNotEmpty
            ? '$rewardLabel — 선물함에서 받아보세요'
            : '₩$earnedPoints 상당 보상이 선물함에 도착했어요',
        'data': {'clue_id': clueId, 'value': earnedPoints},
      });
    } catch (e) {
      debugPrint('  [reward] notification 알림 INSERT 실패 (무시): $e');
    }
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

  /// 그룹 미션 #15 — coop 클루 lobby 참여.
  /// 서버 RPC가 임계값 도달 시 자동으로 모든 lobby 참여자를 in_progress로 전환.
  /// 반환: {ok, state, current, target, started, reason?}
  Future<Map<String, dynamic>> joinCoop(String clueId) async {
    final res = await _client.rpc('join_coop_clue', params: {
      'clue_id_in': clueId,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// coop 클루 모집 상태 polling용.
  /// 반환: {coop_state, current_participants, min_participants, lobby_started_at}
  Future<Map<String, dynamic>?> fetchCoopState(String clueId) async {
    final row = await _client
        .from('clues')
        .select('coop_state, current_participants, min_participants, lobby_started_at, lobby_window_minutes, game_mode')
        .eq('id', clueId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }
}
