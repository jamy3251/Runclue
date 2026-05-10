import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../widgets/common/haptic_button.dart';
import '../../widgets/common/badge_chip.dart';

/// Screen 11 — 런클루만의 이유 (WhyRunClue)
/// 경쟁 우위 설명 + 플라이휠 구조 시각화 + 전환 유도
class WhyRunClueScreen extends StatelessWidget {
  const WhyRunClueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ONLY RUNCLUE badge
            const BadgeChip(label: 'ONLY RUNCLUE', color: AppColors.brandYellow),
            const SizedBox(height: AppSpacing.lg),

            // Impact headline
            Text(
              '뛰면서 버는\n새로운 방법',
              style: GoogleFonts.blackHanSans(
                fontSize: 36,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 3 differentiators
            Row(
              children: const [
                _DiffMetric(value: '₩2.3M', label: '월 최대 수익'),
                _DiffMetric(value: '60×', label: '경쟁사 대비'),
                _DiffMetric(value: '₩0', label: '광고비'),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Flywheel diagram
            Center(child: _FlywheelDiagram()),
            const SizedBox(height: AppSpacing.xxl),

            // Comparison table
            Text(
              '왜 런클루일까?',
              style: AppTextStyles.headingLg.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ComparisonTable(),
            const SizedBox(height: AppSpacing.xxl),

            // CTA
            GradientButton(
              text: '지금 시작하기',
              icon: Icons.arrow_forward,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _DiffMetric extends StatelessWidget {
  final String value;
  final String label;
  const _DiffMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headingLg.copyWith(
              color: AppColors.brandYellow,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Animated triangular flywheel diagram
class _FlywheelDiagram extends StatefulWidget {
  @override
  State<_FlywheelDiagram> createState() => _FlywheelDiagramState();
}

class _FlywheelDiagramState extends State<_FlywheelDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 280,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _FlywheelPainter(_ctrl.value),
          child: Stack(
            children: [
              // Top: Explorer
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: _RoleNode(
                  icon: Icons.explore,
                  label: '탐험가',
                  color: AppColors.brandYellow,
                ),
              ),
              // Bottom-left: Creator
              Positioned(
                bottom: 10,
                left: 10,
                child: _RoleNode(
                  icon: Icons.edit,
                  label: '크리에이터',
                  color: AppColors.brandBlue,
                ),
              ),
              // Bottom-right: Business
              Positioned(
                bottom: 10,
                right: 10,
                child: _RoleNode(
                  icon: Icons.store,
                  label: '사장님',
                  color: AppColors.brandOrange,
                ),
              ),
              // Center label
              Center(
                child: Text(
                  '플라이휠',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RoleNode({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FlywheelPainter extends CustomPainter {
  final double progress;
  _FlywheelPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    // Triangle vertices (top, bottom-left, bottom-right)
    final top = Offset(cx, cy - r);
    final bl = Offset(cx - r * 0.87, cy + r * 0.5);
    final br = Offset(cx + r * 0.87, cy + r * 0.5);

    // Draw triangle edges
    final linePaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(top, br, linePaint);
    canvas.drawLine(br, bl, linePaint);
    canvas.drawLine(bl, top, linePaint);

    // Animated arrow dot on each edge
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final edges = [
      [top, br],
      [br, bl],
      [bl, top],
    ];
    final colors = [
      AppColors.brandYellow,
      AppColors.brandOrange,
      AppColors.brandBlue,
    ];

    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final start = edges[i][0];
      final end = edges[i][1];
      final pos = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      dotPaint.color = colors[i].withValues(alpha: 0.8);
      canvas.drawCircle(pos, 4, dotPaint);
      // glow
      dotPaint.color = colors[i].withValues(alpha: 0.2);
      canvas.drawCircle(pos, 8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlywheelPainter old) =>
      old.progress != progress;
}

class _ComparisonTable extends StatelessWidget {
  static const _rows = [
    ['시간당 수익', '₩300', '₩18,000+'],
    ['오프라인 연계', 'X', 'O'],
    ['상금 투명성', '불명확', '100% 공개'],
    ['크리에이터 수익', '없음', '최대 40%'],
    ['사장님 광고비', '고정', '성과 기반'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            color: AppColors.bgSurface,
            child: Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text('캐쉬워크',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('RUNCLUE',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandYellow,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ],
            ),
          ),
          // Rows
          ...List.generate(_rows.length, (i) {
            final row = _rows[i];
            final isRunClueWin = row[2] != row[1];
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: i.isEven ? AppColors.bgBase : AppColors.bgSurface,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(row[0],
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: _compValue(row[1], isWin: false),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppColors.brandYellow.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _compValue(row[2], isWin: true),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _compValue(String val, {required bool isWin}) {
    if (val == 'X') {
      return const Icon(Icons.cancel, size: 16, color: AppColors.brandRed);
    }
    if (val == 'O') {
      return const Icon(Icons.check_circle, size: 16, color: AppColors.brandGreen);
    }
    return Text(
      val,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption.copyWith(
        color: isWin ? AppColors.brandYellow : AppColors.textMuted,
        fontWeight: isWin ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
