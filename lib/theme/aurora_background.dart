import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/hit_settings.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;

  final bool enabled;

  const AuroraBackground({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  static const int _steps = 360;

  static const double _frozenT = 0.5;

  @override
  void initState() {
    super.initState();
    HitSettings.I.aurora.addListener(_syncController);
    _syncController();
  }

  @override
  void didUpdateWidget(covariant AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  @override
  void dispose() {
    HitSettings.I.aurora.removeListener(_syncController);
    _controller.dispose();
    super.dispose();
  }

  void _syncController() {
    final on = widget.enabled && HitSettings.I.aurora.value;
    if (on && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!on && _controller.isAnimating) {
      _controller.stop();
    }
  }

  double _quantized() => (_controller.value * _steps).floor() / _steps;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HitSettings.I.aurora,
      builder: (context, auroraOn, _) {
        if (!widget.enabled || !auroraOn) return widget.child;

        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return CustomPaint(
            painter: _AmbientPainter(
              t: _frozenT,
              scheme: Theme.of(context).colorScheme,
            ),
            child: RepaintBoundary(child: widget.child),
          );
        }

        return AnimatedBuilder(
          animation: _controller,
          child: RepaintBoundary(child: widget.child),
          builder: (context, child) => CustomPaint(
            painter: _AmbientPainter(
              t: _quantized(),
              scheme: Theme.of(context).colorScheme,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double t;
  final ColorScheme scheme;
  _AmbientPainter({required this.t, required this.scheme});

  double _wave(double x, double phase) =>
      0.5 + 0.5 * math.sin((x + phase) * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Color color, Offset center, double radius) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            color,
            color.withValues(alpha: 0.0),
          ]),
      );
    }

    final w = size.width, h = size.height;
    final dark = scheme.brightness == Brightness.dark;

    final aLime = dark ? 0.10 : 0.05;
    final aMint = dark ? 0.07 : 0.035;
    final aSky = dark ? 0.045 : 0.025;

    glow(
      scheme.primary.withValues(alpha: aLime),
      Offset(
        w * (0.18 + 0.10 * _wave(t, 0)),
        h * (0.09 + 0.05 * _wave(t, .4)),
      ),
      w * 0.62,
    );

    glow(
      scheme.secondary.withValues(alpha: aMint),
      Offset(
        w * (0.86 - 0.08 * _wave(t, .6)),
        h * (0.38 + 0.10 * _wave(t, .2)),
      ),
      w * 0.52,
    );

    glow(
      scheme.tertiary.withValues(alpha: aSky),
      Offset(
        w * (0.32 + 0.12 * _wave(t, .3)),
        h * (0.86 - 0.06 * _wave(t, .8)),
      ),
      w * 0.46,
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.t != t ||
      old.scheme.primary != scheme.primary ||
      old.scheme.secondary != scheme.secondary ||
      old.scheme.tertiary != scheme.tertiary;
}
