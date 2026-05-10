import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final SupabaseClient _client = safeClient;

  /// List posts with optional type filtering.
  Future<List<Map<String, dynamic>>> getPosts({
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('community_posts')
          .select('*, author:profiles(*)');

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get a single post by ID.
  Future<Map<String, dynamic>?> getPostById(String id) async {
    try {
      final response = await _client
          .from('community_posts')
          .select('*, author:profiles(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Create a new post.
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('community_posts')
          .insert(data)
          .select('*, author:profiles(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Delete a post.
  Future<void> deletePost(String id) async {
    try {
      await _client.from('community_posts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Toggle like on a post.
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final existing = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'post')
          .eq('target_id', postId)
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
          'target_type': 'post',
          'target_id': postId,
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get comments for a post.
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _client
          .from('post_comments')
          .select('*, author:profiles(*)')
          .eq('post_id', postId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Add a comment to a post.
  Future<Map<String, dynamic>> addComment(
    String postId,
    String userId,
    String content,
  ) async {
    try {
      final response = await _client
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'content': content,
          })
          .select('*, author:profiles(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}
