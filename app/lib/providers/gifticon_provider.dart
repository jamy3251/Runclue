import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/gifticon_service.dart';
import 'auth_provider.dart';

final gifticonServiceProvider = Provider<GifticonService>((ref) {
  return GifticonService();
});

/// 다이아 사용처 카탈로그 — 활성 + display_order 정렬.
final gifticonCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.watch(gifticonServiceProvider);
  return svc.catalog();
});

/// 내 교환 내역 (pending / issued / failed).
final myRedemptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final svc = ref.watch(gifticonServiceProvider);
  return svc.myRedemptions();
});
