import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Supabase 클라이언트를 안전하게 가져오는 헬퍼.
/// 초기화 안 됐으면 더미 클라이언트 반환 (UI 미리보기 모드).
SupabaseClient get safeClient {
  try {
    return Supabase.instance.client;
  } catch (e) {
    debugPrint('safeClient fallback: $e');
    return SupabaseClient(
      'https://placeholder.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2MDAwMDAwMDAsImV4cCI6MjAwMDAwMDAwMH0.placeholder',
    );
  }
}

/// Supabase가 실제로 초기화되었는지 확인
bool get isSupabaseReady {
  try {
    Supabase.instance.client;
    return SupabaseConfig.url.isNotEmpty &&
           !SupabaseConfig.url.contains('your-project');
  } catch (_) {
    return false;
  }
}
