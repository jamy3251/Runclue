import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 부적절한 콘텐츠/사용자 신고 서비스.
/// reports 테이블에 INSERT하고, 관리자가 대시보드에서 처리.
class ReportService {
  final SupabaseClient _client;

  ReportService({SupabaseClient? client})
      : _client = client ?? safeClient;

  /// 신고 제출
  Future<Map<String, dynamic>> submitReport({
    required String reporterId,
    required String targetType, // 'clue', 'user', 'evidence', 'community_post'
    required String targetId,
    required String reason, // 'inappropriate', 'spam', 'fraud', 'safety', 'harassment', 'copyright', 'other'
    String? description,
  }) async {
    try {
      final response = await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        if (description != null) 'description': description,
      }).select().single();
      return response;
    } catch (e) {
      throw Exception('신고 제출 실패: $e');
    }
  }
}
