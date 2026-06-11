import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StepService {
  final SupabaseClient _client = safeClient;

  /// Get all steps for a clue, ordered by order_index.
  Future<List<Map<String, dynamic>>> getStepsByClueId(String clueId) async {
    try {
      final response = await _client
          .from('steps')
          .select('*')
          .eq('clue_id', clueId)
          .order('order_index', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch steps: $e');
    }
  }

  /// Create a new step.
  /// 견고한 INSERT — 누락 컬럼 + CHECK 제약 자동 매핑
  Future<Map<String, dynamic>> createStep(Map<String, dynamic> stepData) async {
    var payload = Map<String, dynamic>.from(stepData);
    final droppedCols = <String>[];

    for (int attempt = 0; attempt < 12; attempt++) {
      try {
        final response =
            await _client.from('steps').insert(payload).select().single();
        return response;
      } on PostgrestException catch (e) {
        // PGRST204: 컬럼 누락 자동 제거
        if (e.code == 'PGRST204') {
          final match = RegExp(r"'([^']+)' column").firstMatch(e.message);
          final col = match?.group(1);
          if (col != null && payload.containsKey(col)) {
            payload.remove(col);
            droppedCols.add(col);
            continue;
          }
        }
        // 23514: type CHECK 제약 위반 → 호환 type으로 자동 매핑
        if (e.code == '23514' && e.message.contains('type')) {
          final cur = payload['type']?.toString() ?? '';
          // PHOTO_SIM/MOTION_SIM은 SNAPSHOT으로 (사진 인증) 폴백
          // 그 외 알 수 없는 값은 CHECKPOINT로
          final mapped = switch (cur) {
            'PHOTO_SIM' || 'MOTION_SIM' => 'SNAPSHOT',
            _ => 'CHECKPOINT',
          };
          if (mapped != cur) {
            payload['type'] = mapped;
            // SNAPSHOT/CHECKPOINT는 manual/auto 검증
            payload['validation_type'] =
                mapped == 'CHECKPOINT' ? 'auto' : 'manual';
            droppedCols.add('type:$cur→$mapped');
            continue;
          }
        }
        throw Exception(
            'STEP INSERT 실패 [code=${e.code}]: ${e.message} | drop=$droppedCols',);
      } catch (e) {
        throw Exception('STEP INSERT 실패 (예외): $e');
      }
    }
    throw Exception('STEP 스키마 불일치: drop=$droppedCols');
  }

  /// Update an existing step.
  Future<Map<String, dynamic>> updateStep(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _client
          .from('steps')
          .update(fields)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update step: $e');
    }
  }

  /// Delete a step by ID.
  Future<void> deleteStep(String id) async {
    try {
      await _client.from('steps').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete step: $e');
    }
  }

  /// Reorder steps for a clue by updating their order_index values.
  ///
  /// [stepOrders] is a list of maps with 'id' and 'order_index' keys.
  Future<void> reorderSteps(
    String clueId,
    List<Map<String, dynamic>> stepOrders,
  ) async {
    try {
      for (final order in stepOrders) {
        await _client
            .from('steps')
            .update({'order_index': order['order_index']})
            .eq('id', order['id'])
            .eq('clue_id', clueId);
      }
    } catch (e) {
      throw Exception('Failed to reorder steps: $e');
    }
  }
}
