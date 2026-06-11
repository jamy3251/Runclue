import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  // 전역 에러 핸들링 — 크래시 방지
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Google Maps: Android에서 Hybrid Composition 강제
    // SurfaceView 모드가 일부 디바이스(Note 9 등)에서 GPU 노이즈/터치 크래시 유발
    if (Platform.isAndroid) {
      try {
        final mapsImplementation = GoogleMapsFlutterPlatform.instance;
        if (mapsImplementation is GoogleMapsFlutterAndroid) {
          mapsImplementation.useAndroidViewSurface = true;
        }
      } catch (_) {/* 패키지 미가용 시 무시 */}
    }

    // Supabase 초기화 — 환경변수 누락 시 release 빌드에선 명확한 에러 화면.
    // 과거에 .env 빠진 채로 APK 빌드해서 회원가입/로그인 모두 실패한 사고가 있었음.
    final hasValidConfig = SupabaseConfig.url.isNotEmpty &&
        !SupabaseConfig.url.contains('your-project') &&
        SupabaseConfig.anonKey.isNotEmpty;

    String? initError;
    if (hasValidConfig) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        debugPrint('Supabase initialized: ${SupabaseConfig.url}');
      } catch (e) {
        initError = e.toString();
        debugPrint('Supabase init failed: $e');
      }
    } else {
      debugPrint(
          '⚠ Supabase config missing — build with: '
          'flutter build apk --release --dart-define-from-file=.env');
    }

    // Release 빌드 + config 누락이면 미스빌드 화면 노출
    if (!hasValidConfig && kReleaseMode) {
      runApp(const _MisbuildApp(
        reason: 'SUPABASE_URL / SUPABASE_ANON_KEY 누락',
        hint:
            '빌드 시 --dart-define-from-file=.env 옵션이 누락된 APK입니다.\n'
            'scripts/build_apk.ps1 로 다시 빌드해주세요.',
      ),);
      return;
    }
    if (initError != null && kReleaseMode) {
      runApp(_MisbuildApp(
        reason: 'Supabase 초기화 실패',
        hint: initError,
      ),);
      return;
    }

    runApp(
      const ProviderScope(
        child: RunClueApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack: $stack');
  });
}

/// 빌드 사고(환경변수 누락 / Supabase 초기화 실패) 시 첫 화면.
/// 사용자에게 '이건 잘못 빌드된 APK다' 라고 명확히 전달하기 위한 폴백.
class _MisbuildApp extends StatelessWidget {
  final String reason;
  final String hint;
  const _MisbuildApp({required this.reason, required this.hint});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunClue · 빌드 오류',
      home: Scaffold(
        backgroundColor: const Color(0xFF111115),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 56,),
                const SizedBox(height: 20),
                const Text('빌드 설정 오류',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),),
                const SizedBox(height: 12),
                Text(reason,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                    ),),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x12FFFFFF)),
                  ),
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEBEBEB),
                      height: 1.6,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '이 화면이 보이면 잘못된 APK입니다.\n개발자에게 빌드 옵션 누락을 알려주세요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA0A0A0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
