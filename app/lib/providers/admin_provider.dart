import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// 현재 사용자가 admin인지 확인 (라우트 가드용).
final isAdminProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.isCurrentUserAdmin();
});

/// 어드민 통계.
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.getStats();
});

/// 어드민 — 전체 클루 목록.
final adminAllCluesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.listAllClues();
});

/// 어드민 — 전체 보상 목록.
final adminAllRewardsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.listAllRewards();
});

/// 어드민 — 기프티콘 카탈로그 (비활성 포함).
final adminGifticonsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.listGifticons();
});

/// 어드민 — 발급 대기 교환 요청 큐.
final adminPendingRedemptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(adminServiceProvider);
  return svc.pendingRedemptions();
});
