import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/battle_service.dart';
import 'auth_provider.dart';

final battleServiceProvider = Provider<BattleService>((ref) {
  return BattleService();
});

/// matchId polling — 큐 상태 → matched 전환 감지용.
final battleMatchProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, matchId) async* {
  final svc = ref.watch(battleServiceProvider);
  while (true) {
    try {
      yield await svc.fetchMatch(matchId);
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

final myBattleHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(battleServiceProvider).myHistory(userId);
});
