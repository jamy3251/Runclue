import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/clue_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

/// 디바이스 현재 GPS 위치 (1회성 fetch).
/// 권한 거부/불가 시 null 반환 (예외 던지지 않고 graceful degradation).
final userPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    final svc = LocationService();
    await svc.requestPermission();
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );
  } catch (_) {
    return null;
  }
});

/// Singleton provider for [ClueService].
final clueServiceProvider = Provider<ClueService>((ref) {
  return ClueService();
});

/// Family provider for nearby clues based on location and radius.
final nearbyCluesProvider = FutureProvider.family<List<Map<String, dynamic>>,
    ({double lat, double lng, double radius})>((ref, params) async {
  final clueService = ref.watch(clueServiceProvider);
  return clueService.getNearbyClues(params.lat, params.lng, params.radius);
});

/// Family provider for a single clue detail by ID.
final clueDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final clueService = ref.watch(clueServiceProvider);
  return clueService.getClueById(id);
});

/// FutureProvider for clues created by the current user.
final myCluesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final clueService = ref.watch(clueServiceProvider);
  return clueService.getMyClues(userId);
});

/// FutureProvider for trending clues.
final trendingCluesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final clueService = ref.watch(clueServiceProvider);
  return clueService.getTrendingClues();
});

/// Family provider for clue search results.
final clueSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  if (query.trim().isEmpty) return [];

  final clueService = ref.watch(clueServiceProvider);
  return clueService.searchClues(query);
});
