import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';
import 'auth_provider.dart';

/// Singleton provider for [ProfileService].
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// FutureProvider for the current user's profile (typed Map).
final myProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(profileServiceProvider);
  return service.getProfile(userId);
});

/// FutureProvider for the current user's badges.
final myBadgesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(profileServiceProvider);
  return service.getUserBadges(userId);
});

/// FutureProvider for the current user's clan.
final myClanProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(profileServiceProvider);
  return service.getUserClan(userId);
});

/// FutureProvider for weekly ranking.
final weeklyRankingProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.getWeeklyRanking();
});

/// Family provider for any user's profile by ID.
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.getProfile(userId);
});
