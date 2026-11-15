import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// The official حلقة brand logo: ring of 30 dots with one gold dot at the top
/// around an open Mushaf, matching assets/branding/app_icon.png (Principle VI).
class HalaqaLogo extends StatelessWidget {
  const HalaqaLogo({
    super.key,
    this.size = 48,
    this.color,
    this.goldColor,
    this.isDark,
  });

  /// Standard sizes: 48 for headers/dialogs, 96 for splash/auth.
  static const double small = 48;
  static const double large = 96;

  final double size;
  final Color? color;
  final Color? goldColor;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final themeColors = Theme.of(context).extension<AppColors>();
    final defaultColors = dark ? AppColors.dark : AppColors.light;
    final resolvedColor = color ??
        (isDark != null
            ? defaultColors.primary
            : (themeColors?.primary ?? defaultColors.primary));
    final resolvedGold = goldColor ??
        (isDark != null
            ? defaultColors.accent
            : (themeColors?.accent ?? defaultColors.accent));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HalaqaLogoPainter(
          color: resolvedColor,
          goldColor: resolvedGold,
        ),
      ),
    );
  }
}

class HalaqaLogoPainter extends CustomPainter {
  const HalaqaLogoPainter({
    required this.color,
    required this.goldColor,
  });

  final Color color;
  final Color goldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.40;
    final dotRadius = math.max(1.5, size.width * 0.026);

    // 1. Ring of 30 dots (one gold dot at top / -90 degrees)
    for (var i = 0; i < 30; i++) {
      final angle = 2 * math.pi * i / 30 - math.pi / 2;
      final dx = cx + radius * math.cos(angle);
      final dy = cy + radius * math.sin(angle);
      final isTopGold = (i == 0);
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isTopGold ? goldColor : color;
      final currentDotR = isTopGold ? dotRadius * 1.25 : dotRadius;
      canvas.drawCircle(Offset(dx, dy), currentDotR, dotPaint);
    }

    // 2. Open book & rihal (book stand)
    final bookPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final leftPage = Path()
      ..moveTo(cx, cy - size.height * 0.035)
      ..cubicTo(
        cx - size.width * 0.08,
        cy - size.height * 0.12,
        cx - size.width * 0.16,
        cy - size.height * 0.12,
        cx - size.width * 0.20,
        cy - size.height * 0.08,
      )
      ..lineTo(cx - size.width * 0.20, cy + size.height * 0.08)
      ..cubicTo(
        cx - size.width * 0.16,
        cy + size.height * 0.05,
        cx - size.width * 0.08,
        cy + size.height * 0.05,
        cx,
        cy + size.height * 0.09,
      )
      ..close();

    final rightPage = Path()
      ..moveTo(cx, cy - size.height * 0.035)
      ..cubicTo(
        cx + size.width * 0.08,
        cy - size.height * 0.12,
        cx + size.width * 0.16,
        cy - size.height * 0.12,
        cx + size.width * 0.20,
        cy - size.height * 0.08,
      )
      ..lineTo(cx + size.width * 0.20, cy + size.height * 0.08)
      ..cubicTo(
        cx + size.width * 0.16,
        cy + size.height * 0.05,
        cx + size.width * 0.08,
        cy + size.height * 0.05,
        cx,
        cy + size.height * 0.09,
      )
      ..close();

    final rightPagePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.85);

    // Stand (Rihal)
    final stand = Path()
      ..moveTo(cx - size.width * 0.11, cy + size.height * 0.17)
      ..lineTo(cx, cy + size.height * 0.09)
      ..lineTo(cx + size.width * 0.11, cy + size.height * 0.17)
      ..lineTo(cx + size.width * 0.07, cy + size.height * 0.17)
      ..lineTo(cx, cy + size.height * 0.12)
      ..lineTo(cx - size.width * 0.07, cy + size.height * 0.17)
      ..close();

    canvas.drawPath(stand, bookPaint);
    canvas.drawPath(leftPage, bookPaint);
    canvas.drawPath(rightPage, rightPagePaint);

    // Spine hairline
    final spinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.015)
      ..color = color;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.035),
      Offset(cx, cy + size.height * 0.09),
      spinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant HalaqaLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.goldColor != goldColor;
}
