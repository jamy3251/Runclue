import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/currency_service.dart';
import 'auth_provider.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// 현재 사용자 코인+다이아 잔액. 적립/차감 후 ref.invalidate로 갱신.
final balancesProvider =
    FutureProvider<({int coin, int diamond})>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return (coin: 0, diamond: 0);
  final svc = ref.watch(currencyServiceProvider);
  return svc.fetchBalances(userId);
});

/// 오늘 코인 적립 누계 (일일 캡 500 알림용).
final todayCoinEarnedProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  final svc = ref.watch(currencyServiceProvider);
  return svc.todayCoinEarned(userId);
});

/// 최근 코인 ledger 30개.
final recentCoinLedgerProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final svc = ref.watch(currencyServiceProvider);
  return svc.recentCoinLedger(userId);
});

/// 최근 다이아 ledger 30개.
final recentDiamondLedgerProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final svc = ref.watch(currencyServiceProvider);
  return svc.recentDiamondLedger(userId);
});
