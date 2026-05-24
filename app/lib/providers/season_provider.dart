import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/season_service.dart';
import 'auth_provider.dart';

final seasonServiceProvider = Provider<SeasonService>((ref) {
  return SeasonService();
});

/// 현재 KST 주의 시즌 (active). 없으면 ensure로 생성됨.
final currentSeasonProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final svc = ref.watch(seasonServiceProvider);
  // ensure를 먼저 호출 — cron 누락 시에도 새 시즌 생성
  await svc.ensureCurrent();
  return svc.currentSeason();
});

/// 시즌 리더보드 Top 100.
final seasonLeaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(seasonServiceProvider).leaderboard();
});

/// 내 과거 시즌 보상.
final mySeasonRewardsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(seasonServiceProvider).myRewards(userId);
});
