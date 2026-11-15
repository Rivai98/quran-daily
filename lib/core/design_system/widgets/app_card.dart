import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';

/// Flat card: surface + 1px border, radius lg, no shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding = AppSpacing.card,
    this.highlighted = false,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;

  /// When true the border uses the primary color (e.g. the member's own juz).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBR,
          side: BorderSide(
            color: highlighted ? colors.primary : colors.border,
            width: highlighted ? 1.5 : 1,
          ),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
