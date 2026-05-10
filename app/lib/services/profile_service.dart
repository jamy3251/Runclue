import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = safeClient;

  /// Get a profile by user ID.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update a profile.
  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _client
          .from('profiles')
          .update(fields)
          .eq('id', userId)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get badges earned by a user.
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await _client
          .from('rewards')
          .select('*')
          .eq('user_id', userId)
          .eq('type', 'badge')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch badges: $e');
    }
  }

  /// Get the user's clan membership.
  Future<Map<String, dynamic>?> getUserClan(String userId) async {
    try {
      final response = await _client
          .from('clan_members')
          .select('*, clan:clans(*)')
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user clan: $e');
    }
  }

  /// Get weekly ranking (top users by points).
  Future<List<Map<String, dynamic>>> getWeeklyRanking({int limit = 10}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, nickname, avatar_url, total_points')
          .order('total_points', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch ranking: $e');
    }
  }
}
