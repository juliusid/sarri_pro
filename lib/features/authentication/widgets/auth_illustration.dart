// lib/features/authentication/widgets/auth_illustration.dart
//
// Small animated motif for the auth screens now that they're just a
// button or two — fills the space above the title instead of leaving it
// blank. Two variants: a dotted route with a traveling marker (login —
// "continuing a journey") and a dotted radar with an outward ping
// (signup — "starting fresh").

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';

enum AuthIllustrationVariant { route, radar }

class AuthIllustration extends StatefulWidget {
  final AuthIllustrationVariant variant;
  final double height;

  const AuthIllustration({
    super.key,
    required this.variant,
    this.height = 190,
  });

  @override
  State<AuthIllustration> createState() => _AuthIllustrationState();
}

class _AuthIllustrationState extends State<AuthIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft glow blob, gently breathing.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = 0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi);
              return Positioned(
                top: -30,
                right: widget.variant == AuthIllustrationVariant.route ? -20 : null,
                left: widget.variant == AuthIllustrationVariant.radar ? -10 : null,
                child: Opacity(
                  opacity: (dark ? 0.14 : 0.08) + pulse * (dark ? 0.06 : 0.04),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          // A few floating square accents for texture.
          Positioned(left: 6, top: 30, child: _accentSquare(dark, 22)),
          Positioned(left: 44, top: 4, child: _accentSquare(dark, 14)),
          Positioned(
            right: widget.variant == AuthIllustrationVariant.route ? 30 : 20,
            bottom: 24,
            child: _accentSquare(dark, 18),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: widget.variant == AuthIllustrationVariant.route
                    ? _RoutePainter(dark: dark, t: _controller.value)
                    : _RadarPainter(dark: dark, t: _controller.value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _accentSquare(bool dark, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.lightGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
    );
  }
}

// ── Login: a dotted route with a marker traveling toward the pin ───────────
class _RoutePainter extends CustomPainter {
  final bool dark;
  final double t; // 0..1, looping
  _RoutePainter({required this.dark, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.10, size.height * 0.88);
    final mid = Offset(size.width * 0.42, size.height * 0.70);
    final end = Offset(size.width * 0.62, size.height * 0.30);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, size.height * 0.95, mid.dx, mid.dy)
      ..quadraticBezierTo(mid.dx + 20, mid.dy - 30, end.dx, end.dy);

    // Dashes flow toward the destination.
    _drawDashedPath(
      canvas,
      path,
      Paint()
        ..color = TColors.primary.withOpacity(dark ? 0.8 : 0.7)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      phase: t * 22,
    );

    // Start dot (small, muted)
    canvas.drawCircle(
      start,
      6,
      Paint()..color = TColors.primary.withOpacity(0.5),
    );

    // Traveling marker, looping along the route.
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final tangent = metric.getTangentForOffset(metric.length * t);
      final pos = tangent?.position;
      if (pos != null) {
        canvas.drawCircle(pos, 9, Paint()..color = TColors.primary.withOpacity(0.16));
        canvas.drawCircle(pos, 4, Paint()..color = TColors.primary.withOpacity(0.9));
      }
    }

    // Destination marker: breathing ring + solid dot.
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      end,
      12 + breathe * 4,
      Paint()..color = TColors.primary.withOpacity(0.16 - breathe * 0.06),
    );
    canvas.drawCircle(end, 7, Paint()..color = TColors.primary);
    canvas.drawCircle(
      end,
      7,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.dark != dark;
}

// ── Signup: a dotted radar ring with an outward ping ────────────────────────
class _RadarPainter extends CustomPainter {
  final bool dark;
  final double t; // 0..1, looping
  _RadarPainter({required this.dark, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.78, size.height * 0.42);
    const radius = 46.0;

    // Slowly rotating dashed ring.
    final dashPaint = Paint()
      ..color = TColors.primary.withOpacity(dark ? 0.8 : 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedCircle(canvas, center, radius, dashPaint, rotationDegrees: t * 360);

    // Crosshair ticks
    final tickPaint = Paint()
      ..color = (dark ? TColors.lightGrey : TColors.darkGrey).withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 14);
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 6);
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Two staggered outward pings.
    for (final phase in [t, (t + 0.5) % 1.0]) {
      final pingRadius = radius * 0.4 + phase * radius * 0.9;
      final fade = (1 - phase).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        pingRadius,
        Paint()
          ..color = TColors.primary.withOpacity(0.35 * fade)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }

    // Center pulse
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(center, 14 + breathe * 3, Paint()..color = TColors.primary.withOpacity(0.15));
    canvas.drawCircle(center, 7, Paint()..color = TColors.primary);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.dark != dark;
}

void _drawDashedPath(Canvas canvas, Path path, Paint paint, {double phase = 0}) {
  const dashWidth = 6.0;
  const dashGap = 5.0;
  const cycle = dashWidth + dashGap;
  final offset = phase % cycle;

  for (final metric in path.computeMetrics()) {
    double distance = -offset;
    while (distance < metric.length) {
      final segStart = distance.clamp(0.0, metric.length);
      final segEnd = (distance + dashWidth).clamp(0.0, metric.length);
      if (segEnd > segStart) {
        canvas.drawPath(metric.extractPath(segStart, segEnd), paint);
      }
      distance += cycle;
    }
  }
}

void _drawDashedCircle(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint, {
  double rotationDegrees = 0,
}) {
  const dashDegrees = 10.0;
  const gapDegrees = 8.0;
  final startOffset = rotationDegrees % 360;
  double angle = 0;
  while (angle < 360) {
    final start = (angle + startOffset) * math.pi / 180;
    final sweep = dashDegrees * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
    angle += dashDegrees + gapDegrees;
  }
}
