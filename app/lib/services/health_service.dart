import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 걸음수 코인 적립 (트랙 E, Step 13).
///
/// - Android: Health Connect (앱 설치 필요, Play Store에서 자동 권장)
/// - iOS: HealthKit (기본 내장)
///
/// 1000걸음당 +10 코인, 일 최대 50 코인.
/// 클라이언트가 오늘 누적 걸음 X 측정 → claim_walk_reward(X) 호출 →
/// 서버가 이미 적립 분과 차이만 grant_coin.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  final SupabaseClient _client = safeClient;
  bool _configured = false;

  static const _types = <HealthDataType>[HealthDataType.STEPS];
  static const _perms = <HealthDataAccess>[HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('⚠ [health] configure: $e');
    }
    _configured = true;
  }

  /// 권한 요청 — 한 번 거부하면 OS 설정 가야 다시 묻기 때문에 UI 측에서 신중히 호출.
  Future<bool> requestPermission() async {
    await _ensureConfigured();
    try {
      final ok = await _health.requestAuthorization(_types, permissions: _perms);
      return ok;
    } catch (e) {
      debugPrint('⚠ [health] auth: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    await _ensureConfigured();
    try {
      final p = await _health.hasPermissions(_types, permissions: _perms);
      return p ?? false;
    } catch (_) {
      return false;
    }
  }

  /// KST 오늘 자정 ~ 현재까지 누적 걸음수.
  Future<int> todaySteps() async {
    await _ensureConfigured();
    try {
      final nowUtc = DateTime.now().toUtc();
      final kstNow = nowUtc.add(const Duration(hours: 9));
      final kstMidnight =
          DateTime(kstNow.year, kstNow.month, kstNow.day);
      final startUtc = kstMidnight.subtract(const Duration(hours: 9));
      final steps = await _health.getTotalStepsInInterval(startUtc, nowUtc);
      return steps ?? 0;
    } catch (e) {
      debugPrint('⚠ [health] todaySteps: $e');
      return 0;
    }
  }

  /// 오늘 걸음 보상 상태 (서버 측 기록).
  Future<Map<String, dynamic>> todayStatus() async {
    final res = await _client.rpc('today_walk_status');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// claim — steps 측정 + RPC 호출. 반환: {ok, steps, eligible_coin, delta, ...}
  Future<Map<String, dynamic>> claim() async {
    final steps = await todaySteps();
    final res = await _client.rpc('claim_walk_reward', params: {
      'steps_total_in': steps,
    });
    if (res is Map) {
      final m = Map<String, dynamic>.from(res);
      m['client_steps'] = steps;
      return m;
    }
    return {'ok': false, 'reason': 'unexpected_response', 'client_steps': steps};
  }
}
