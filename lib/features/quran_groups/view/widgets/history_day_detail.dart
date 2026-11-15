import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';
import 'portion_detail_sheet.dart';

AssignmentStatus _toDesignStatus(AssignmentStatusEnum s) =>
    AssignmentStatus.values.byName(s.name);

/// Detail sheet/panel for a specific historical day (S10).
class HistoryDayDetail extends StatelessWidget {
  const HistoryDayDetail({
    super.key,
    required this.day,
    this.groupId = '',
    this.metadataRepository,
    this.onClose,
  });

  final HistoryDaySummary day;
  final String groupId;
  final QuranMetadataRepository? metadataRepository;
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
            InkWell(
              onTap: () => PortionDetailSheet.show(
                context,
                assignment: day.myResult!,
                unit: day.portionUnit,
                groupId: groupId,
                metadataRepository: metadataRepository,
              ),
              borderRadius: AppRadius.smBR,
              child: AppCard(
                padding: AppSpacing.card,
                child: Row(
                children: [
                  if (day.myResult!.reader != null) ...[
                    UserAvatar(
                      initials: day.myResult!.reader!.initials,
                      size: 36,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicStrings.portionName(
                            day.portionUnit,
                            day.myResult!.portionIndex,
                          ),
                          style: AppTypography.title,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          ArabicStrings.historySeat(
                            ArabicNumerals.format(day.myResult!.seatNumber),
                          ),
                          style: AppTypography.caption.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusChip(status: _toDesignStatus(day.myResult!.status)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ],
          if ((day.portions ?? day.perJuz) case final portionsList?) ...[
            const AppSectionHeader(title: ArabicStrings.allMembersDetailTitle),
            const SizedBox(height: AppSpacing.xs),
            for (final assignment in portionsList) ...[
              InkWell(
                onTap: () => PortionDetailSheet.show(
                  context,
                  assignment: assignment,
                  unit: day.portionUnit,
                  groupId: groupId,
                  metadataRepository: metadataRepository,
                ),
                borderRadius: AppRadius.smBR,
                child: Container(
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
                      if (assignment.reader != null)
                        UserAvatar(
                          initials: assignment.reader!.initials,
                          size: 36,
                        )
                      else
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surfaceMuted,
                          ),
                          child: Icon(
                            assignment.status == AssignmentStatusEnum.available
                                ? Icons.event_seat
                                : Icons.person_outline,
                            size: 18,
                            color: colors.inkMuted,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ArabicStrings.portionName(
                                day.portionUnit,
                                assignment.portionIndex,
                              ),
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${assignment.readerDisplayName ?? assignment.reader?.displayName ?? (assignment.status == AssignmentStatusEnum.available ? ArabicStrings.unassignedReader : ArabicStrings.unread)} · ${ArabicStrings.historySeat(ArabicNumerals.format(assignment.seatNumber))}',
                              style: AppTypography.caption.copyWith(
                                color: colors.inkMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (assignment.status == AssignmentStatusEnum.completed ||
                                assignment.status == AssignmentStatusEnum.late ||
                                assignment.kind == AssignmentKind.volunteer ||
                                assignment.kind == AssignmentKind.override) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Wrap(
                                spacing: AppSpacing.xxs,
                                children: [
                                  if (assignment.status == AssignmentStatusEnum.completed)
                                    _buildTag(
                                      context,
                                      ArabicStrings.tagOnTime,
                                      colors.completedBg,
                                      colors.completedFg,
                                    ),
                                  if (assignment.status == AssignmentStatusEnum.late)
                                    _buildTag(
                                      context,
                                      ArabicStrings.tagLate,
                                      colors.lateBg,
                                      colors.lateFg,
                                    ),
                                  if (assignment.kind == AssignmentKind.volunteer)
                                    _buildTag(
                                      context,
                                      ArabicStrings.tagVolunteer,
                                      colors.primaryContainer,
                                      colors.primary,
                                    ),
                                  if (assignment.kind == AssignmentKind.override)
                                    _buildTag(
                                      context,
                                      ArabicStrings.tagOverride,
                                      colors.surfaceMuted,
                                      colors.inkMuted,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusChip(status: _toDesignStatus(assignment.status)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smBR,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
