import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

/// Semantic variants for [AppBadge] matching constitution Principle VI tokens.
enum AppBadgeVariant {
  primary,
  tonal,
  surface,
  neutral,
  info,
  warning,
  error,
  success,
}

/// Sizing for [AppBadge].
enum AppBadgeSize {
  small,
  regular,
}

/// A compact, accessible status/role/count badge (Constitution Principle VI & ui-craft.md).
///
/// Badges sit next to titles or in metadata lines to convey roles (مشرف, مالك),
/// counts, or categorical status. They are never full-width pills that look like buttons.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.neutral,
    this.size = AppBadgeSize.small,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.semanticLabel,
  });

  /// Factory constructor for role badges (e.g. مشرف, مالك, عضو).
  const factory AppBadge.role({
    Key? key,
    required String label,
    IconData? icon,
    bool isOwner,
  }) = _AppRoleBadge;

  /// Factory constructor for count/metric badges.
  const factory AppBadge.count({
    Key? key,
    required String label,
    AppBadgeVariant variant,
  }) = _AppCountBadge;

  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final (defaultFg, defaultBg) = switch (variant) {
      AppBadgeVariant.primary => (colors.primary, colors.primaryContainer),
      AppBadgeVariant.tonal => (colors.onPrimaryContainer, colors.primaryContainer),
      AppBadgeVariant.surface => (colors.ink, colors.surface),
      AppBadgeVariant.neutral => (colors.inkMuted, colors.surfaceMuted),
      AppBadgeVariant.info => (colors.infoFg, colors.infoBg),
      AppBadgeVariant.warning => (colors.pendingFg, colors.pendingBg),
      AppBadgeVariant.error => (colors.danger, colors.missedBg),
      AppBadgeVariant.success => (colors.completedFg, colors.completedBg),
    };

    final fg = foregroundColor ?? defaultFg;
    final bg = backgroundColor ?? defaultBg;
    final border = borderColor ?? fg.withValues(alpha: 0.28);

    final isSmall = size == AppBadgeSize.small;
    final textStyle = isSmall
        ? AppTypography.caption.copyWith(color: fg, height: 1.2)
        : AppTypography.label.copyWith(color: fg, height: 1.2);
    final iconSize = isSmall ? 14.0 : 16.0;
    final padding = isSmall
        ? const EdgeInsetsDirectional.only(
            start: 6,
            end: 8,
            top: 2,
            bottom: 2,
          )
        : const EdgeInsetsDirectional.only(
            start: 8,
            end: 12,
            top: 4,
            bottom: 4,
          );

    return Semantics(
      label: semanticLabel ?? label,
      container: true,
      child: Container(
        decoration: ShapeDecoration(
          color: bg,
          shape: StadiumBorder(
            side: BorderSide(color: border, width: 1),
          ),
        ),
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppRoleBadge extends AppBadge {
  const _AppRoleBadge({
    super.key,
    required super.label,
    IconData? icon,
    bool isOwner = false,
  }) : super(
          icon: icon ?? (isOwner ? Icons.stars_rounded : Icons.shield_outlined),
          variant: isOwner ? AppBadgeVariant.primary : AppBadgeVariant.tonal,
          size: AppBadgeSize.small,
        );
}

class _AppCountBadge extends AppBadge {
  const _AppCountBadge({
    super.key,
    required super.label,
    super.variant = AppBadgeVariant.neutral,
  }) : super(
          size: AppBadgeSize.small,
        );
}
