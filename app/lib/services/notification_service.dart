import '../config/supabase_safe.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

/// Singleton provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// FutureProvider: 현재 사용자의 알림 목록.
final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications(userId);
});

/// FutureProvider: 읽지 않은 알림 수.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount(userId);
});

class NotificationService {
  final SupabaseClient _client = safeClient;
  RealtimeChannel? _channel;

  /// Get paginated notifications for a user.
  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for a user.
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Get the count of unread notifications.
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Subscribe to real-time notification inserts for a user.
  ///
  /// Returns a stream that emits new notification records.
  Stream<Map<String, dynamic>> subscribeToNotifications(String userId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            controller.add(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .subscribe();

    controller.onCancel = () {
      unsubscribe();
    };

    return controller.stream;
  }

  /// Unsubscribe from real-time notifications.
  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
