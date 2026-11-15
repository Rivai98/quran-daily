import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';

class AvailableJuzList extends StatelessWidget {
  const AvailableJuzList({
    super.key,
    required this.assignments,
    required this.metadataRepository,
  });

  final List<Assignment> assignments;
  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    final available =
        assignments
            .where(
              (assignment) =>
                  assignment.status == AssignmentStatusEnum.available,
            )
            .toList()
          ..sort((a, b) => a.juz.compareTo(b.juz));
    if (available.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<void>(
      future: metadataRepository.load(),
      builder: (context, state) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ArabicStrings.availableJuzTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            for (final assignment in available)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppSpacing.xs,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: AppRadius.mdBR,
                  ),
                  child: Padding(
                    padding: AppSpacing.compactCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ArabicStrings.juzOrdinals[assignment.juz - 1],
                          style: AppTypography.label,
                        ),
                        if (state.connectionState == ConnectionState.done &&
                            state.hasError == false) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _range(assignment.juz),
                            style: AppTypography.quranLabel,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _range(int juz) {
    final info = metadataRepository.juz(juz);
    final start = metadataRepository.suraName(info.startSura);
    final end = metadataRepository.suraName(info.endSura);
    return '$start ${ArabicNumerals.format(info.startAya)} — '
        '$end ${ArabicNumerals.format(info.endAya)}';
  }
}
