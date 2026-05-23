import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/quest_service.dart';
import 'auth_provider.dart';

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService();
});

/// 오늘 미션 상태 — 진행 카운트 + 이미 받은 quest 목록 + 출석 streak.
/// claim 후 ref.invalidate(todayQuestStatusProvider)로 갱신.
final todayQuestStatusProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {'ok': false, 'reason': 'not_logged_in'};
  final svc = ref.watch(questServiceProvider);
  return svc.todayStatus();
});
