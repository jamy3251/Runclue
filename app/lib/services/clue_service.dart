import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClueService {
  final SupabaseClient _client = safeClient;

  /// List clues with optional filtering and pagination.
  Future<List<Map<String, dynamic>>> getClues({
    String? category,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('clues')
          .select('*, steps(count)');

      if (category != null) {
        query = query.eq('category', category);
      }
      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.eq('status', 'active');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch clues: $e');
    }
  }

  /// Get nearby clues using the nearby_clues RPC function.
  Future<List<Map<String, dynamic>>> getNearbyClues(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    try {
      final response = await _client.rpc('nearby_clues', params: {
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch nearby clues: $e');
    }
  }

  /// Get a single clue by ID with its steps. 견고한 fallback.
  /// 1차: join으로 한 번에 (FK 관계 있을 때 빠름)
  /// 2차: clue + steps 따로 fetch (FK 없거나 PGRST200 발생 시)
  Future<Map<String, dynamic>?> getClueById(String id) async {
    // 1차 — embed
    try {
      final response = await _client
          .from('clues')
          .select('*, steps(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (_) {/* 2차 fallback */}

    // 2차 — 분리 fetch
    try {
      final clue = await _client
          .from('clues')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (clue == null) return null;

      try {
        final steps = await _client
            .from('steps')
            .select('*')
            .eq('clue_id', id)
            .order('order_index', ascending: true);
        clue['steps'] = List<Map<String, dynamic>>.from(steps);
      } catch (_) {
        clue['steps'] = <Map<String, dynamic>>[];
      }
      return clue;
    } catch (e) {
      throw Exception('Failed to fetch clue: $e');
    }
  }

  /// Get clues created by a specific user. join 실패 시 단순 쿼리로 fallback.
  Future<List<Map<String, dynamic>>> getMyClues(String userId) async {
    try {
      final response = await _client
          .from('clues')
          .select('*, steps(count)')
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {/* 2차 fallback */}

    try {
      final response = await _client
          .from('clues')
          .select('*')
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Create a new clue.
  /// 견고한 INSERT — Supabase 스키마에 없는 컬럼은 자동으로 빼고 재시도.
  /// + 사후 검증 SELECT로 실제 DB에 저장됐는지 확인
  Future<Map<String, dynamic>> createClue(Map<String, dynamic> clueData) async {
    var payload = Map<String, dynamic>.from(clueData);
    final droppedCols = <String>[];

    // 최대 12회 재시도 (각각 모르는 컬럼 한 개씩 제거)
    for (int attempt = 0; attempt < 12; attempt++) {
      try {
        final response =
            await _client.from('clues').insert(payload).select().single();
        final id = response['id']?.toString();
        if (id == null || id.isEmpty) {
          throw Exception('INSERT 응답에 ID 없음 (DB에 저장 안 됨)');
        }
        // 사후 검증 — 실제로 row가 존재하는지 다시 SELECT
        try {
          final verify = await _client
              .from('clues')
              .select('id')
              .eq('id', id)
              .maybeSingle();
          if (verify == null) {
            throw Exception(
                'INSERT는 응답했으나 DB에 row가 없음 (RLS 또는 트리거 문제 의심)');
          }
        } catch (e) {
          throw Exception('사후 검증 실패: $e (drop=$droppedCols)');
        }
        return response;
      } on PostgrestException catch (e) {
        // PGRST204: column not found in schema
        if (e.code == 'PGRST204') {
          final col = _extractMissingColumn(e.message);
          if (col != null && payload.containsKey(col)) {
            payload.remove(col);
            droppedCols.add(col);
            continue;
          }
        }
        // 그 외는 자세한 에러 정보로 던짐
        throw Exception(
            'INSERT 실패 [code=${e.code}]: ${e.message} | drop=$droppedCols | 남은 컬럼=${payload.keys.toList()}');
      } catch (e) {
        throw Exception('INSERT 실패 (예외): $e | drop=$droppedCols');
      }
    }
    throw Exception(
        '너무 많은 알 수 없는 컬럼: 제거된 컬럼=$droppedCols, 남은 컬럼=${payload.keys.toList()}');
  }

  /// PostgrestException 메시지에서 누락 컬럼명 추출.
  /// 예: "Could not find the 'distribution_mode' column of 'clues'..."
  String? _extractMissingColumn(String message) {
    final match = RegExp(r"'([^']+)' column").firstMatch(message);
    return match?.group(1);
  }

  /// Update an existing clue.
  Future<Map<String, dynamic>> updateClue(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _client
          .from('clues')
          .update(fields)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update clue: $e');
    }
  }

  /// Soft-delete a clue by setting its status to suspended.
  Future<void> deleteClue(String id) async {
    try {
      await _client
          .from('clues')
          .update({'status': 'suspended'})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete clue: $e');
    }
  }

  /// Text search across clue titles and descriptions. 견고한 fallback.
  Future<List<Map<String, dynamic>>> searchClues(String query) async {
    try {
      final response = await _client
          .from('clues')
          .select('*, steps(count)')
          .eq('status', 'active')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      // join 또는 필터 실패 → 단순 쿼리로 재시도
      try {
        final response = await _client
            .from('clues')
            .select('*')
            .or('title.ilike.%$query%,description.ilike.%$query%')
            .order('created_at', ascending: false)
            .limit(50);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }

  /// Get trending clues — 견고한 fallback 체인.
  /// 1차: status='active' + view_count/like_count 정렬 + steps join
  /// 2차: status='active' + created_at 정렬만
  /// 3차: 모든 status, created_at 정렬
  Future<List<Map<String, dynamic>>> getTrendingClues({int limit = 20}) async {
    // 1차 시도
    try {
      final response = await _client
          .from('clues')
          .select('*, steps(count)')
          .eq('status', 'active')
          .order('view_count', ascending: false)
          .order('like_count', ascending: false)
          .limit(limit);
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {/* 1차 실패 → 2차 */}

    // 2차: 정렬 단순화, join 제거
    try {
      final response = await _client
          .from('clues')
          .select('*')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(limit);
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {/* 2차 실패 → 3차 */}

    // 3차: status 필터도 제거 (전체)
    try {
      final response = await _client
          .from('clues')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // 모두 실패 → 빈 리스트
      return [];
    }
  }

  /// Increment the view count for a clue.
  Future<void> incrementViewCount(String id) async {
    try {
      await _client.rpc('increment_view_count', params: {'clue_id': id});
    } catch (e) {
      // Silently fail – view count is non-critical.
    }
  }

  /// Toggle like/unlike for a clue. Returns true if liked, false if unliked.
  Future<bool> toggleLike(String clueId, String userId) async {
    try {
      final existing = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'clue')
          .eq('target_id', clueId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('likes')
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        await _client.from('likes').insert({
          'user_id': userId,
          'target_type': 'clue',
          'target_id': clueId,
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }
}
