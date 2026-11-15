import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'islamic_ornament.dart';

const supportedAvatarKeys = <String>{'ornament', 'man_kufi', 'woman_hijab'};

class IllustratedAvatar extends StatelessWidget {
  const IllustratedAvatar({
    super.key,
    this.avatarKey = 'ornament',
    this.size = 48,
  });

  final String avatarKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final key = supportedAvatarKeys.contains(avatarKey)
        ? avatarKey
        : 'ornament';
    return Semantics(
      image: true,
      label: key == 'man_kufi'
          ? 'رسم رجل بقلنسوة'
          : key == 'woman_hijab'
          ? 'رسم امرأة بحجاب'
          : 'زخرفة إسلامية',
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _AvatarPainter(colors: colors, avatarKey: key),
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter({required this.colors, required this.avatarKey});
  final AppColors colors;
  final String avatarKey;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawColor(colors.primaryContainer, BlendMode.src);
    if (avatarKey == 'ornament') {
      GirihPainter(
        colors.accent.withValues(alpha: .12),
      ).paint(canvas, Size(100, 100));
      final gold = Paint()..color = colors.accent;
      canvas.drawCircle(
        const Offset(50, 50),
        23,
        gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final star = Path();
      for (var i = 0; i < 16; i++) {
        final radius = i.isEven ? 17.0 : 8.0;
        final angle = -math.pi / 2 + i * math.pi / 8;
        final point = Offset(
          50 + math.cos(angle) * radius,
          50 + math.sin(angle) * radius,
        );
        if (i == 0) {
          star.moveTo(point.dx, point.dy);
        } else {
          star.lineTo(point.dx, point.dy);
        }
      }
      star.close();
      canvas.drawPath(
        star,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }

    final skin = Paint()..color = colors.accent.withValues(alpha: .76);
    final garment = Paint()..color = colors.primary;
    final ink = Paint()..color = colors.onPrimaryContainer;
    final face = Path()
      ..moveTo(35, 42)
      ..quadraticBezierTo(35, 22, 50, 22)
      ..quadraticBezierTo(66, 22, 66, 42)
      ..lineTo(63, 58)
      ..quadraticBezierTo(50, 73, 37, 58)
      ..close();

    if (avatarKey == 'woman_hijab') {
      final hijab = Path()
        ..moveTo(24, 47)
        ..quadraticBezierTo(22, 14, 50, 13)
        ..quadraticBezierTo(79, 14, 77, 48)
        ..lineTo(82, 91)
        ..quadraticBezierTo(50, 101, 18, 91)
        ..close();
      canvas.drawPath(hijab, garment);
      canvas.drawPath(face, skin);
      canvas.drawOval(const Rect.fromLTWH(34, 66, 32, 36), garment);
    } else {
      canvas.drawOval(const Rect.fromLTWH(16, 67, 68, 48), garment);
      canvas.drawPath(face, skin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, 15, 34, 12),
          const Radius.circular(5),
        ),
        garment,
      );
      canvas.drawRect(
        const Rect.fromLTWH(35, 25, 30, 5),
        Paint()..color = colors.accent,
      );
    }
    canvas.drawCircle(const Offset(43, 47), 1.7, ink);
    canvas.drawCircle(const Offset(57, 47), 1.7, ink);
    canvas.drawArc(
      const Rect.fromLTWH(44, 49, 12, 8),
      .2,
      2.7,
      false,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.avatarKey != avatarKey;
}
