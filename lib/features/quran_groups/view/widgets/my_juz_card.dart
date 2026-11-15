import 'package:flutter/material.dart';

import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';

class MyJuzCard extends StatelessWidget {
  const MyJuzCard({
    super.key,
    required this.snapshot,
    required this.onOpen,
    required this.metadataRepository,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback onOpen;
  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    final assignment = snapshot.myAssignments.firstWhere(
      (item) => item.isMe,
      orElse: () => snapshot.myAssignments.first,
    );
    final status = design.AssignmentStatus.values.byName(
      assignment.status.name,
    );
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ArabicStrings.myWirdToday,
                    style: AppTypography.title,
                  ),
                ),
                StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              snapshot.portionUnit == PortionUnit.juz
                  ? ArabicNumerals.format(assignment.juz)
                  : ArabicStrings.portionName(
                      snapshot.portionUnit,
                      assignment.portionIndex,
                    ),
              style: snapshot.portionUnit == PortionUnit.juz
                  ? AppTypography.display
                  : AppTypography.quranLabel,
              textAlign: TextAlign.start,
            ),
            FutureBuilder<void>(
              future: metadataRepository.load(),
              builder: (context, state) {
                if (state.connectionState != ConnectionState.done ||
                    state.hasError) {
                  return const SizedBox.shrink();
                }
                final portion = metadataRepository.portion(
                  snapshot.portionUnit,
                  assignment.portionIndex,
                );
                return Text(
                  ArabicStrings.portionRange(
                    metadataRepository.suraName(portion.startSura),
                    portion.startAya,
                    metadataRepository.suraName(portion.endSura),
                    portion.endAya,
                  ),
                  style: AppTypography.bodyLarge,
                );
              },
            ),
            for (final volunteered in snapshot.myAssignments.where(
              (item) => item.kind == AssignmentKind.volunteer,
            )) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.volunteer_activism, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      snapshot.portionUnit == PortionUnit.juz
                          ? '${ArabicStrings.volunteeredJuz}: ${ArabicNumerals.format(volunteered.juz)}'
                          : '${ArabicStrings.volunteeredPortion}: ${ArabicStrings.portionName(snapshot.portionUnit, volunteered.portionIndex)}',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: ArabicStrings.openTodayWird,
              icon: const Icon(Icons.open_in_new),
              expanded: true,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
