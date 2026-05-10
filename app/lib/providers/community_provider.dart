import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/community_service.dart';

/// Singleton provider for [CommunityService].
final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

/// FutureProvider for community posts (all types).
final communityPostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(communityServiceProvider);
  return service.getPosts();
});

/// Family provider for posts filtered by type.
final communityPostsByTypeProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, type) async {
  final service = ref.watch(communityServiceProvider);
  return service.getPosts(type: type);
});

/// Family provider for a single post detail.
final postDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final service = ref.watch(communityServiceProvider);
  return service.getPostById(id);
});

/// Family provider for post comments.
final postCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, postId) async {
  final service = ref.watch(communityServiceProvider);
  return service.getComments(postId);
});
