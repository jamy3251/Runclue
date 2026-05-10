import 'dart:async';
import 'dart:io';

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

    // Supabase 초기화 — 실패해도 앱은 실행
    try {
      if (SupabaseConfig.url.isNotEmpty &&
          !SupabaseConfig.url.contains('your-project') &&
          SupabaseConfig.anonKey.isNotEmpty) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        debugPrint('Supabase initialized: ${SupabaseConfig.url}');
      } else {
        debugPrint('Supabase skipped — no valid config');
      }
    } catch (e) {
      debugPrint('Supabase init failed (UI preview mode): $e');
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
