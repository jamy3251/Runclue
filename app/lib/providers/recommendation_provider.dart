import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/recommendation_service.dart';
import 'auth_provider.dart';
import 'clue_provider.dart' show userPositionProvider;

final recommendationServiceProvider =
    Provider<RecommendationService>((ref) => RecommendationService());

/// 사용자 현재 위치 + ID 기반 추천 클루 리스트.
/// 위치 또는 로그인 없으면 빈 리스트.
final recommendedCluesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final pos = ref.watch(userPositionProvider).valueOrNull;
  final userId = ref.watch(currentUserIdProvider);
  if (pos == null || userId == null) return [];

  final svc = ref.read(recommendationServiceProvider);
  return svc.recommendedForUser(
    lat: pos.latitude,
    lng: pos.longitude,
    userId: userId,
  );
});

/// 특정 클루의 같은 상권 다른 클루.
final sameDistrictProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clueId) async {
  final svc = ref.read(recommendationServiceProvider);
  return svc.sameDistrict(clueId: clueId);
});
