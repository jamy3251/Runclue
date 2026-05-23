import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wallet_service.dart';
import 'auth_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final topupSummaryProvider =
    FutureProvider<({int gross, int fee, int net, int topupCount})>(
        (ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return (gross: 0, fee: 0, net: 0, topupCount: 0);
  return ref.watch(walletServiceProvider).topupSummary(userId);
});

final myTopupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(walletServiceProvider).myTopups(userId);
});

final myCluePoolsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(walletServiceProvider).myCluePools(userId);
});

final storeRevenueProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(walletServiceProvider).storeRevenue(userId);
});

final storeRevenueSumProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  return ref.watch(walletServiceProvider).storeRevenueSum(userId);
});
