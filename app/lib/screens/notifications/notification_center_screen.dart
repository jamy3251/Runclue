import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: Text(
          '알림',
          style: AppTextStyles.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(),
            child: Text(
              '모두 읽음',
              style: AppTextStyles.label.copyWith(color: AppColors.brandYellow),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandYellow),
        ),
        error: (error, _) => _buildErrorState(error),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildNotificationList(notifications);
        },
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    final grouped = _groupByDate(notifications);

    return RefreshIndicator(
      color: AppColors.brandYellow,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.sm,
        ),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final group = grouped[index];
          return _buildDateGroup(group);
        },
      ),
    );
  }

  Widget _buildDateGroup(_DateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
            left: AppSpacing.xs,
          ),
          child: Text(
            group.label,
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
          ),
        ),
        ...group.notifications.map((n) => _buildNotificationTile(n)),
      ],
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] as String? ?? 'general';
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final createdAt = DateTime.tryParse(
      notification['created_at'] as String? ?? '',
    );
    final notificationId = notification['id'] as String;

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        return true;
      },
      onDismissed: (_) => _deleteNotification(notificationId),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isRead ? AppColors.bgSurface : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isRead
                  ? AppColors.borderSubtle
                  : AppColors.brandYellow.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBgColor(type),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm + 4),
                ),
                child: Icon(
                  _iconForType(type),
                  color: _iconColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w400 : FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: AppSpacing.sm),
                            decoration: const BoxDecoration(
                              color: AppColors.brandYellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _timeAgo(createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '알림이 없습니다',
            style: AppTextStyles.headingMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '새로운 소식이 오면 여기에 표시됩니다',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '알림을 불러올 수 없습니다',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(notificationsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(
              '다시 시도',
              style: AppTextStyles.label.copyWith(
                color: AppColors.brandYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────

  Future<void> _markAllAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final service = ref.read(notificationServiceProvider);
      await service.markAllAsRead(userId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '모든 알림을 읽음으로 표시했습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.bgElevated,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '오류가 발생했습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.deleteNotification(notificationId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '삭제에 실패했습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    final notificationId = notification['id'] as String;
    final isRead = notification['is_read'] == true;

    // 읽지 않은 경우 읽음 처리
    if (!isRead) {
      final service = ref.read(notificationServiceProvider);
      service.markAsRead(notificationId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }

    // 1) 타입별 기본 경로 — 명시 route가 없어도 사용자가 어디로 가야 할지 안내
    final type = notification['type']?.toString();
    final data = (notification['data'] ??
        notification['payload']) as Map<String, dynamic>?;

    String? route;
    switch (type) {
      case 'reward_earned':
        route = '/rewards?tab=gifts';
        break;
      case 'evidence_approved':
      case 'evidence_rejected':
      case 'clue_started':
      case 'clue_ended':
      case 'clue_approved':
      case 'clue_rejected':
        final clueId = data?['clue_id']?.toString();
        if (clueId != null) route = '/clue/$clueId';
        break;
      case 'clan_invite':
        route = '/community';
        break;
    }

    // 2) 명시 route가 있으면 덮어쓰기
    final explicit = data?['route'] as String?;
    if (explicit != null && explicit.isNotEmpty) route = explicit;

    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  IconData _iconForType(String type) {
    switch (type) {
      case 'clue_start':
      case 'clue_update':
        return Icons.explore_rounded;
      case 'mission_complete':
        return Icons.emoji_events_rounded;
      case 'badge':
        return Icons.military_tech_rounded;
      case 'community':
      case 'comment':
        return Icons.forum_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'system':
        return Icons.info_rounded;
      case 'ranking':
        return Icons.leaderboard_rounded;
      case 'invite':
        return Icons.mail_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'clue_start':
      case 'clue_update':
        return AppColors.brandBlue;
      case 'mission_complete':
      case 'badge':
        return AppColors.brandYellow;
      case 'community':
      case 'comment':
        return AppColors.brandGreen;
      case 'follow':
        return AppColors.brandPurple;
      case 'system':
        return AppColors.textSecondary;
      case 'ranking':
        return AppColors.brandOrange;
      case 'invite':
        return AppColors.brandBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _iconBgColor(String type) {
    return _iconColor(type).withValues(alpha: 0.12);
  }

  List<_DateGroup> _groupByDate(List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<Map<String, dynamic>>> groups = {
      '오늘': [],
      '어제': [],
      '이번 주': [],
      '이전': [],
    };

    for (final n in notifications) {
      final createdAt = DateTime.tryParse(n['created_at'] as String? ?? '');
      if (createdAt == null) {
        groups['이전']!.add(n);
        continue;
      }

      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (date == today || date.isAfter(today)) {
        groups['오늘']!.add(n);
      } else if (date == yesterday || (date.isAfter(yesterday) && date.isBefore(today))) {
        groups['어제']!.add(n);
      } else if (date.isAfter(weekAgo)) {
        groups['이번 주']!.add(n);
      } else {
        groups['이전']!.add(n);
      }
    }

    return groups.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _DateGroup(label: e.key, notifications: e.value))
        .toList();
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}개월 전';
    return '${(diff.inDays / 365).floor()}년 전';
  }
}

class _DateGroup {
  final String label;
  final List<Map<String, dynamic>> notifications;

  const _DateGroup({required this.label, required this.notifications});
}
