import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import 'validation_banner.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';

class AvailableJuzList extends StatefulWidget {
  const AvailableJuzList({
    super.key,
    required this.assignments,
    required this.metadataRepository,
    this.onVolunteer,
    this.volunteeringAssignmentId,
  });

  final List<Assignment> assignments;
  final QuranMetadataRepository metadataRepository;
  final ValueChanged<Assignment>? onVolunteer;
  final String? volunteeringAssignmentId;

  @override
  State<AvailableJuzList> createState() => _AvailableJuzListState();
}

class _AvailableJuzListState extends State<AvailableJuzList> {
  late final Future<void> _metadata = widget.metadataRepository.load();

  @override
  Widget build(BuildContext context) {
    final rows = widget.assignments.where(
      (assignment) =>
          assignment.status == AssignmentStatusEnum.available ||
          (assignment.kind == AssignmentKind.volunteer &&
              assignment.status != AssignmentStatusEnum.unread),
    );
    final sorted = rows.toList()..sort((a, b) => a.juz.compareTo(b.juz));
    if (sorted.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<void>(
      future: _metadata,
      builder: (context, metadataState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ArabicStrings.availableJuzTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          for (final assignment in sorted)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: AppCard(
                padding: AppSpacing.compactCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ArabicStrings.juzOrdinals[assignment.juz - 1],
                      style: AppTypography.label,
                    ),
                    if (metadataState.connectionState == ConnectionState.done &&
                        !metadataState.hasError) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _range(widget.metadataRepository, assignment.juz),
                        style: AppTypography.quranLabel,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    if (assignment.kind == AssignmentKind.volunteer)
                      ValidationBanner(
                        icon: Icons.volunteer_activism,
                        message: ArabicStrings.volunteerTaken,
                        color: colors.primary,
                      )
                    else
                      AppButton(
                        label: ArabicStrings.volunteerForJuz,
                        icon: const Icon(Icons.volunteer_activism),
                        variant: AppButtonVariant.tonal,
                        expanded: true,
                        loading:
                            widget.volunteeringAssignmentId ==
                            assignment.assignmentId,
                        onPressed:
                            widget.onVolunteer == null ||
                                widget.volunteeringAssignmentId != null
                            ? null
                            : () => widget.onVolunteer!(assignment),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _range(QuranMetadataRepository metadataRepository, int juz) {
    final info = metadataRepository.juz(juz);
    final start = metadataRepository.suraName(info.startSura);
    final end = metadataRepository.suraName(info.endSura);
    return '$start ${ArabicNumerals.format(info.startAya)} - '
        '$end ${ArabicNumerals.format(info.endAya)}';
  }
}
