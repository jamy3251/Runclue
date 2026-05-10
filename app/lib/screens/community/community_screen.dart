import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/error_widget.dart' as app;
import '../../widgets/common/loading_widget.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['전체', '후기', '팁', '사진', '질문'];
  static const _tabTypes = [null, 'review', 'tip', 'photo', 'question'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소통'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Theme.of(context).primaryColor,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) {
          return _PostList(type: _tabTypes[index]);
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWritePostBottomSheet(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showWritePostBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '글 작성',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Type selector
                  Wrap(
                    spacing: 8,
                    children: [
                      _typeChip('후기', 'review', selectedType, (v) {
                        setModalState(() => selectedType = v);
                      }),
                      _typeChip('팁', 'tip', selectedType, (v) {
                        setModalState(() => selectedType = v);
                      }),
                      _typeChip('사진', 'photo', selectedType, (v) {
                        setModalState(() => selectedType = v);
                      }),
                      _typeChip('질문', 'question', selectedType, (v) {
                        setModalState(() => selectedType = v);
                      }),
                      _typeChip('일반', 'general', selectedType, (v) {
                        setModalState(() => selectedType = v);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: '내용',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (content.isEmpty) return;

                        final userId = ref.read(currentUserIdProvider);
                        if (userId == null) return;

                        try {
                          final service =
                              ref.read(communityServiceProvider);
                          await service.createPost({
                            'author_id': userId,
                            'type': selectedType,
                            'title': title.isEmpty ? null : title,
                            'content': content,
                          });
                          // Refresh posts
                          ref.invalidate(communityPostsProvider);
                          ref.invalidate(communityPostsByTypeProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('게시 실패: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('게시'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeChip(
    String label,
    String value,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _PostList extends ConsumerWidget {
  final String? type;

  const _PostList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsByTypeProvider(type));

    return postsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => app.AppErrorWidget(
        message: '게시글을 불러올 수 없습니다',
        onRetry: () => ref.invalidate(communityPostsByTypeProvider(type)),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  '아직 게시글이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityPostsByTypeProvider(type));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final author =
                  post['author'] as Map<String, dynamic>? ?? {};
              final createdAt = post['created_at'] != null
                  ? _formatTimeAgo(DateTime.parse(post['created_at']))
                  : '';

              return _CommunityPostCard(
                authorName: author['nickname'] ?? '유저',
                avatarUrl: author['avatar_url'],
                title: post['title'] ?? '',
                preview: post['content'] ?? '',
                likeCount: post['like_count'] ?? 0,
                commentCount: post['comment_count'] ?? 0,
                timeAgo: createdAt,
                onTap: () {
                  final postId = post['id'];
                  if (postId != null) {
                    context.push('/post/$postId');
                  }
                },
              );
            },
          ),
        );
      },
    );
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

class _CommunityPostCard extends StatelessWidget {
  final String authorName;
  final String? avatarUrl;
  final String title;
  final String preview;
  final int likeCount;
  final int commentCount;
  final String timeAgo;
  final VoidCallback onTap;

  const _CommunityPostCard({
    required this.authorName,
    this.avatarUrl,
    required this.title,
    required this.preview,
    required this.likeCount,
    required this.commentCount,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.bgSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (title.isNotEmpty) const SizedBox(height: 8),

              // Preview
              Text(
                preview,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Engagement Row
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$likeCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$commentCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
