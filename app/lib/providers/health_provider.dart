import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_service.dart';
import 'auth_provider.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService.instance;
});

/// 오늘 걸음 보상 상태 (서버 기록 — steps_reported + coins_awarded + remaining).
final todayWalkStatusProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {'ok': false, 'reason': 'not_logged_in'};
  final svc = ref.watch(healthServiceProvider);
  return svc.todayStatus();
});
