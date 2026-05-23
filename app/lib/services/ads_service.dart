import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_safe.dart';

/// 보상형 비디오 광고 (트랙 C).
///
/// MVP는 클라이언트 신뢰: onUserEarnedReward 콜백 → claim_ad_reward RPC.
/// 본격 Google SSV 서버 검증은 Phase 2 (Edge Function ad-ssv-callback).
///
/// 광고 단위 ID:
///   debug → Google 공식 테스트 ID
///   release → --dart-define GMA_REWARDED_AD_UNIT_ANDROID/IOS 환경변수
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  RewardedAd? _ready;
  bool _loading = false;
  final SupabaseClient _client = safeClient;
  final _uuid = const Uuid();

  static const _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIos = 'ca-app-pub-3940256099942544/1712485313';

  String get _adUnitId {
    if (kReleaseMode) {
      final env = Platform.isAndroid
          ? const String.fromEnvironment('GMA_REWARDED_AD_UNIT_ANDROID')
          : const String.fromEnvironment('GMA_REWARDED_AD_UNIT_IOS');
      if (env.isNotEmpty) return env;
    }
    return Platform.isAndroid ? _testAndroid : _testIos;
  }

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    unawaited(_preload());
  }

  Future<void> _preload() async {
    if (_loading || _ready != null) return;
    _loading = true;
    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ready = ad;
            _loading = false;
          },
          onAdFailedToLoad: (err) {
            debugPrint('⚠ [ads] rewarded load failed: $err');
            _ready = null;
            _loading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('⚠ [ads] preload exception: $e');
      _loading = false;
    }
  }

  bool get isReady => _ready != null;

  /// 광고 시청 → 끝까지 본 경우 claim_ad_reward RPC 호출.
  /// 반환: {ok, reward_coin, today_count, cap} 또는 {ok: false, reason}
  Future<Map<String, dynamic>> showAndClaim() async {
    await init();
    if (_ready == null) {
      await _preload();
      // load 콜백 대기 — 짧은 폴링
      for (var i = 0; i < 30 && _ready == null && _loading; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    final ad = _ready;
    if (ad == null) {
      return {'ok': false, 'reason': 'ad_not_ready'};
    }
    _ready = null;

    final dismissed = Completer<void>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(_preload());
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('⚠ [ads] show failed: $err');
        a.dispose();
        unawaited(_preload());
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          earned = true;
        },
      );
    } catch (e) {
      return {'ok': false, 'reason': 'show_exception: $e'};
    }

    await dismissed.future;
    if (!earned) {
      return {'ok': false, 'reason': 'not_completed'};
    }

    // 보상 적립 (SSV는 Phase 2)
    final token = _uuid.v4();
    final res = await _client.rpc('claim_ad_reward', params: {
      'ad_unit_id_in': _adUnitId,
      'view_token_in': token,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  /// 오늘 광고 시청 카운트 (남은 횟수 표시용)
  Future<Map<String, dynamic>> todayCount() async {
    final res = await _client.rpc('today_ad_count');
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }
}
