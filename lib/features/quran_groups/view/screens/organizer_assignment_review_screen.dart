import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/app_section_header.dart';
import '../widgets/assignment_draft_row.dart';
import '../widgets/validation_banner.dart';

class OrganizerAssignmentReviewScreen extends StatelessWidget {
  const OrganizerAssignmentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.organizerReviewTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const ValidationBanner(
            icon: Icons.warning_amber,
            message: ArabicStrings.publishBlocked,
            color: AppTheme.pendingColor,
          ),
          const AppSectionHeader(
            title: ArabicStrings.reviewAssignmentsAction,
            subtitle: ArabicStrings.partsStatusSubtitle,
          ),
          for (var index = 1; index <= 10; index++) ...[
            AssignmentDraftRow(index: index),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.publish),
            label: const Text(ArabicStrings.publishTodayWird),
          ),
        ],
      ),
    );
  }
}
