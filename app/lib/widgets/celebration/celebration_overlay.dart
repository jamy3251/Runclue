import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

/// Full-screen mission clear celebration with confetti + trophy glow.
///
/// Usage: CelebrationOverlay.show(context)
class CelebrationOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const CelebrationOverlay({super.key, this.onComplete});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.heavyImpact();
    if (!context.mounted) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => const CelebrationOverlay(),
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(vsync: this, duration: AppDurations.slow);
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.celebration,
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.08, end: 0.2).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _scaleCtrl.forward();
    _particleCtrl.forward();

    Future.delayed(AppDurations.celebration, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: AppColors.bgHero,
      child: Stack(
        children: [
          // Radial glow center
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandYellow.withValues(alpha: _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti particles
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ConfettiPainter(_particleCtrl.value),
            ),
          ),

          // Center content
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative line
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _starDeco(),
                      Container(width: 60, height: 1, color: AppColors.brandYellow.withValues(alpha: 0.3)),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 1, color: AppColors.brandYellow.withValues(alpha: 0.3)),
                      _starDeco(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // MISSION CLEAR!
                  Text(
                    'MISSION\nCLEAR!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.blackHanSans(
                      fontSize: 44,
                      height: 1.0,
                      color: AppColors.brandYellow,
                      shadows: [
                        Shadow(blurRadius: 30, color: AppColors.brandYellow.withValues(alpha: 0.8)),
                        Shadow(blurRadius: 60, color: AppColors.brandYellow.withValues(alpha: 0.4)),
                      ],
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trophy icon with glow
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandYellow.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.brandYellow.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 40,
                            color: AppColors.brandYellow.withValues(alpha: _glowAnim.value + 0.1),
                          ),
                          BoxShadow(
                            blurRadius: 80,
                            color: AppColors.brandYellow.withValues(alpha: _glowAnim.value * 0.5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 72,
                        color: AppColors.brandYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Decorative line bottom
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _starDeco(),
                      Container(width: 60, height: 1, color: AppColors.brandYellow.withValues(alpha: 0.3)),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 1, color: AppColors.brandYellow.withValues(alpha: 0.3)),
                      _starDeco(),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Tap to continue
                  _PulsingText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starDeco() => Text(
    '✦',
    style: TextStyle(
      color: AppColors.brandYellow.withValues(alpha: 0.6),
      fontSize: 12,
      decoration: TextDecoration.none,
    ),
  );
}

class _PulsingText extends StatefulWidget {
  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + _ctrl.value * 0.6,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '탭해서 결과 보기',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Confetti painter with RunClue brand colors
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);
  static final List<_Particle> _particles = List.generate(80, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.15,
      speed: 0.7 + _rng.nextDouble() * 0.6,
      wobbleAmp: 15 + _rng.nextDouble() * 25,
      wobbleFreq: 2 + _rng.nextDouble() * 4,
      size: 4 + _rng.nextDouble() * 6,
      rotation: _rng.nextDouble() * 6.28,
      rotSpeed: (_rng.nextDouble() - 0.5) * 8,
      colorIndex: _rng.nextInt(3),
    );
  });

  static const _colors = [
    Color(0xFFFACC15), // Yellow
    Color(0xFFFFFFFF), // White
    Color(0xFF38BDF8), // Blue
  ];

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p.startY + p.speed * progress) * size.height;
      if (y > size.height + 20 || y < -30) continue;

      final x = p.x * size.width +
          sin(progress * p.wobbleFreq * 3.14) * p.wobbleAmp;
      final alpha = (1.0 - progress * 0.6).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = _colors[p.colorIndex].withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotSpeed);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _Particle {
  final double x, startY, speed, wobbleAmp, wobbleFreq;
  final double size, rotation, rotSpeed;
  final int colorIndex;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.colorIndex,
  });
}
