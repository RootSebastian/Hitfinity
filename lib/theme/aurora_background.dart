import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ultra-subtle ambient light: one warm glow drifting slowly.
/// Barely there — depth without decoration.
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
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _AmbientPainter(
          t: _controller.value,
          scheme: Theme.of(context).colorScheme,
        ),
        child: widget.child,
      ),
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
            color.withOpacity(0.0),
          ]),
      );
    }

    final w = size.width, h = size.height;
    // One warm accent glow, very low opacity, drifting
    glow(
      scheme.primary.withOpacity(0.07),
      Offset(
        w * (0.20 + 0.08 * _wave(t, 0)),
        h * (0.10 + 0.06 * _wave(t, .4)),
      ),
      w * 0.55,
    );
    // One cool neutral glow opposite
    glow(
      (scheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
          .withOpacity(0.04),
      Offset(
        w * (0.85 - 0.06 * _wave(t, .6)),
        h * (0.45 + 0.10 * _wave(t, .2)),
      ),
      w * 0.5,
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => true;
}