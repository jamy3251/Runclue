import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Screen 01 · Login (로그인)
/// 명세 v2.0 §4.1 — 히어로 슬로건 + 사회증명 배너 + 이메일/비번 + 소셜 3열
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        final response = await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
        );
        // 자동 confirm 트리거 또는 confirm email 비활성화로 session 있으면 바로 로그인
        if (response.session != null) {
          if (mounted) context.go('/home');
        } else {
          // session 없으면 즉시 로그인 시도 (트리거로 confirm된 경우)
          try {
            await authService.signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
            if (mounted) context.go('/home');
          } catch (_) {
            // 로그인까지 실패하면 진짜 인증 메일 필요한 상태
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('인증 이메일을 발송했습니다. 이메일을 확인해주세요.')),
              );
            }
          }
        }
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isSignUp ? '회원가입' : '로그인'} 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgHero,
      body: Stack(
        children: [
          // 배경 레이어 1: 레이더 링
          const Positioned.fill(child: _RadarRings()),
          // 배경 레이어 2: 중앙 하단 옐로 글로우
          const Positioned(
            bottom: -120,
            left: 0,
            right: 0,
            child: _RadialGlow(
              size: 360,
              color: Color(0x0FFACC15),
            ),
          ),
          // 배경 레이어 3: 우상단 블루 오브
          const Positioned(
            top: -80,
            right: -60,
            child: _RadialGlow(
              size: 220,
              color: Color(0x0A38BDF8),
            ),
          ),

          // 콘텐츠
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 뒤로가기 (로그인은 보통 단독 진입이지만 회원가입 토글 시 위치 마커)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/auth'),
                    ),
                  ),

                  // 히어로 슬로건
                  const SizedBox(height: 8),
                  _HeroSlogan(),

                  const SizedBox(height: 28),

                  // 사회증명 배너
                  const _SocialProofBanner(),

                  const SizedBox(height: 28),

                  // 폼
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUp) ...[
                          _buildField(
                            controller: _nicknameController,
                            label: '닉네임',
                            hint: '런클루에서 사용할 이름',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (!_isSignUp) return null;
                              if (value == null || value.trim().isEmpty) {
                                return '닉네임을 입력해주세요';
                              }
                              if (value.trim().length < 2) {
                                return '닉네임은 2자 이상이어야 합니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildField(
                          controller: _emailController,
                          label: '이메일',
                          hint: 'example@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return '올바른 이메일 형식을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _passwordController,
                          label: '비밀번호',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            if (value.length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 메인 CTA — 크루 합류하기
                  _PrimaryYellowCTA(
                    label: _isSignUp ? '회원가입' : '크루 합류하기',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleSubmit,
                  ),

                  const SizedBox(height: 12),

                  // 보조 링크: 비밀번호 찾기 | 회원가입 토글
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isSignUp)
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            '비밀번호 찾기',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (!_isSignUp)
                        Container(
                          width: 1,
                          height: 12,
                          color: AppColors.borderDefault,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? '로그인' : '회원가입',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: AppColors.brandYellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.borderDefault)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.borderDefault)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 소셜 로그인 3열
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          provider: _SocialProvider.kakao,
                          onPressed: () => _handleOAuth('kakao'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SocialButton(
                          provider: _SocialProvider.naver,
                          onPressed: () => _handleOAuth('naver'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SocialButton(
                          provider: _SocialProvider.google,
                          onPressed: () => _handleOAuth('google'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: GoogleFonts.notoSansKr(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  Future<void> _handleOAuth(String providerKey) async {
    // OAuth는 auth_screen에서 처리하던 흐름과 동일하게 단순화
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$providerKey 로그인은 곧 지원됩니다'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀번호 찾기'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '가입한 이메일',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              try {
                final authService = ref.read(authServiceProvider);
                await authService.resetPassword(email);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('비밀번호 재설정 이메일을 발송했습니다.'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('실패: $e')),
                  );
                }
              }
            },
            child: const Text('보내기'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 히어로 슬로건
// ─────────────────────────────────────────────────────────────

class _HeroSlogan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RUNCLUE',
          style: GoogleFonts.blackHanSans(
            fontSize: 22,
            color: AppColors.brandYellow,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '방문하자,',
          style: GoogleFonts.blackHanSans(
            fontSize: 42,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
        ),
        Text(
          '풀자,',
          style: GoogleFonts.blackHanSans(
            fontSize: 42,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
        ),
        Text(
          '벌자.',
          style: GoogleFonts.blackHanSans(
            fontSize: 42,
            color: AppColors.brandYellow,
            height: 1.05,
            shadows: [
              Shadow(
                color: AppColors.brandYellow.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 사회증명 배너 — 5 아바타 + N명 활동 중
// ─────────────────────────────────────────────────────────────

class _SocialProofBanner extends StatelessWidget {
  const _SocialProofBanner();

  static const List<({String name, Color color})> _crew = [
    (name: '준', color: Color(0xFFFACC15)),
    (name: '지', color: Color(0xFF38BDF8)),
    (name: '서', color: Color(0xFF10B981)),
    (name: '민', color: Color(0xFFA78BFA)),
    (name: '하', color: Color(0xFFF97316)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          // LIVE pulse
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 아바타 5개 겹침
          SizedBox(
            width: 84,
            height: 24,
            child: Stack(
              children: [
                for (int i = 0; i < _crew.length; i++)
                  Positioned(
                    left: i * 15.0,
                    child: _AvatarPill(
                      label: _crew[i].name,
                      color: _crew[i].color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '127명 지금 활동 중',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPill extends StatelessWidget {
  final String label;
  final Color color;

  const _AvatarPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bgHero, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CTA 버튼
// ─────────────────────────────────────────────────────────────

class _PrimaryYellowCTA extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryYellowCTA({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.ctaYellow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [AppShadows.ctaYellow],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 소셜 로그인 버튼
// ─────────────────────────────────────────────────────────────

enum _SocialProvider { kakao, naver, google }

class _SocialButton extends StatelessWidget {
  final _SocialProvider provider;
  final VoidCallback onPressed;

  const _SocialButton({required this.provider, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (provider) {
      _SocialProvider.kakao => (
          const Color(0xFFFAE100),
          Colors.black,
          Icons.chat_bubble,
          '카카오',
        ),
      _SocialProvider.naver => (
          const Color(0xFF03C75A),
          Colors.white,
          Icons.eco,
          '네이버',
        ),
      _SocialProvider.google => (
          Colors.white,
          Colors.black,
          Icons.g_mobiledata_outlined,
          'Google',
        ),
    };

    return SizedBox(
      height: 48,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 배경 장식: 레이더 링 + radial glow
// ─────────────────────────────────────────────────────────────

class _RadarRings extends StatefulWidget {
  const _RadarRings();

  @override
  State<_RadarRings> createState() => _RadarRingsState();
}

class _RadarRingsState extends State<_RadarRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _RadarPainter(progress: _controller.value),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.08);

    final center = Offset(size.width * 0.85, size.height * 0.18);
    for (int i = 0; i < 4; i++) {
      final radius = 60.0 + (i * 50) + (progress * 30);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

class _RadialGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _RadialGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
