import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';

AssignmentStatus _toDesignStatus(AssignmentStatusEnum s) =>
    AssignmentStatus.values.byName(s.name);

/// Card representing one day in the history list (S10).
class HistoryDayCard extends StatelessWidget {
  const HistoryDayCard({
    super.key,
    required this.day,
    this.onTap,
    this.showFullKhatmaBadge = true,
  });

  final HistoryDaySummary day;
  final VoidCallback? onTap;
  final bool showFullKhatmaBadge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final totalCompleted = day.completedCount + day.lateCount;

    return InkWell(
      borderRadius: AppRadius.lgBR,
      onTap: onTap,
      child: AppCard(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    ArabicNumerals.format(day.groupDate),
                    style: AppTypography.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (day.fullKhatma && showFullKhatmaBadge)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.statusBg(AssignmentStatus.completed),
                      borderRadius: AppRadius.pillBR,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colors.statusFg(AssignmentStatus.completed),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          ArabicStrings.fullKhatmaBadge,
                          style: AppTypography.caption.copyWith(
                            color: colors.statusFg(AssignmentStatus.completed),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ProgressHeader(
              completed: totalCompleted,
              total: 30,
              variant: ProgressVariant.bar,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _CountChip(
                  status: AssignmentStatus.completed,
                  count: day.completedCount,
                ),
                if (day.lateCount > 0)
                  _CountChip(
                    status: AssignmentStatus.late,
                    count: day.lateCount,
                  ),
                if (day.missedCount > 0)
                  _CountChip(
                    status: AssignmentStatus.missed,
                    count: day.missedCount,
                  ),
                if (day.unreadCount > 0)
                  _CountChip(
                    status: AssignmentStatus.unread,
                    count: day.unreadCount,
                  ),
              ],
            ),
            if (day.myResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: AppRadius.smBR,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ArabicStrings.historyMyJuz(
                          ArabicStrings.portionName(
                            day.portionUnit,
                            day.myResult!.portionIndex,
                          ),
                        ),
                        style: AppTypography.caption.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusChip(status: _toDesignStatus(day.myResult!.status)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.status, required this.count});

  final AssignmentStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fg = colors.statusFg(status);
    final bg = colors.statusBg(status);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillBR),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '${status.label}: ${ArabicNumerals.format(count)}',
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
