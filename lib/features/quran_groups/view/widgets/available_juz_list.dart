import 'package:flutter/material.dart';

import '../../../../core/design_system/widgets/app_banner.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../data/entities/entities.dart';

class AvailableJuzList extends StatefulWidget {
  const AvailableJuzList({
    super.key,
    required this.assignments,
    required this.metadataRepository,
    this.unit = PortionUnit.juz,
    this.onVolunteer,
    this.volunteeringAssignmentId,
  });

  final List<Assignment> assignments;
  final QuranMetadataRepository metadataRepository;
  final PortionUnit unit;
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
    final sorted = rows.toList()
      ..sort(
        (a, b) => widget.unit == PortionUnit.juz
            ? a.juz.compareTo(b.juz)
            : a.portionIndex.compareTo(b.portionIndex),
      );
    if (sorted.isEmpty) return const SizedBox.shrink();

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
                      ArabicStrings.portionName(
                        widget.unit,
                        assignment.portionIndex,
                      ),
                      style: AppTypography.label,
                    ),
                    if (metadataState.connectionState == ConnectionState.done &&
                        !metadataState.hasError) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _range(
                          widget.metadataRepository,
                          widget.unit,
                          assignment.portionIndex,
                        ),
                        style: AppTypography.quranLabel,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    if (assignment.kind == AssignmentKind.volunteer)
                      AppBanner(
                        icon: Icons.volunteer_activism_rounded,
                        message: ArabicStrings.volunteerTaken,
                        variant: AppBannerVariant.success,
                      )
                    else
                      AppButton(
                        label: ArabicStrings.volunteerForJuz,
                        icon: const Icon(Icons.volunteer_activism_rounded),
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

  String _range(
    QuranMetadataRepository metadataRepository,
    PortionUnit unit,
    int index,
  ) {
    if (unit == PortionUnit.juz) {
      final info = metadataRepository.juz(index);
      return ArabicStrings.portionRange(
        metadataRepository.suraName(info.startSura),
        info.startAya,
        metadataRepository.suraName(info.endSura),
        info.endAya,
      );
    }
    final info = metadataRepository.portion(unit, index);
    return ArabicStrings.portionRange(
      metadataRepository.suraName(info.startSura),
      info.startAya,
      metadataRepository.suraName(info.endSura),
      info.endAya,
    );
  }
}
