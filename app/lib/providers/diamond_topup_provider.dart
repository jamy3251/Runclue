import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/diamond_topup_service.dart';

final diamondTopupServiceProvider = Provider<DiamondTopupService>((ref) {
  return DiamondTopupService();
});

/// 활성 다이아 패키지 카탈로그.
final diamondPackagesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.watch(diamondTopupServiceProvider);
  return svc.fetchPackages();
});

/// 본인 다이아 충전 내역.
final myDiamondTopupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.watch(diamondTopupServiceProvider);
  return svc.myTopups();
});
