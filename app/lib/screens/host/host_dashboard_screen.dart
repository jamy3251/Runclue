import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/realtime_feed_provider.dart';
import '../../services/evidence_service.dart';
import '../../services/participation_service.dart';

/// 호스트(Creator)가 실시간으로 참여자 현황과 인증을 확인/승인/반려하는 대시보드.
///
/// 구조:
///   상단: 참여자 수 + 진행률 요약
///   탭 1: 실시간 피드 (evidence/participation 이벤트)
///   탭 2: 승인 대기 (pending evidence 목록 + 승인/반려 액션)
///   탭 3: 리더보드 (순위)
class HostDashboardScreen extends ConsumerStatefulWidget {
  final String clueId;

  const HostDashboardScreen({super.key, required this.clueId});

  @override
  ConsumerState<HostDashboardScreen> createState() =>
      _HostDashboardScreenState();
}

class _HostDashboardScreenState extends ConsumerState<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('호스트 대시보드'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: '실시간'),
            Tab(icon: Icon(Icons.pending_actions), text: '승인 대기'),
            Tab(icon: Icon(Icons.leaderboard), text: '순위'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LiveFeedTab(clueId: widget.clueId),
          _PendingReviewTab(clueId: widget.clueId),
          _LeaderboardTab(clueId: widget.clueId),
        ],
      ),
    );
  }
}

/// 탭 1: 실시간 이벤트 피드
class _LiveFeedTab extends ConsumerWidget {
  final String clueId;
  const _LiveFeedTab({required this.clueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(realtimeFeedProvider(clueId));

    return feedAsync.when(
      data: (event) {
        // StreamProvider는 최신 이벤트 하나만 줌.
        // 실제로는 리스트로 누적해야 하지만, 간단하게 최신 이벤트 표시 + 새로고침.
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingEvidencesProvider(clueId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FeedEventCard(event: event),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '실시간 이벤트가 여기에 표시됩니다',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('실시간 피드 연결 중...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('연결 실패: $e'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(realtimeFeedProvider(clueId)),
              child: const Text('재연결'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEventCard extends StatelessWidget {
  final FeedEvent event;
  const _FeedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final icon = event.type == FeedEventType.evidenceSubmitted
        ? Icons.camera_alt
        : Icons.directions_run;
    final label = event.type == FeedEventType.evidenceSubmitted
        ? '새 인증 제출'
        : '참여 상태 변경';
    final status = event.data['status'] as String? ?? '';

    return Card(
      elevation: 0,
      color: Colors.blue[50],
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(label),
        subtitle: Text('상태: $status'),
        trailing: Text(
          timeago.format(event.timestamp, locale: 'ko'),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

/// 탭 2: 승인 대기 목록
class _PendingReviewTab extends ConsumerWidget {
  final String clueId;
  const _PendingReviewTab({required this.clueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingEvidencesProvider(clueId));

    return pendingAsync.when(
      data: (evidences) {
        if (evidences.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('승인 대기 중인 인증이 없습니다'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingEvidencesProvider(clueId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: evidences.length,
            itemBuilder: (context, index) {
              final evidence = evidences[index];
              return _EvidenceReviewCard(
                evidence: evidence,
                onApprove: () => _handleValidation(
                  context, ref, evidence['id'], 'approved',
                ),
                onReject: () => _handleValidation(
                  context, ref, evidence['id'], 'rejected',
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }

  Future<void> _handleValidation(
    BuildContext context,
    WidgetRef ref,
    String evidenceId,
    String status,
  ) async {
    try {
      final evidenceService = EvidenceService();
      await evidenceService.validateEvidence(
        evidenceId: evidenceId,
        status: status,
      );
      ref.invalidate(pendingEvidencesProvider(clueId));
      if (context.mounted) {
        final message = status == 'approved' ? '승인되었습니다' : '반려되었습니다';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}

class _EvidenceReviewCard extends StatelessWidget {
  final Map<String, dynamic> evidence;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _EvidenceReviewCard({
    required this.evidence,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = evidence['media_url'] as String?;
    final textContent = evidence['text_content'] as String?;
    final step = evidence['steps'] as Map<String, dynamic>?;
    final stepTitle = step?['title'] as String? ?? '';
    final stepType = step?['type'] as String? ?? '';
    final submittedAt = evidence['submitted_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 정보
            Row(
              children: [
                Icon(_stepIcon(stepType), size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stepTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (submittedAt != null)
                  Text(
                    timeago.format(DateTime.parse(submittedAt), locale: 'ko'),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Evidence 내용
            if (mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: mediaUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppColors.bgSurface,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            if (textContent != null && textContent.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(textContent),
              ),
            ],
            const SizedBox(height: 16),

            // 승인/반려 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('반려', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _stepIcon(String type) {
    switch (type) {
      case 'CHECKPOINT':
        return Icons.location_on;
      case 'SNAPSHOT':
        return Icons.camera_alt;
      case 'QUEST':
        return Icons.quiz;
      case 'OX_QUIZ':
        return Icons.check_circle;
      case 'LIST':
        return Icons.checklist;
      default:
        return Icons.help_outline;
    }
  }
}

/// 탭 3: 리더보드
class _LeaderboardTab extends ConsumerWidget {
  final String clueId;
  const _LeaderboardTab({required this.clueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ParticipationService().getLeaderboard(clueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        final leaderboard = snapshot.data ?? [];
        if (leaderboard.isEmpty) {
          return const Center(child: Text('아직 참여자가 없습니다'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final entry = leaderboard[index];
            final rank = index + 1;
            final points = entry['total_points_earned'] ?? 0;
            final status = entry['status'] as String? ?? '';
            final userId = entry['user_id'] as String? ?? '';

            return Card(
              elevation: 0,
              color: rank <= 3 ? Colors.amber[50] : null,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank <= 3 ? Colors.amber : Colors.grey[300],
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rank <= 3 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(userId.substring(0, 8)),
                subtitle: Text(status),
                trailing: Text(
                  '$points점',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
