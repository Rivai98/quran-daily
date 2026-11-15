import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// A quiet, code-drawn rosette ornament for screen headers.
class IslamicOrnamentBand extends StatelessWidget {
  const IslamicOrnamentBand({
    super.key,
    required this.child,
    this.height = 156,
    this.contentPadding = 24,
    this.refined = false,
  });

  final Widget child;
  final double height;
  final double contentPadding;
  final bool refined;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.primaryContainer),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GirihPainter(
                colors.accent.withValues(alpha: 0.06),
                refined: refined,
              ),
            ),
          ),
          Padding(padding: EdgeInsets.all(contentPadding), child: child),
        ],
      ),
    );
  }
}

class GirihPainter extends CustomPainter {
  const GirihPainter(this.color, {this.refined = false});
  final Color color;
  final bool refined;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (refined) {
      paint.strokeWidth = 1.2;
      const spacing = 152.0;
      const outerRadius = 44.0;
      const innerRadius = 18.0;
      final centerY = size.height / 2;
      for (var x = -spacing; x < size.width + spacing; x += spacing) {
        final center = Offset(x + spacing / 2, centerY);
        final outer = List<Offset>.generate(16, (i) {
          final angle = math.pi * i / 8 - math.pi / 2;
          final radius = i.isEven ? outerRadius : innerRadius;
          return center +
              Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        });
        final rosette = Path()..moveTo(outer.first.dx, outer.first.dy);
        for (final point in outer.skip(1)) {
          rosette.lineTo(point.dx, point.dy);
        }
        rosette.close();
        canvas.drawPath(rosette, paint);
        canvas.drawOval(
          Rect.fromCircle(center: center, radius: innerRadius * 1.35),
          paint,
        );
      }
      return;
    }

    const step = 64.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final center = Offset(x + step / 2, y + step / 2);
        final points = List<Offset>.generate(8, (i) {
          final angle = math.pi * i / 4 - math.pi / 2;
          return center + Offset(math.cos(angle) * 22, math.sin(angle) * 22);
        });
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawLine(points[0], points[4], paint);
        canvas.drawLine(points[2], points[6], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GirihPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.refined != refined;
}

/// Hairline divider with a small eight-point star at its center.
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.star, size: 12, color: colors.accent),
        ),
        Expanded(child: Divider(color: colors.border, height: 1)),
      ],
    );
  }
}
