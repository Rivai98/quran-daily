import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../widgets/completion_action_panel.dart';
import '../widgets/offline_completion_status.dart';
import '../widgets/state_panel.dart';

class PersonalAssignmentDetailScreen extends StatelessWidget {
  const PersonalAssignmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.assignmentDetailTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.menu_book,
                    color: theme.colorScheme.primary,
                    size: 34,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ArabicStrings.part2,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ArabicStrings.partRange2,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const CompletionActionPanel(),
          const SizedBox(height: AppSpacing.sm),
          const StatePanel(
            icon: Icons.visibility_off_outlined,
            title: ArabicStrings.noQuranReader,
            message: ArabicStrings.noQuranReader,
          ),
          const SizedBox(height: AppSpacing.sm),
          const OfflineCompletionStatus(),
        ],
      ),
    );
  }
}
