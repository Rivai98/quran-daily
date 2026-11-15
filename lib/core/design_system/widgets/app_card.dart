import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';

/// Flat card: surface + 1px border, radius lg, no shadow (Constitution Principle VI & ui-craft.md).
///
/// Can be made tappable with ripple by providing [onTap].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding = AppSpacing.card,
    this.highlighted = false,
    this.onTap,
    this.color,
    this.borderRadius,
    this.borderSide,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;

  /// When true the border uses the primary color (e.g. the member's own juz).
  final bool highlighted;

  /// Optional tap callback for the whole card with Material ripple (ui-craft.md).
  final VoidCallback? onTap;

  /// Optional color override (defaults to colors.surface).
  final Color? color;

  /// Optional radius override (defaults to AppRadius.lgBR).
  final BorderRadius? borderRadius;

  /// Optional border side override.
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final effectiveRadius = borderRadius ?? AppRadius.lgBR;
    final effectiveColor = color ?? colors.surface;
    final effectiveBorderSide = borderSide ??
        BorderSide(
          color: highlighted ? colors.primary : colors.border,
          width: highlighted ? 1.5 : 1,
        );

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: content,
        ),
      );
    }

    return Container(
      decoration: ShapeDecoration(
        color: effectiveColor,
        shape: RoundedRectangleBorder(
          borderRadius: effectiveRadius,
          side: effectiveBorderSide,
        ),
      ),
      child: content,
    );
  }
}
