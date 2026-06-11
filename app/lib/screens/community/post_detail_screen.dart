import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/error_widget.dart' as app;
import '../../widgets/common/loading_widget.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        centerTitle: true,
        elevation: 0,
      ),
      body: postAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => app.AppErrorWidget(
          message: '게시글을 불러올 수 없습니다',
          onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
        ),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('게시글을 찾을 수 없습니다'));
          }

          final author = post['author'] as Map<String, dynamic>? ?? {};
          final createdAt = post['created_at'] != null
              ? _formatDate(DateTime.parse(post['created_at']))
              : '';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: author['avatar_url'] != null
                                ? NetworkImage(author['avatar_url'])
                                : null,
                            child: author['avatar_url'] == null
                                ? const Icon(Icons.person, size: 22)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author['nickname'] ?? '유저',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (post['type'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _typeLabel(post['type']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      if (post['title'] != null &&
                          post['title'].toString().isNotEmpty)
                        Text(
                          post['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (post['title'] != null &&
                          post['title'].toString().isNotEmpty)
                        const SizedBox(height: 12),

                      // Content
                      Text(
                        post['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Engagement
                      Row(
                        children: [
                          _LikeButton(
                            postId: widget.postId,
                            likeCount: post['like_count'] ?? 0,
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline,
                              size: 20, color: AppColors.textSecondary,),
                          const SizedBox(width: 4),
                          Text(
                            '${post['comment_count'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Comments
                      const Text(
                        '댓글',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      commentsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const Text('댓글을 불러올 수 없습니다'),
                        data: (comments) {
                          if (comments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  '아직 댓글이 없습니다',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: comments.map((comment) {
                              final cAuthor =
                                  comment['author'] as Map<String, dynamic>? ??
                                      {};
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.bgSurface,
                                      backgroundImage:
                                          cAuthor['avatar_url'] != null
                                              ? NetworkImage(
                                                  cAuthor['avatar_url'],)
                                              : null,
                                      child: cAuthor['avatar_url'] == null
                                          ? const Icon(Icons.person, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                cAuthor['nickname'] ?? '유저',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (comment['created_at'] !=
                                                  null)
                                                Text(
                                                  _formatTimeAgo(
                                                      DateTime.parse(
                                                          comment[
                                                              'created_at'],),),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['content'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Comment input
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.bgSurface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _submitComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send,
                              color: Theme.of(context).primaryColor,),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSending = true);
    try {
      final service = ref.read(communityServiceProvider);
      await service.addComment(widget.postId, userId, content);
      _commentController.clear();
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(postDetailProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _typeLabel(String type) {
    const map = {
      'review': '후기',
      'tip': '팁',
      'photo': '사진',
      'question': '질문',
      'general': '일반',
    };
    return map[type] ?? type;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) return '${dateTime.month}/${dateTime.day}';
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}

class _LikeButton extends ConsumerStatefulWidget {
  final String postId;
  final int likeCount;

  const _LikeButton({required this.postId, required this.likeCount});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  bool _isLiked = false;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.likeCount;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;

        try {
          final service = ref.read(communityServiceProvider);
          final liked = await service.toggleLike(widget.postId, userId);
          setState(() {
            _isLiked = liked;
            _count += liked ? 1 : -1;
          });
        } catch (_) {}
      },
      child: Row(
        children: [
          Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: _isLiked ? Colors.red : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '$_count',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
