import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Wraps any widget with tap scale animation + haptic feedback
class HapticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final HapticIntensity haptic;

  const HapticButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.haptic = HapticIntensity.light,
  });

  @override
  State<HapticButton> createState() => _HapticButtonState();
}

enum HapticIntensity { none, light, medium, heavy, success, error }

class _HapticButtonState extends State<HapticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    switch (widget.haptic) {
      case HapticIntensity.none:
        break;
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
      case HapticIntensity.success:
        HapticFeedback.mediumImpact();
      case HapticIntensity.error:
        HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _triggerHaptic();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Gradient CTA button with built-in haptic and scale
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final GradientButtonStyle style;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.style = GradientButtonStyle.yellow,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = switch (style) {
      GradientButtonStyle.yellow => AppGradients.ctaYellow,
      GradientButtonStyle.cyan => AppGradients.ctaCyan,
      GradientButtonStyle.ghost => null,
    };
    final shadow = switch (style) {
      GradientButtonStyle.yellow => AppShadows.ctaYellow,
      GradientButtonStyle.cyan => AppShadows.ctaCyan,
      GradientButtonStyle.ghost => null,
    };
    final textColor = style == GradientButtonStyle.ghost
        ? AppColors.textPrimary
        : Colors.black;

    return HapticButton(
      onTap: isLoading ? null : onTap,
      haptic: HapticIntensity.medium,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: onTap != null ? gradient : null,
          color: onTap == null
              ? const Color(0x14FFFFFF)
              : (gradient == null ? Colors.transparent : null),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: style == GradientButtonStyle.ghost
              ? Border.all(color: const Color(0x26FFFFFF))
              : null,
          boxShadow: shadow != null && onTap != null ? [shadow] : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: textColor),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      text,
                      style: AppTextStyles.button.copyWith(
                        color: onTap == null
                            ? const Color(0x4DFFFFFF)
                            : textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

enum GradientButtonStyle { yellow, cyan, ghost }
