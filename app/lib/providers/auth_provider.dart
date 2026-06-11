import '../config/supabase_safe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/anonymous_auth_service.dart';

/// Singleton provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider that watches the Supabase auth state.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Singleton provider for [AnonymousAuthService].
final anonymousAuthServiceProvider = Provider<AnonymousAuthService>((ref) {
  return AnonymousAuthService();
});

/// Derived provider that exposes the currently authenticated [User], or null.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
    data: (state) => state.session?.user,
  );
});

/// Provider for the current user's ID (convenience shortcut).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// FutureProvider that fetches the current user's profile from Supabase.
///
/// Returns null when no user is logged in.
final currentProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  try {
    final client = safeClient;
    final response = await client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    return response;
  } catch (e) {
    throw Exception('Failed to fetch profile: $e');
  }
});

/// 로그인 직후 라우팅 결정 — 소셜/익명 가입자(guest_*)는 닉네임 설정으로,
/// 이미 닉네임이 있으면 홈으로. 프로필 조회 실패 시 홈 (graceful).
Future<String> postLoginRoute(WidgetRef ref) async {
  try {
    ref.invalidate(currentProfileProvider);
    final profile = await ref.read(currentProfileProvider.future);
    final nickname = profile?['nickname'] as String? ?? '';
    if (nickname.startsWith('guest_')) return '/onboarding/nickname';
  } catch (_) {/* 프로필 조회 실패 → 홈 */}
  return '/home';
}
