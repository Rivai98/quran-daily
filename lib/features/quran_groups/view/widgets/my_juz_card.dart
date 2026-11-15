import 'package:flutter/material.dart';

import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';

class MyJuzCard extends StatelessWidget {
  const MyJuzCard({super.key, required this.snapshot, required this.onOpen});

  final DashboardSnapshot snapshot;
  final VoidCallback onOpen;

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
              ArabicNumerals.format(assignment.juz),
              style: AppTypography.display,
              textAlign: TextAlign.start,
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
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
