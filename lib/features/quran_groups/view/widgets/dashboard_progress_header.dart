import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_colors.dart';
import 'metric_card.dart';
import '../../../../core/design_system/app_radius.dart';

class DashboardProgressHeader extends StatelessWidget {
  const DashboardProgressHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smBR,
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ArabicStrings.groupFajr,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        ArabicStrings.todayCairoDate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 12 / 30,
                    minHeight: 12,
                    borderRadius: AppRadius.smBR,
                    color: appColors.completedFg,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '12 / 30',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.check_circle,
                    label: ArabicStrings.completedPartsMetric,
                    value: '12',
                    color: appColors.completedFg,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: MetricCard(
                    icon: Icons.percent,
                    label: ArabicStrings.completionRateMetric,
                    value: '40%',
                    color: appColors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: MetricCard(
                    icon: Icons.pending_actions,
                    label: ArabicStrings.remainingPartsMetric,
                    value: '18',
                    color: appColors.pendingFg,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
