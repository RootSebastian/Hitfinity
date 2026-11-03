import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flat surface card with a hairline border.
/// `gradient` (accent wash) is available for primary CTAs.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMD),
    this.margin,
    this.radius,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = radius ?? BorderRadius.circular(AppTheme.radiusLG);

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (isDark
                ? AppTheme.surfaceDark
                : AppTheme.surfaceLight)
            : null,
        borderRadius: r,
        border: gradient == null
            ? Border.all(color: AppTheme.hairline(theme.brightness))
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: r, child: card),
    );
  }
}