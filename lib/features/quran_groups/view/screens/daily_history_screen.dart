import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../widgets/app_section_header.dart';
import '../widgets/history_assignment_detail.dart';
import '../widgets/history_day_summary_tile.dart';
import '../widgets/state_panel.dart';

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      (
        ArabicStrings.june20,
        '30 / 30',
        '100%',
        ArabicStrings.noMissedParts,
      ),
      (
        ArabicStrings.june19,
        '27 / 30',
        '90%',
        ArabicStrings.threeMissedParts,
      ),
      (
        ArabicStrings.june18,
        '29 / 30',
        '97%',
        ArabicStrings.oneLatePart,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.historyTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const StatePanel(
            icon: Icons.history,
            title: ArabicStrings.emptyHistory,
            message: ArabicStrings.emptyHistory,
          ),
          const AppSectionHeader(title: ArabicStrings.historyTitle),
          for (final day in days) ...[
            HistoryDaySummaryTile(
              day: day.$1,
              count: day.$2,
              percent: day.$3,
              detail: day.$4,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const AppSectionHeader(title: ArabicStrings.oneLatePart),
          const HistoryAssignmentDetail(),
        ],
      ),
    );
  }
}
