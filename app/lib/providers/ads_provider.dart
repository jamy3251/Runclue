import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads_service.dart';
import 'auth_provider.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  return AdsService.instance;
});

/// 오늘 광고 시청 카운트 (남은 횟수).
/// 반환: {ok, today_count, cap, remaining}
final todayAdCountProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {'ok': false, 'reason': 'not_logged_in'};
  final svc = ref.watch(adsServiceProvider);
  return svc.todayCount();
});
