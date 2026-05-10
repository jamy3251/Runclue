import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// 푸시 알림 서비스.
///
/// Phase 1: flutter_local_notifications로 인앱 알림
/// Phase 2: FCM + Supabase Edge Function으로 원격 푸시
///
/// 알림 유형:
///   evidence_submitted → "친구가 인증했어요!" (FOMO 트리거)
///   step_completed     → "Step 2 완료!" (진행 상황)
///   validation_result  → "인증이 승인되었습니다" / "반려되었습니다"
///   clue_completed     → "미션 완료!" (축하)
class PushNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 초기화. main()에서 한 번 호출.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// 로컬 알림 표시
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'runclue_channel',
      'RunClue 알림',
      channelDescription: '미션 진행 관련 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  /// 알림 유형별 편의 메서드
  static Future<void> notifyEvidenceSubmitted(String stepTitle, {String? clueId}) async {
    await showNotification(
      title: '새 인증이 도착했어요!',
      body: '"$stepTitle" 스텝에 인증이 제출되었습니다',
      payload: clueId != null ? 'clue:$clueId' : null,
    );
  }

  static Future<void> notifyStepCompleted(int stepIndex, String stepTitle, {String? clueId}) async {
    await showNotification(
      title: 'Step ${stepIndex + 1} 완료!',
      body: '"$stepTitle"을 완료했습니다',
      payload: clueId != null ? 'clue:$clueId' : null,
    );
  }

  static Future<void> notifyValidationResult({
    required bool approved,
    required String stepTitle,
    String? clueId,
  }) async {
    await showNotification(
      title: approved ? '인증 승인!' : '인증 반려',
      body: approved
          ? '"$stepTitle" 인증이 승인되었습니다'
          : '"$stepTitle" 인증이 반려되었습니다. 다시 시도해주세요.',
      payload: clueId != null ? 'clue:$clueId' : null,
    );
  }

  static Future<void> notifyClueCompleted(String clueTitle, {String? clueId}) async {
    await showNotification(
      title: '미션 완료! 🎉',
      body: '"$clueTitle" 미션을 완료했습니다!',
      payload: clueId != null ? 'clue_result:$clueId' : null,
    );
  }

  /// GoRouter navigatorKey — main()에서 설정 필요
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// 네비게이터 키 설정. main()에서 router의 navigatorKey를 전달.
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    // payload format: "type:id" e.g. "clue:abc123", "post:xyz456"
    final parts = payload.split(':');
    if (parts.length != 2) return;

    final type = parts[0];
    final id = parts[1];

    switch (type) {
      case 'clue':
        GoRouter.of(context).push('/clue/$id');
      case 'clue_result':
        GoRouter.of(context).push('/clue/$id/result');
      case 'post':
        GoRouter.of(context).push('/post/$id');
      case 'progress':
        GoRouter.of(context).push('/progress');
      default:
        GoRouter.of(context).push('/explore');
    }
  }
}
