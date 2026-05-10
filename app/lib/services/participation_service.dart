import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipationService {
  final SupabaseClient _client = safeClient;

  /// Join a clue by creating a new participation record.
  Future<Map<String, dynamic>> joinClue({
    required String clueId,
    required String userId,
    String? clanId,
  }) async {
    try {
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
      return response;
    } catch (e) {
      throw Exception('Failed to join clue: $e');
    }
  }

  /// Get all participations for a user with clue data joined.
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

  /// Get a single participation for a user and clue.
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

  /// Update progress by advancing to the next step.
  Future<Map<String, dynamic>> updateProgress(
    String participationId,
    int stepIndex,
  ) async {
    try {
      final response = await _client
          .from('participations')
          .update({
            'current_step_index': stepIndex,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', participationId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  /// Mark a participation as completed.
  Future<Map<String, dynamic>> completeParticipation(
    String participationId,
  ) async {
    try {
      final response = await _client
          .from('participations')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', participationId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to complete participation: $e');
    }
  }

  /// Mark a participation as abandoned.
  Future<Map<String, dynamic>> abandonParticipation(
    String participationId,
  ) async {
    try {
      final response = await _client
          .from('participations')
          .update({
            'status': 'abandoned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', participationId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to abandon participation: $e');
    }
  }

  /// Get leaderboard for a clue, ranked by points and completion time.
  Future<List<Map<String, dynamic>>> getLeaderboard(String clueId) async {
    try {
      final response = await _client
          .from('participations')
          .select('*, profiles:user_id(nickname, avatar_url)')
          .eq('clue_id', clueId)
          .eq('status', 'completed')
          .order('total_points', ascending: false)
          .order('completed_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }
}
