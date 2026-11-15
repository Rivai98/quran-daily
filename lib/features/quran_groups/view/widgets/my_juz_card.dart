import 'package:flutter/material.dart';

import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
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
    return _MyJuzCardContent(
      assignment: assignment,
      snapshot: snapshot,
      status: status,
      onOpen: onOpen,
      metadataRepository: metadataRepository,
    );
  }
}

class _MyJuzCardContent extends StatefulWidget {
  const _MyJuzCardContent({
    required this.assignment,
    required this.snapshot,
    required this.status,
    required this.onOpen,
    required this.metadataRepository,
  });

  final Assignment assignment;
  final DashboardSnapshot snapshot;
  final design.AssignmentStatus status;
  final VoidCallback onOpen;
  final QuranMetadataRepository metadataRepository;

  @override
  State<_MyJuzCardContent> createState() => _MyJuzCardContentState();
}

class _MyJuzCardContentState extends State<_MyJuzCardContent> {
  late final Future<void> _metadata = widget.metadataRepository.load();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      highlighted: true,
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
                StatusChip(status: widget.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ArabicStrings.juzOrdinals[widget.assignment.juz - 1],
              style: AppTypography.quranLabel,
            ),
            FutureBuilder<void>(
              future: _metadata,
              builder: (context, state) {
                if (state.connectionState != ConnectionState.done ||
                    state.hasError) {
                  return const SizedBox.shrink();
                }
                final info = widget.metadataRepository.juz(
                  widget.assignment.juz,
                );
                return Text(
                  '${widget.metadataRepository.suraName(info.startSura)} '
                  '${ArabicNumerals.format(info.startAya)} – '
                  '${widget.metadataRepository.suraName(info.endSura)} '
                  '${ArabicNumerals.format(info.endAya)}',
                  style: AppTypography.quranLabel,
                );
              },
            ),
            for (final volunteered in widget.snapshot.myAssignments.where(
              (item) => item.kind == AssignmentKind.volunteer,
            )) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.volunteer_activism, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${ArabicStrings.volunteeredJuz}: ${ArabicNumerals.format(volunteered.juz)}',
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
              onPressed: widget.onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
