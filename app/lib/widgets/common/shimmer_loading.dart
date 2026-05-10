import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Shimmer effect wrapper — wraps any widget with a shimmer animation
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton card placeholder for list loading
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.borderDefault),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 120, height: 14),
            const SizedBox(height: AppSpacing.md),
            _bar(width: double.infinity, height: 12),
            const SizedBox(height: AppSpacing.sm),
            _bar(width: 200, height: 12),
            const Spacer(),
            Row(
              children: [
                _circle(24),
                const SizedBox(width: AppSpacing.sm),
                _bar(width: 80, height: 10),
                const Spacer(),
                _bar(width: 60, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton list — shows N skeleton cards
class SkeletonList extends StatelessWidget {
  final int count;
  final double cardHeight;
  const SkeletonList({super.key, this.count = 3, this.cardHeight = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => SkeletonCard(height: cardHeight)),
    );
  }
}
