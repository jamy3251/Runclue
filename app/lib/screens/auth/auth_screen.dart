import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/platform_stats_service.dart';

/// 로그인 화면 — PDF spec Page 4 (Login.tsx)
///
/// 구조:
///   A) 히어로 배경: #07070E + 레이더 링/오브 글로우 SVG 애니메이션
///   B) 슬로건: Black Han Sans 42px, 3행 "뛰자, / 풀자, / 벌자."
///   C) 사회증명 배너: 아바타 5개 + LIVE 녹색 도트 + "N명 지금 활동 중"
///   D) 입력 필드: bg rgba(255,255,255,0.04), border rgba(255,255,255,0.08)
///   E) 메인 CTA: gradient #FACC15→#F59E0B + shimmer
///   F) 소셜 로그인 3종: 카카오 #FAE100, 네이버 #03C75A, Google
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _radarController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();

    _radarController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _radarController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OAuth 딥링크 복귀 시 세션이 수립되면 자동 라우팅 (닉네임 미설정자는 설정으로)
    ref.listen(authStateProvider, (prev, next) async {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.signedIn && mounted) {
        final route = await postLoginRoute(ref);
        if (mounted) context.go(route);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgHero,
      body: Stack(
        children: [
          // A) 레이더 링 + 오브 글로우 배경 애니메이션
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadarPainter(
                    progress: _radarController.value,
                    glowValue: _glowController.value,
                  ),
                );
              },
            ),
          ),

          // 메인 콘텐츠
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController, curve: Curves.easeOut,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 로고 + 활동 수
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('R',
                            style: GoogleFonts.blackHanSans(
                              fontSize: 18, color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('RUNCLUE',
                          style: GoogleFonts.blackHanSans(
                            fontSize: 16, color: AppColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        // 실시간 활동자 수 (실데이터 — platformStatsProvider)
                        Builder(builder: (context) {
                          final stats =
                              ref.watch(platformStatsProvider).valueOrNull;
                          final n = stats?.totalParticipants ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  n > 0 ? '탐험가 $n명' : '얼리 액세스',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // B) 슬로건 — 3행 Black Han Sans
                    Text('방문하자,',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 48, color: AppColors.brandYellow, height: 1.1,
                      ),
                    ),
                    Text('풀자,',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 48, color: AppColors.brandYellow, height: 1.1,
                      ),
                    ),
                    Text('벌자.',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 48, color: AppColors.brandYellow, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('AR 기반 캠퍼스타운 상생 리워드 플랫폼',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14, color: AppColors.textMuted,
                      ),
                    ),
                    Text('탐험가 · 크리에이터 · 사장님 3자 생태계',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13, color: AppColors.textDisabled,
                      ),
                    ),

                    const Spacer(flex: 1),

                    // C) 사회증명 배너
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          // 아바타 스택
                          SizedBox(
                            width: 76, height: 28,
                            child: Stack(
                              children: List.generate(5, (i) {
                                return Positioned(
                                  left: i * 15.0,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: [
                                      AppColors.brandYellow,
                                      AppColors.brandBlue,
                                      AppColors.brandGreen,
                                      AppColors.brandOrange,
                                      AppColors.brandPurple,
                                    ][i],
                                    child: Icon(Icons.person, size: 14, color: Colors.black),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(builder: (context) {
                              final stats = ref
                                  .watch(platformStatsProvider)
                                  .valueOrNull;
                              final n = stats?.totalParticipants ?? 0;
                              final clues = stats?.totalClues ?? 0;
                              return RichText(
                                text: TextSpan(
                                  style:
                                      GoogleFonts.notoSansKr(fontSize: 12),
                                  children: n > 0
                                      ? [
                                          TextSpan(
                                            text: '탐험가 $n명',
                                            style: const TextStyle(
                                              color: AppColors.brandGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(
                                            text: clues > 0
                                                ? '과 클루 $clues개가 기다리고 있어요'
                                                : '이 함께하고 있어요',
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textSecondary),
                                          ),
                                        ]
                                      : [
                                          const TextSpan(
                                            text:
                                                '지금 합류하면 첫 시즌의 개척자가 됩니다',
                                            style: TextStyle(
                                                color: AppColors
                                                    .textSecondary),
                                          ),
                                        ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // E) 메인 CTA — "크루 합류하기"
                    // 세션이 있으면 홈으로, 없으면 로그인 화면으로
                    Builder(builder: (context) {
                      bool hasSession = false;
                      try {
                        hasSession =
                            Supabase.instance.client.auth.currentSession !=
                                null;
                      } catch (_) {/* 미초기화면 false */}
                      return _YellowCTA(
                        label: hasSession ? '내 크루로 들어가기' : '크루 합류하기',
                        onPressed: () => context.go(
                          hasSession ? '/home' : '/auth/login',
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // F) 소셜 로그인 — 카카오 / Google (+ iOS는 Apple, 심사 요건)
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            color: const Color(0xFFFAE100),
                            icon: Icons.chat_bubble_rounded,
                            iconColor: Colors.black,
                            label: '카카오',
                            labelColor: Colors.black,
                            onPressed: () => _handleOAuthLogin(context, ref, 'kakao'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialButton(
                            color: Colors.white,
                            icon: Icons.g_mobiledata_rounded,
                            iconColor: Colors.black,
                            label: 'Google',
                            labelColor: Colors.black,
                            onPressed: () => _handleOAuthLogin(context, ref, 'google'),
                          ),
                        ),
                        if (!kIsWeb && Platform.isIOS) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SocialButton(
                              color: Colors.black,
                              icon: Icons.apple,
                              label: 'Apple',
                              onPressed: () =>
                                  _handleOAuthLogin(context, ref, 'apple'),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 이메일 로그인 + 약관
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/auth/login'),
                        child: Text('이메일로 로그인',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13, color: AppColors.textMuted,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '가입 시 이용약관 및 개인정보처리방침에 동의합니다',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 10, color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOAuthLogin(
    BuildContext context, WidgetRef ref, String provider,
  ) async {
    try {
      final authService = ref.read(authServiceProvider);
      final oauthProvider = switch (provider) {
        'kakao' => OAuthProvider.kakao,
        'google' => OAuthProvider.google,
        'apple' => OAuthProvider.apple,
        _ => OAuthProvider.kakao,
      };
      // 외부 브라우저에서 인증 진행 — 복귀 시 authStateProvider listen이 라우팅
      await authService.signInWithOAuth(oauthProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('브라우저에서 로그인을 완료하면 자동으로 이동합니다'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}

// ─── Yellow CTA Button (spec E) ───
class _YellowCTA extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _YellowCTA({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.brandYellow, AppColors.brandYellowDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandYellow.withValues(alpha: 0.4),
              blurRadius: 20, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Center(
              child: Text(label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Social Login Button (spec F) ───
class _SocialButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.color,
    required this.icon,
    this.iconColor,
    required this.label,
    this.labelColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: iconColor ?? Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.white),
            const SizedBox(width: 6),
            Text(label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: labelColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Radar Ring + Glow Background (spec A) ───
class _RadarPainter extends CustomPainter {
  final double progress;
  final double glowValue;

  _RadarPainter({required this.progress, required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.3);

    // 글로우 오브
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.brandYellow.withValues(alpha: 0.06 + 0.04 * glowValue),
          AppColors.brandYellow.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 200));
    canvas.drawCircle(center, 200, glowPaint);

    // 레이더 링들 (확장하며 사라짐)
    for (var i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = 40 + ringProgress * 180;
      final opacity = (1.0 - ringProgress) * 0.12;

      if (opacity > 0) {
        final ringPaint = Paint()
          ..color = AppColors.brandYellow.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(center, radius, ringPaint);
      }
    }

    // 레이더 스윕 라인
    final sweepAngle = progress * 2 * pi;
    final sweepEnd = Offset(
      center.dx + cos(sweepAngle) * 200,
      center.dy + sin(sweepAngle) * 200,
    );
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.brandYellow.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(center, sweepEnd))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, sweepEnd, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.glowValue != glowValue;
}
