import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/store_service.dart';
import 'auth_provider.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

/// 사장 본인 메뉴 관리 — 모든 status 포함 (active=false도 표시).
final myMenusProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(storeServiceProvider).myMenus(userId);
});

/// 다른 사용자가 본 가게 메뉴 — active만.
final storeMenusProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, ownerId) async {
  return ref.watch(storeServiceProvider).storeMenus(ownerId);
});

/// 내 구매 내역 — 사용 가능한 QR 포함.
final myPurchasesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(storeServiceProvider).myPurchases(userId);
});

/// 사장이 받은 주문 (호스트 대시보드용).
final myStoreOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(storeServiceProvider).myStoreOrders(userId);
});
