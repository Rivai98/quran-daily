import 'package:flutter/material.dart';

import '../../localization/arabic_strings.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Stale/offline state banner with the last-synced time. The UI must label
/// clearly when shared data may be stale (constitution Principle I & ui-craft.md).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.message,
    this.lastSynced,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.cloud_off,
  });

  final String message;
  final String? lastSynced;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: ShapeDecoration(
          color: colors.pendingBg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdBR,
            side: BorderSide(color: colors.pendingFg.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 20,
                color: colors.pendingFg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTypography.caption.copyWith(
                      color: colors.pendingFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastSynced != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      lastSynced!,
                      style: AppTypography.caption.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: colors.pendingFg,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  minimumSize: const Size(48, 36),
                ),
                child: Text(
                  retryLabel ?? ArabicStrings.retry,
                  style: AppTypography.label.copyWith(color: colors.pendingFg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
