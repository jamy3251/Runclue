import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../providers/clue_provider.dart';
import '../../providers/participation_provider.dart';
import '../../widgets/common/error_widget.dart' as app;
import '../../widgets/common/loading_widget.dart';

/// Screen 09 · 미션 결과 — 명세 v2.0 §4.9
class ClueResultScreen extends ConsumerStatefulWidget {
  final String clueId;

  const ClueResultScreen({super.key, required this.clueId});

  @override
  ConsumerState<ClueResultScreen> createState() => _ClueResultScreenState();
}

class _ClueResultScreenState extends ConsumerState<ClueResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..forward();
  late final AnimationController _heroCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  bool _detailOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100),
          () => HapticFeedback.heavyImpact());
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participationAsync =
        ref.watch(currentParticipationProvider(widget.clueId));
    final clueAsync = ref.watch(clueDetailProvider(widget.clueId));

    return Scaffold(
      backgroundColor: AppColors.bgHero,
      body: participationAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => app.AppErrorWidget(
          message: '결과를 불러올 수 없습니다',
          onRetry: () =>
              ref.invalidate(currentParticipationProvider(widget.clueId)),
        ),
        data: (participation) {
          final clue = clueAsync.valueOrNull;
          final reward = participation?['total_points_earned'] ?? 0;
          final rank = participation?['rank'];
          return Stack(
            children: [
              // 컨페티 + radial glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(progress: _confettiCtrl.value),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brandYellow.withValues(alpha: 0.18),
                          AppColors.brandYellow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 메인 콘텐츠
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _detailOpen = true),
                        behavior: HitTestBehavior.opaque,
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _heroCtrl,
                            curve: Curves.elasticOut,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 장식선
                              Text(
                                '✦  ─────  ✦',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  color: AppColors.brandYellow.withValues(
                                      alpha: 0.5),
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MISSION CLEAR!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.blackHanSans(
                                  fontSize: 44,
                                  color: AppColors.brandYellow,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.brandYellow
                                          .withValues(alpha: 0.8),
                                      blurRadius: 30,
                                    ),
                                    Shadow(
                                      color: AppColors.brandYellow
                                          .withValues(alpha: 0.4),
                                      blurRadius: 60,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '✦  ─────  ✦',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  color: AppColors.brandYellow.withValues(
                                      alpha: 0.5),
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // 트로피
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandYellow
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.brandYellow
                                        .withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandYellow
                                          .withValues(alpha: 0.3),
                                      blurRadius: 40,
                                    ),
                                    BoxShadow(
                                      color: AppColors.brandYellow
                                          .withValues(alpha: 0.15),
                                      blurRadius: 80,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.emoji_events,
                                  size: 72,
                                  color: AppColors.brandYellow,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 미션 제목
                              Text(
                                clue?['title'] ?? '미션 완료',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 보상
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.brandGreen
                                        .withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.payments,
                                        color: AppColors.brandGreen, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₩$reward 적립 완료',
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 18,
                                        color: AppColors.brandGreen,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (rank != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '🏆 $rank위',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 하단 안내 — 탭해서 결과 보기
                    if (!_detailOpen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: GestureDetector(
                          onTap: () => setState(() => _detailOpen = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '탭해서 결과 보기',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const _BlinkArrow(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 결과 상세 패널 (slide-up)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: _detailOpen ? 0 : -600,
                child: _DetailPanel(
                  clue: clue,
                  participation: participation,
                  onClose: () => setState(() => _detailOpen = false),
                  onShare: () {
                    final title = clue?['title'] ?? 'RunClue';
                    Share.share('[$title] 클루를 완료했어요! #RunClue');
                  },
                  onNext: () => context.go('/explore'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 결과 상세 패널
// ─────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic>? clue;
  final Map<String, dynamic>? participation;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final VoidCallback onNext;

  const _DetailPanel({
    required this.clue,
    required this.participation,
    required this.onClose,
    required this.onShare,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final reward = participation?['total_points_earned'] ?? 0;
    final rank = participation?['rank'];
    final completedAt = participation?['completed_at'];
    final startedAt =
        participation?['started_at'] ?? participation?['created_at'];

    String elapsed = '--:--';
    if (completedAt != null && startedAt != null) {
      try {
        final s = DateTime.parse(startedAt);
        final e = DateTime.parse(completedAt);
        final diff = e.difference(s);
        elapsed = '${diff.inMinutes}분 ${diff.inSeconds % 60}초';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [AppShadows.modal],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // drag handle
            Center(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            Text(
              '결과 상세',
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),

            _DetailRow(label: '최종 순위', value: rank != null ? '🏆 $rank위' : '—'),
            _DetailRow(label: '획득 금액', value: '₩$reward'),
            _DetailRow(label: '완료 시간', value: elapsed),

            const SizedBox(height: 20),

            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('공유'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('다음 미션'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 깜빡이는 화살표
// ─────────────────────────────────────────────────────────────

class _BlinkArrow extends StatefulWidget {
  const _BlinkArrow();

  @override
  State<_BlinkArrow> createState() => _BlinkArrowState();
}

class _BlinkArrowState extends State<_BlinkArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(_ctrl.value * 6, 0),
        child: const Icon(Icons.arrow_forward,
            size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 컨페티 페인터
// ─────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _rng = Random(42);

  _ConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFFFACC15),
    Color(0xFFFFFFFF),
    Color(0xFF38BDF8),
    Color(0xFF10B981),
    Color(0xFFEF4444),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 32; i++) {
      final x = _rng.nextDouble() * size.width;
      final yStart = -20.0 - _rng.nextDouble() * 100;
      final fall = size.height + 100;
      final y = yStart + fall * progress;
      if (y < 0 || y > size.height) continue;

      final color = _colors[i % _colors.length];
      paint.color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      final w = 6.0 + _rng.nextDouble() * 4;
      final h = 8.0 + _rng.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * pi * 2 + i.toDouble());
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
