import '../config/supabase_safe.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// 딥링크 생성/파싱/처리를 담당하는 서비스.
///
/// URL 형식: https://runclue.app/clue/{clueId}
/// 앱 미설치 시: 웹 랜딩 페이지로 이동 (Flutter Web)
/// 앱 설치 시: Android App Links / iOS Universal Links로 앱 실행
///
/// 플로우:
///   1. Host가 클루 생성 후 "공유" 클릭
///   2. DeepLinkService.shareClue() → 카톡/시스템 공유 시트
///   3. Participant가 링크 클릭 → /join/:id로 라우팅
///   4. 비회원이면 AnonymousAuthService로 익명 인증 후 참여
class DeepLinkService {
  static const _baseUrl = 'https://runclue.app';

  /// 클루 공유 링크를 생성한다.
  static String generateClueLink(String clueId) {
    return '$_baseUrl/clue/$clueId';
  }

  /// 클루 링크를 시스템 공유 시트로 공유한다.
  static Future<void> shareClue({
    required String clueId,
    required String clueTitle,
    String? message,
  }) async {
    final link = generateClueLink(clueId);
    final text = message ?? '🏃 "$clueTitle" 미션에 도전하세요!\n$link';
    await Share.share(text);
  }

  /// 딥링크 URL에서 clueId를 추출한다.
  /// 유효하지 않은 URL이면 null 반환.
  static String? parseClueId(String url) {
    try {
      final uri = Uri.parse(url);

      // https://runclue.app/clue/{clueId}
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'clue') {
        final clueId = uri.pathSegments[1];
        if (clueId.isNotEmpty) return clueId;
      }

      // https://runclue.app/join/{clueId} (대체 형식)
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
        return uri.pathSegments[1];
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Supabase에서 클루가 존재하고 참여 가능한 상태인지 확인한다.
  static Future<Map<String, dynamic>?> validateClueLink(String clueId) async {
    try {
      final client = safeClient;
      final response = await client
          .from('clues')
          .select('id, title, description, status, current_participants, max_participants, start_time, end_time, thumbnail_url, category')
          .eq('id', clueId)
          .maybeSingle();

      if (response == null) return null;

      final status = response['status'] as String?;
      if (status != 'active' && status != 'approved') return null;

      return response;
    } catch (_) {
      return null;
    }
  }

  /// 딥링크를 GoRouter로 처리한다.
  /// 앱 시작 시 또는 앱 실행 중 딥링크 수신 시 호출.
  static void handleDeepLink(BuildContext context, String url) {
    final clueId = parseClueId(url);
    if (clueId != null) {
      context.push('/join/$clueId');
    }
  }
}
