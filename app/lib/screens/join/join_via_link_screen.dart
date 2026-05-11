import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../services/deep_link_service.dart';
import '../../services/participation_service.dart';

/// 딥링크로 진입한 사용자에게 클루 미리보기를 보여주고
/// 즉시 참여할 수 있게 하는 화면.
///
/// 플로우:
///   딥링크 클릭 → /join/:id → 클루 정보 로딩 → 미리보기 카드
///   → "참여하기" 버튼 → (비회원이면 익명 인증) → 참여 → 플레이 화면
class JoinViaLinkScreen extends ConsumerStatefulWidget {
  final String clueId;

  const JoinViaLinkScreen({super.key, required this.clueId});

  @override
  ConsumerState<JoinViaLinkScreen> createState() => _JoinViaLinkScreenState();
}

class _JoinViaLinkScreenState extends ConsumerState<JoinViaLinkScreen> {
  Map<String, dynamic>? _clue;
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClue();
  }

  Future<void> _loadClue() async {
    final clue = await DeepLinkService.validateClueLink(widget.clueId);
    if (mounted) {
      setState(() {
        _clue = clue;
        _isLoading = false;
        if (clue == null) _error = '클루를 찾을 수 없거나 참여할 수 없는 상태입니다';
      });
    }
  }

  Future<void> _handleJoin() async {
    setState(() => _isJoining = true);

    try {
      // 로그인 여부 확인
      var userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        // 비회원: 익명 인증
        final anonService = ref.read(anonymousAuthServiceProvider);
        final user = await anonService.signInAnonymously();
        userId = user.id;
      }

      // 참여
      final participationService = ParticipationService();
      await participationService.joinClue(clueId: widget.clueId, userId: userId);

      if (mounted) {
        context.go('/clue/${widget.clueId}/play');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/explore'),
                  child: const Text('홈으로 이동'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final clue = _clue!;
    final title = clue['title'] as String? ?? '';
    final description = clue['description'] as String? ?? '';
    final thumbnailUrl = clue['thumbnail_url'] as String?;
    final category = clue['category'] as String? ?? '';
    final currentParticipants = clue['current_participants'] as int? ?? 0;
    final maxParticipants = clue['max_participants'] as int?;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // RunClue 로고
              Text(
                'RunClue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '미션에 초대되었습니다!',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // 클루 미리보기 카드
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일
                    if (thumbnailUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.flag,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카테고리
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),

                          // 제목
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 설명
                          if (description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(height: 16),

                          // 참여자 수
                          Row(
                            children: [
                              Icon(Icons.people, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                maxParticipants != null
                                    ? '$currentParticipants / $maxParticipants명 참여 중'
                                    : '$currentParticipants명 참여 중',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 참여 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isJoining ? null : _handleJoin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text(
                          '지금 참여하기',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 홈으로 이동
              TextButton(
                onPressed: () => context.go('/explore'),
                child: Text(
                  '나중에 할게요',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
