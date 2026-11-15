import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Semantic variants for [AppBanner] following constitution Principle VI status pairs.
enum AppBannerVariant {
  error,
  warning,
  info,
  success,
}

/// A calm, consistent banner for notices, errors, and warnings (Constitution Principle VI).
///
/// Banners sit inline to explain state changes or errors with real Arabic reasons
/// and clear next actions (ui-craft.md).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.variant = AppBannerVariant.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  /// Factory constructor for error banners with real Arabic reasons.
  factory AppBanner.error({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppBanner(
      key: key,
      message: message,
      title: title,
      variant: AppBannerVariant.error,
      icon: icon ?? Icons.error_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Factory constructor for warnings (e.g. 2-group limit or offline).
  factory AppBanner.warning({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppBanner(
      key: key,
      message: message,
      title: title,
      variant: AppBannerVariant.warning,
      icon: icon ?? Icons.warning_amber_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Factory constructor for informational notices.
  factory AppBanner.info({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppBanner(
      key: key,
      message: message,
      title: title,
      variant: AppBannerVariant.info,
      icon: icon ?? Icons.info_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Factory constructor for success feedback.
  factory AppBanner.success({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppBanner(
      key: key,
      message: message,
      title: title,
      variant: AppBannerVariant.success,
      icon: icon ?? Icons.check_circle_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  final String message;
  final String? title;
  final AppBannerVariant variant;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final (fg, bg, defaultIcon) = switch (variant) {
      AppBannerVariant.error => (
          colors.danger,
          colors.missedBg,
          Icons.error_outline_rounded,
        ),
      AppBannerVariant.warning => (
          colors.pendingFg,
          colors.pendingBg,
          Icons.warning_amber_rounded,
        ),
      AppBannerVariant.info => (
          colors.infoFg,
          colors.infoBg,
          Icons.info_outline_rounded,
        ),
      AppBannerVariant.success => (
          colors.completedFg,
          colors.completedBg,
          Icons.check_circle_outline_rounded,
        ),
    };

    final effectiveIcon = icon ?? defaultIcon;

    return Semantics(
      container: true,
      liveRegion: variant == AppBannerVariant.error,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: ShapeDecoration(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdBR,
            side: BorderSide(color: fg.withValues(alpha: 0.28)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(effectiveIcon, size: 20, color: fg),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null && title!.isNotEmpty) ...[
                    Text(
                      title!,
                      style: AppTypography.label.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    message,
                    style: AppTypography.caption.copyWith(color: fg),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          actionLabel!,
                          style: AppTypography.label.copyWith(
                            color: fg,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
