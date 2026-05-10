import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/supabase_safe.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _navigated) return;

    String target = '/auth';
    try {
      final session = safeClient.auth.currentSession;
      target = session != null ? '/home' : '/auth';
    } catch (e) {
      debugPrint('Splash navigation error: $e');
    }

    // 한 프레임 미뤄서 라우터 redirect와의 race 회피
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgHero,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'R',
                style: GoogleFonts.blackHanSans(
                  fontSize: 48,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'RUNCLUE',
              style: GoogleFonts.blackHanSans(
                fontSize: 28,
                color: AppColors.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '방문하자, 풀자, 벌자.',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
