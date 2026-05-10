import '../config/supabase_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 딥링크로 진입한 비회원이 가입 없이 미션에 참여할 수 있도록
/// Supabase anonymous auth + localStorage 세션 ID를 관리한다.
///
/// 플로우:
///   딥링크 클릭 → signInAnonymously() → profile 자동 생성 (handle_new_user 트리거)
///   → localStorage에 세션 ID 저장 → 브라우저 재접속 시 복구
class AnonymousAuthService {
  final SupabaseClient _client = safeClient;
  static const _sessionKey = 'runclue_anonymous_session_id';

  /// 익명으로 로그인한다. 이미 익명 세션이 있으면 재사용.
  /// handle_new_user 트리거가 profiles에 'guest_XXXX' 닉네임으로 행을 생성한다.
  Future<User> signInAnonymously() async {
    // 기존 익명 세션 확인
    final currentUser = _client.auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      return currentUser;
    }

    // 저장된 세션 복구 시도
    final savedSessionId = await _getSavedSessionId();
    if (savedSessionId != null && currentUser != null) {
      return currentUser;
    }

    // 새 익명 세션 생성
    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    if (user == null) {
      throw Exception('익명 로그인 실패: 사용자 정보를 받지 못했습니다');
    }

    await _saveSessionId(user.id);
    return user;
  }

  /// 현재 사용자가 익명 사용자인지 확인
  bool get isAnonymous {
    final user = _client.auth.currentUser;
    return user != null && user.isAnonymous;
  }

  /// 익명 사용자를 정식 계정으로 전환 (카카오 로그인 등)
  /// 기존 참여 기록이 새 계정으로 이전된다.
  Future<User> upgradeToFullAccount({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
    final user = response.user;
    if (user == null) {
      throw Exception('계정 전환 실패');
    }
    await _clearSessionId();
    return user;
  }

  Future<void> _saveSessionId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }

  Future<String?> _getSavedSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> _clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
