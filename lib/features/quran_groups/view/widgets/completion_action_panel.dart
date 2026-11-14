import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'status_chip.dart';

class CompletionActionPanel extends StatelessWidget {
  const CompletionActionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusChip(
              label: ArabicStrings.pending,
              status: ReadingStatus.pending,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ArabicStrings.assignmentCompleteHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text(ArabicStrings.completeAction),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.undo),
              label: const Text(ArabicStrings.undoAction),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ArabicStrings.undoCompletionHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
