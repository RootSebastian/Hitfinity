import 'package:flutter/material.dart';

import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.spaceLG),
    this.color,
    this.gradient,
    this.radius,
    this.borderColor,
    this.glow = false,
  });

  final Widget child;

  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;

  final Color? color;

  final Gradient? gradient;

  final double? radius;

  final Color? borderColor;

  final bool glow;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? AppTheme.radiusXL;

    final edge = borderColor ??
        (dark ? AppTheme.hairlineDark : AppTheme.hairlineLight);

    final card = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (dark ? AppTheme.surface : Colors.white))
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          if (glow)
            BoxShadow(
              color: AppTheme.lime.withValues(alpha: dark ? 0.20 : 0.32),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}
