import 'package:material_ui/material_ui.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';

class PortionDetailSheet extends StatelessWidget {
  const PortionDetailSheet({
    super.key,
    required this.assignment,
    required this.unit,
    required this.groupId,
    this.metadataRepository,
    this.onOpenProfile,
    this.onVolunteer,
    this.onOverride,
  });

  final Assignment assignment;
  final PortionUnit unit;
  final String groupId;
  final QuranMetadataRepository? metadataRepository;
  final ValueChanged<String>? onOpenProfile;
  final VoidCallback? onVolunteer;
  final VoidCallback? onOverride;

  static Future<void> show(
    BuildContext context, {
    required Assignment assignment,
    required PortionUnit unit,
    required String groupId,
    QuranMetadataRepository? metadataRepository,
    ValueChanged<String>? onOpenProfile,
    VoidCallback? onVolunteer,
    VoidCallback? onOverride,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: PortionDetailSheet(
        assignment: assignment,
        unit: unit,
        groupId: groupId,
        metadataRepository: metadataRepository,
        onOpenProfile:
            onOpenProfile ??
            (userId) {
              Navigator.of(sheetContext).pop();
              Navigator.pushNamed(
                context,
                AppRoutes.memberProfile,
                arguments: {'userId': userId, 'groupId': groupId},
              );
            },
        onVolunteer: onVolunteer == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onVolunteer();
              },
        onOverride: onOverride == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onOverride();
              },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final designStatus = AssignmentStatus.values.byName(assignment.status.name);

    String? readingRange;
    if (metadataRepository != null) {
      try {
        final p = metadataRepository!.portion(unit, assignment.portionIndex);
        final startSuraName = metadataRepository!.suraName(p.startSura);
        final endSuraName = metadataRepository!.suraName(p.endSura);
        readingRange = ArabicStrings.portionRange(
          startSuraName,
          p.startAya,
          endSuraName,
          p.endAya,
        );
      } catch (_) {}
    }

    final hasReader =
        assignment.reader != null ||
        (assignment.readerDisplayName != null &&
            assignment.readerDisplayName!.isNotEmpty);

    final readerDisplayName =
        assignment.reader?.displayName ??
        assignment.readerDisplayName ??
        (assignment.status == AssignmentStatusEnum.available
            ? ArabicStrings.available
            : ArabicStrings.unassignedReader);

    final kindText = switch (assignment.kind) {
      AssignmentKind.volunteer => ArabicStrings.kindVolunteer,
      AssignmentKind.override => ArabicStrings.kindOverride,
      AssignmentKind.seat => ArabicStrings.kindSeat,
      AssignmentKind.unassigned => ArabicStrings.unassignedReader,
    };

    String? formattedTime;
    if (assignment.completedAt != null) {
      final time = assignment.completedAt!.toLocal();
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      formattedTime = ArabicNumerals.format('$h:$m');
    }

    final isLate = assignment.status == AssignmentStatusEnum.late;

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ArabicStrings.portionName(unit, assignment.portionIndex),
                      style: AppTypography.headline,
                    ),
                    if (readingRange != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        readingRange,
                        style: AppTypography.caption.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusChip(status: designStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.card,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.mdBR,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                UserAvatar(
                  size: 48,
                  initials: assignment.reader?.initials,
                  displayName: hasReader ? readerDisplayName : null,
                  isVacant: !hasReader,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(readerDisplayName, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.event_seat_rounded,
                            size: 16,
                            color: colors.inkMuted,
                          ),
                          Text(
                            ArabicStrings.historySeat(
                              ArabicNumerals.format(assignment.seatNumber),
                            ),
                            style: AppTypography.caption.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                          Icon(
                            assignment.kind == AssignmentKind.volunteer
                                ? Icons.volunteer_activism_rounded
                                : Icons.menu_book_rounded,
                            size: 16,
                            color: colors.inkMuted,
                          ),
                          Text(
                            kindText,
                            style: AppTypography.caption.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      if (formattedTime != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Icon(
                              isLate
                                  ? Icons.history_rounded
                                  : Icons.schedule_rounded,
                              size: 14,
                              color: colors.inkMuted,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              '${ArabicStrings.completionTime}: $formattedTime (${isLate ? ArabicStrings.tagLate : ArabicStrings.tagOnTime})',
                              style: AppTypography.caption.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (assignment.status == AssignmentStatusEnum.available) ...[
            Text(
              ArabicStrings.portionVacant,
              style: AppTypography.body.copyWith(color: colors.inkMuted),
            ),
            if (onVolunteer != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: ArabicStrings.volunteerForPortion,
                icon: const Icon(Icons.volunteer_activism_rounded),
                variant: AppButtonVariant.primary,
                expanded: true,
                onPressed: onVolunteer,
              ),
            ],
          ],
          if (hasReader &&
              assignment.reader?.userId != null &&
              onOpenProfile != null) ...[
            AppButton(
              label: ArabicStrings.openProfile,
              icon: const Icon(Icons.person_rounded),
              variant: AppButtonVariant.primary,
              expanded: true,
              onPressed: () => onOpenProfile!(assignment.reader!.userId),
            ),
          ],
          if (onOverride != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: ArabicStrings.overrideAssignmentTitle,
              icon: const Icon(Icons.swap_horiz_rounded),
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: onOverride,
            ),
          ],
        ],
      ),
    );
  }
}
