import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/hit_settings.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    this.name,
    this.subtitle,
    this.initials,
    this.onSettingsTap,
  });

  final String? name;
  final String? subtitle;

  final String? initials;

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final cleanName = name?.trim() ?? '';
    final who = cleanName.isEmpty ? '' : ', $cleanName';

    final letter = initials ??
        (cleanName.isEmpty
            ? null
            : cleanName.substring(0, 1).toUpperCase());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:       BoxDecoration(
              gradient: AppTheme.limeMint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lime.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: letter == null
                  ?       Icon(
                      Icons.person_rounded,
                      size: 24,
                      color: AppTheme.ink,
                    )
                  : Text(
                      letter,
                      style:       TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$salutation$who 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          _HeaderBubble(
            icon: Icons.settings_rounded,
            showDot: false,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderBubble extends StatelessWidget {
  const _HeaderBubble({
    required this.icon,
    this.showDot = false,
    this.onTap,
  });

  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.hairlineDark),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, size: 20, color: AppTheme.textMuted),
              ),
              if (showDot)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.coral,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceAlt,
                        width: 1.5,
                      ),
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

class ChallengeBanner extends StatelessWidget {
  const ChallengeBanner({
    super.key,
    this.eyebrow = 'NEW CHALLENGE',
    this.title = '2 Weeks of Energy',
    this.subtitle,
    this.cta = 'START',
    this.progress,
    this.onTap,
  });

  final String eyebrow;
  final String title;

  final String? subtitle;

  final String cta;

  final double? progress;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = progress?.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.limeMint,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lime.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: onTap == null
              ? null
              : () {
                  HitHaptics.mediumImpact();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child:       Icon(
                    Icons.emoji_events_rounded,
                    size: 22,
                    color: AppTheme.lime,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppTheme.ink.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:       TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.ink,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink.withValues(alpha: 0.74),
                          ),
                        ),
                      ],
                      if (clamped != null) ...[
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            width: double.infinity,
                            height: 5,
                            child: Container(
                              color: AppTheme.ink.withValues(alpha: 0.22),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor:
                                    clamped == 0 ? 0.02 : clamped,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.ink.withValues(alpha: 0.82),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    cta,
                    style:       TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.lime,
                    ),
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

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.weekStart,
    this.today,
    this.markedDays = const <int>{},
    this.selectedDay,
    this.onDayTap,
  });

  final DateTime weekStart;

  final DateTime? today;

  final Set<int> markedDays;

  final int? selectedDay;

  final ValueChanged<int>? onDayTap;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _dayChip(context, i, now),
            ),
          ),
      ],
    );
  }

  Widget _dayChip(BuildContext context, int i, DateTime now) {
    final date = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isSelected = selectedDay != null
        ? selectedDay == i
        : (isToday &&
            !now.isBefore(date) &&
            now.isBefore(date.add(const Duration(days: 1))));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDayTap == null
          ? null
          : () {
              HitHaptics.selectionClick();
              onDayTap!(i);
            },
      child: Column(
        children: [
          Text(
            _letters[i],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: isToday ? AppTheme.lime : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppTheme.space2XS + 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lime : AppTheme.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.limeSoft
                    : AppTheme.hairlineDark,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.lime.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppTheme.ink
                      : (isToday ? AppTheme.lime : AppTheme.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space2XS + 2),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: markedDays.contains(i)
                  ? AppTheme.lime
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class HitChip extends StatelessWidget {
  const HitChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap == null
            ? null
            : () {
                HitHaptics.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 38,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.lime : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : AppTheme.hairlineDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? AppTheme.ink : AppTheme.textMuted,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: selected ? AppTheme.ink : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;

  final String value;
  final String label;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppTheme.lime;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL - 4),
        border: Border.all(color: AppTheme.hairlineDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class SegmentSwitch extends StatelessWidget {
  const SegmentSwitch({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.track,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.hairlineDark),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    HitHaptics.selectionClick();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 38,
                    decoration: BoxDecoration(
                      color: i == index ? AppTheme.lime : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        options[i].toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: i == index
                              ? AppTheme.ink
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GradientBar extends StatelessWidget {
  const GradientBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.gradient,
    this.colors,
    this.trackColor,
  });

  final double progress;

  final Gradient? gradient;
  final List<Color>? colors;
  final double height;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final fill = gradient ?? LinearGradient(colors: colors ?? AppTheme.heroGradient.colors);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          color: trackColor ?? AppTheme.track,
          child: clamped <= 0
              ? null
              : FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clamped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: fill),
                  ),
                ),
        ),
      ),
    );
  }
}

class GlowRing extends StatelessWidget {
  const GlowRing({
    super.key,
    required this.progress,
    this.size = 170,
    this.strokeWidth = 11,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlowRingPainter(
          progress.clamp(0.0, 1.0),
          strokeWidth,
          AppTheme.heroGradient.colors,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  _GlowRingPainter(this.progress, this.strokeWidth, this.colors);

  final double progress;
  final double strokeWidth;

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    const start = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.track;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    if (progress <= 0) return;

    final sweep = math.pi * 2 * progress;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 5
      ..strokeCap = StrokeCap.round
      ..color = colors.first.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawArc(arcRect, start, sweep, false, glow);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors:       AppTheme.heroGradient.colors,
      ).createShader(rect);

    canvas.drawArc(arcRect, start, sweep, false, arc);
  }

  bool _sameColors(List<Color> other) {
    if (other.length != colors.length) return false;
    for (var i = 0; i < colors.length; i++) {
      if (other[i] != colors[i]) return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      !_sameColors(old.colors);
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spaceXL,
        bottom: AppTheme.spaceMD,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.hairlineDark,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spaceSM),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;

  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
        AppTheme.space2XS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppTheme.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class HitNavItem {
  const HitNavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class HitBottomNav extends StatelessWidget {
  const HitBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.centerIndex,
  });

  final List<HitNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int? centerIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        6,
        AppTheme.spaceMD,
        AppTheme.spaceMD,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: AppTheme.canvasDeep.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              if (centerIndex == i)
                _CenterFab(
                  item: items[i],
                  onTap: () {
                    HitHaptics.mediumImpact();
                    onChanged(i);
                  },
                )
              else
                Expanded(
                  child: _NavTab(
                    item: items[i],
                    active: selectedIndex == i,
                    onTap: () {
                      HitHaptics.selectionClick();
                      onChanged(i);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final HitNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.lime : AppTheme.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppTheme.lime : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.item, required this.onTap});

  final HitNavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.lime,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.lime.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(item.icon, size: 26, color: AppTheme.ink),
          ),
        ),
      ),
    );
  }
}
