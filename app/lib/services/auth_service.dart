import '../config/supabase_safe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = safeClient;

  // Current user
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {'nickname': nickname},
      );
    } catch (e) {
      throw _toFriendlyError(e, '회원가입');
    }
  }

  // Sign in with email
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _toFriendlyError(e, '로그인');
    }
  }

  // Sign in with OAuth (Kakao, Google, etc.)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      return await _client.auth.signInWithOAuth(provider);
    } catch (e) {
      throw _toFriendlyError(e, '소셜 로그인');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _toFriendlyError(e, '비밀번호 재설정');
    }
  }

  /// 사용자에게 친숙한 한국어 에러 메시지로 변환
  Exception _toFriendlyError(Object e, String action) {
    final msg = e.toString();

    // Cloudflare 521 / 522 — Supabase 서버 다운/일시정지
    if (msg.contains('521') ||
        msg.contains('522') ||
        msg.contains('523') ||
        msg.contains('Web server is down')) {
      return Exception(
          '$action 실패: 서버가 일시 정지 상태입니다.\n잠시 후 다시 시도해주세요.');
    }

    // 네트워크 / DNS
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Network is unreachable') ||
        msg.contains('No address associated')) {
      return Exception('$action 실패: 인터넷 연결을 확인해주세요.');
    }

    // 타임아웃
    if (msg.contains('timed out') || msg.contains('TimeoutException')) {
      return Exception('$action 실패: 응답이 너무 오래 걸립니다.\n잠시 후 다시 시도해주세요.');
    }

    // 인증 에러
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
    }
    if (msg.contains('User already registered')) {
      return Exception('이미 가입된 이메일입니다.\n로그인을 시도해주세요.');
    }
    if (msg.contains('Email rate limit')) {
      return Exception('잠시 후 다시 시도해주세요. (요청 한도 초과)');
    }

    // 기타 — 짧게 자르기
    final clean = msg.replaceAll('Exception: ', '').trim();
    return Exception(
        '$action 실패: ${clean.length > 80 ? '${clean.substring(0, 80)}...' : clean}');
  }
}
