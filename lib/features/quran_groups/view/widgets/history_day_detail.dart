import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';

AssignmentStatus _toDesignStatus(AssignmentStatusEnum s) =>
    AssignmentStatus.values.byName(s.name);

/// Detail sheet/panel for a specific historical day (S10).
class HistoryDayDetail extends StatelessWidget {
  const HistoryDayDetail({
    super.key,
    required this.day,
    this.onClose,
  });

  final HistoryDaySummary day;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final totalCompleted = day.completedCount + day.lateCount;

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ArabicNumerals.format(day.groupDate),
                style: AppTypography.headline,
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: ArabicStrings.closeDetailAction,
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressHeader(
            completed: totalCompleted,
            total: 30,
            variant: ProgressVariant.bar,
          ),
          const SizedBox(height: AppSpacing.md),
          if (day.myResult != null) ...[
            const AppSectionHeader(title: ArabicStrings.myResultSectionTitle),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              padding: AppSpacing.card,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ArabicStrings.juzName(day.myResult!.juz),
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'مقعد ${ArabicNumerals.format(day.myResult!.seatNumber)}',
                        style: AppTypography.caption.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StatusChip(status: _toDesignStatus(day.myResult!.status)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (day.perJuz != null) ...[
            const AppSectionHeader(title: ArabicStrings.allMembersDetailTitle),
            const SizedBox(height: AppSpacing.xs),
            for (final assignment in day.perJuz!) ...[
              Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.smBR,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicStrings.juzName(assignment.juz),
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${assignment.readerDisplayName ?? ArabicStrings.unassignedSeat} · مقعد ${ArabicNumerals.format(assignment.seatNumber)}',
                          style: AppTypography.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    StatusChip(status: _toDesignStatus(assignment.status)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
