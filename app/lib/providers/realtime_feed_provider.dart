import '../config/supabase_safe.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 클루 진행 중 실시간 이벤트를 수신하는 통합 Provider.
///
/// Eng Review 결정: 4채널 → 2채널 통합 (Supabase 무료 플랜 200 connection 제한)
///   채널 1: 'clue:{clueId}' → evidence INSERT + participation UPDATE
///   채널 2: 'location:{clueId}' → Presence (위치 broadcast) [Sprint 5]
///
/// 사용:
///   final feed = ref.watch(realtimeFeedProvider(clueId));
///   feed.when(data: (events) => ..., loading: ..., error: ...);

/// 실시간 피드 이벤트 타입
enum FeedEventType {
  evidenceSubmitted,
  participationUpdated,
}

class FeedEvent {
  final FeedEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  FeedEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 특정 클루의 실시간 피드 스트림을 제공하는 Provider.
final realtimeFeedProvider =
    StreamProvider.family<FeedEvent, String>((ref, clueId) {
  final controller = StreamController<FeedEvent>.broadcast();

  // Supabase 미초기화 시 빈 스트림으로 graceful degradation
  if (!isSupabaseReady) {
    ref.onDispose(controller.close);
    return controller.stream;
  }

  RealtimeChannel? channel;
  try {
    final client = safeClient;
    final c = client.channel('clue:$clueId');

    c.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'evidences',
      callback: (payload) {
        controller.add(FeedEvent(
          type: FeedEventType.evidenceSubmitted,
          data: Map<String, dynamic>.from(payload.newRecord),
        ));
      },
    );

    c.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'evidences',
      callback: (payload) {
        controller.add(FeedEvent(
          type: FeedEventType.evidenceSubmitted,
          data: Map<String, dynamic>.from(payload.newRecord),
        ));
      },
    );

    c.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'participations',
      callback: (payload) {
        controller.add(FeedEvent(
          type: FeedEventType.participationUpdated,
          data: Map<String, dynamic>.from(payload.newRecord),
        ));
      },
    );

    c.subscribe();
    channel = c;
  } catch (e) {
    channel = null;
  }

  ref.onDispose(() {
    final ch = channel;
    if (ch != null) {
      try {
        safeClient.removeChannel(ch);
      } catch (_) {/* swallow during teardown */}
    }
    controller.close();
  });

  return controller.stream;
});

/// 특정 클루의 pending evidence 목록을 실시간으로 관리하는 Provider.
final pendingEvidencesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clueId) async {
  final client = safeClient;
  final response = await client
      .from('evidences')
      .select('*, steps!inner(clue_id, title, type)')
      .eq('steps.clue_id', clueId)
      .eq('status', 'pending')
      .order('created_at', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});
