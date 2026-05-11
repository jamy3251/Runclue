import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reward_service.dart';
import 'auth_provider.dart';

final rewardServiceProvider = Provider<RewardService>((_) => RewardService());

/// 선물함 — 미수령 보상
final myUnclaimedRewardsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(rewardServiceProvider).getUnclaimed(userId);
});

/// 인벤토리 — 수령한 보상
final myClaimedRewardsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(rewardServiceProvider).getClaimed(userId);
});

/// 선물함 미수령 카운트 — 내 정보 탭 뱃지용. 항상 0 이상.
final unclaimedRewardsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  return ref.watch(rewardServiceProvider).unclaimedCount(userId);
});
