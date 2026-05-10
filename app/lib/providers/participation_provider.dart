import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/participation_service.dart';
import 'auth_provider.dart';

/// Singleton provider for [ParticipationService].
final participationServiceProvider = Provider<ParticipationService>((ref) {
  return ParticipationService();
});

/// FutureProvider for the current user's participations.
final myParticipationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(participationServiceProvider);
  return service.getMyParticipations(userId);
});

/// Family provider for a single participation by clue ID (for the current user).
final currentParticipationProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, clueId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(participationServiceProvider);
  return service.getParticipation(clueId, userId);
});

/// Family provider for the leaderboard of a specific clue.
final leaderboardProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clueId) async {
  final service = ref.watch(participationServiceProvider);
  return service.getLeaderboard(clueId);
});
