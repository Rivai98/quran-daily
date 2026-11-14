import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Stale/offline state banner with the last-synced time. The UI must label
/// clearly when shared data may be stale (constitution Principle I).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message, this.lastSynced});

  final String message;
  final String? lastSynced;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
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
          Icon(Icons.cloud_off, size: 20, color: colors.pendingFg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AppTypography.caption),
                if (lastSynced != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    lastSynced!,
                    style: AppTypography.caption
                        .copyWith(color: colors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
