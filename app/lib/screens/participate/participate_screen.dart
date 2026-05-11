import '../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/participation_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart' as app;
import '../../widgets/common/loading_widget.dart';

class ParticipateScreen extends ConsumerWidget {
  const ParticipateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(myParticipationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('참여'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: participationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => app.AppErrorWidget(
          message: '참여 목록을 불러올 수 없습니다',
          onRetry: () => ref.invalidate(myParticipationsProvider),
        ),
        data: (participations) {
          if (participations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.explore_off,
              title: '아직 참여한 클루가 없어요',
              subtitle: '탐색에서 클루를 찾아보세요!',
              actionLabel: '탐색하러 가기',
              onAction: () {
                context.go('/explore');
              },
            );
          }

          final active = participations
              .where((p) =>
                  p['status'] == 'in_progress' || p['status'] == 'joined')
              .toList();
          final completed = participations
              .where((p) => p['status'] == 'completed')
              .toList();
          final abandoned = participations
              .where((p) => p['status'] == 'abandoned')
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myParticipationsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isNotEmpty) ...[
                    const Text(
                      '진행 중인 클루',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...active.map((p) => _ParticipationCard(
                          title: p['clue_title'] ??
                              p['clues']?['title'] ??
                              '클루',
                          progress: _calcProgress(p),
                          timeRemaining: _formatTimeRemaining(p),
                          isActive: true,
                          onTap: () {
                            final clueId =
                                p['clue_id'] ?? p['clues']?['id'];
                            if (clueId != null) {
                              context.push('/clue/$clueId/play');
                            }
                          },
                        )),
                    const SizedBox(height: 32),
                  ],

                  if (completed.isNotEmpty) ...[
                    const Text(
                      '완료한 클루',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completed.map((p) => _ParticipationCard(
                          title: p['clue_title'] ??
                              p['clues']?['title'] ??
                              '클루',
                          progress: 1.0,
                          timeRemaining: '완료',
                          isActive: false,
                          onTap: () {
                            final clueId =
                                p['clue_id'] ?? p['clues']?['id'];
                            if (clueId != null) {
                              context.push('/clue/$clueId/result');
                            }
                          },
                        )),
                  ],

                  if (abandoned.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      '포기한 클루',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...abandoned.map((p) => _ParticipationCard(
                          title: p['clue_title'] ??
                              p['clues']?['title'] ??
                              '클루',
                          progress: _calcProgress(p),
                          timeRemaining: '포기',
                          isActive: false,
                          isAbandoned: true,
                          onTap: () {
                            final clueId =
                                p['clue_id'] ?? p['clues']?['id'];
                            if (clueId != null) {
                              context.push('/clue/$clueId');
                            }
                          },
                        )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calcProgress(Map<String, dynamic> p) {
    final completed = (p['completed_steps'] ?? 0) as int;
    final total = (p['total_steps'] ?? 1) as int;
    if (total == 0) return 0;
    return completed / total;
  }

  String _formatTimeRemaining(Map<String, dynamic> p) {
    final endsAt = p['ends_at'] ?? p['clues']?['ends_at'];
    if (endsAt == null) return '시간 제한 없음';

    try {
      final end = DateTime.parse(endsAt);
      final remaining = end.difference(DateTime.now());
      if (remaining.isNegative) return '시간 초과';
      if (remaining.inDays > 0) return '${remaining.inDays}일 남음';
      if (remaining.inHours > 0) return '${remaining.inHours}시간 남음';
      return '${remaining.inMinutes}분 남음';
    } catch (_) {
      return '';
    }
  }
}

class _ParticipationCard extends StatelessWidget {
  final String title;
  final double progress;
  final String timeRemaining;
  final bool isActive;
  final bool isAbandoned;
  final VoidCallback onTap;

  const _ParticipationCard({
    required this.title,
    required this.progress,
    required this.timeRemaining,
    required this.isActive,
    this.isAbandoned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isAbandoned
        ? Colors.grey
        : isActive
            ? Colors.blue
            : Colors.green;

    return Card(
      elevation: 0,
      color: isAbandoned
          ? AppColors.bgSurface
          : isActive
              ? Colors.blue[50]
              : AppColors.bgSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isAbandoned
              ? AppColors.borderDefault
              : isActive
                  ? Colors.blue[200]!
                  : AppColors.bgSurface,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAbandoned
                          ? '포기'
                          : isActive
                              ? '진행중'
                              : '완료',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bgSurface,
                  color: accentColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.timer : Icons.check_circle,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeRemaining,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
