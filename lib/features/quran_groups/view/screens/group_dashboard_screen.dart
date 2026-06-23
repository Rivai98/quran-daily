import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/app_section_header.dart';
import '../widgets/assignment_list.dart';
import '../widgets/assignment_status_grid.dart';
import '../widgets/dashboard_progress_header.dart';
import '../widgets/dense_info_row.dart';
import '../widgets/offline_stale_banner.dart';
import '../widgets/status_chip.dart';

class GroupDashboardScreen extends StatelessWidget {
  const GroupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicStrings.dashboardTitle),
        actions: [
          IconButton(
            tooltip: ArabicStrings.settingsTitle,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const OfflineStaleBanner(),
          const SizedBox(height: AppSpacing.sm),
          const DashboardProgressHeader(),
          const SizedBox(height: AppSpacing.md),
          _PersonalAssignmentCard(
            onOpen: () => Navigator.pushNamed(context, AppRoutes.assignment),
          ),
          const AppSectionHeader(
            title: ArabicStrings.partsStatusTitle,
            subtitle: ArabicStrings.partsStatusSubtitle,
          ),
          const _StatusLegend(),
          const SizedBox(height: AppSpacing.xs),
          const AssignmentStatusGrid(),
          const AppSectionHeader(
            title: ArabicStrings.membersListTitle,
            subtitle: ArabicStrings.membersListSubtitle,
          ),
          const AssignmentList(),
          const AppSectionHeader(title: ArabicStrings.organizerActionsTitle),
          DenseInfoRow(
            icon: Icons.edit_calendar,
            title: ArabicStrings.reviewAssignmentsAction,
            subtitle: ArabicStrings.publishBlocked,
            accentColor: AppTheme.lateColor,
            onTap: () => Navigator.pushNamed(context, AppRoutes.organizerReview),
            trailing: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: AppSpacing.xs),
          DenseInfoRow(
            icon: Icons.person_add,
            title: ArabicStrings.reviewJoinRequestsAction,
            subtitle: ArabicStrings.memberCount29,
            accentColor: AppTheme.pendingColor,
            onTap: () => Navigator.pushNamed(context, AppRoutes.joinRequests),
            trailing: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: AppSpacing.xs),
          DenseInfoRow(
            icon: Icons.groups,
            title: ArabicStrings.manageMembersAction,
            subtitle: ArabicStrings.activeMembersLabel,
            accentColor: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.members),
            trailing: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: AppSpacing.xs),
          DenseInfoRow(
            icon: Icons.history,
            title: ArabicStrings.openHistoryAction,
            subtitle: ArabicStrings.noMissedParts,
            accentColor: AppTheme.completeColor,
            onTap: () => Navigator.pushNamed(context, AppRoutes.history),
            trailing: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }
}

class _PersonalAssignmentCard extends StatelessWidget {
  const _PersonalAssignmentCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ArabicStrings.yourAssignment,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        ArabicStrings.partRange2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusChip(
                  label: ArabicStrings.pending,
                  status: ReadingStatus.pending,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ArabicStrings.part2,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text(ArabicStrings.openAssignmentAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        StatusChip(label: ArabicStrings.completed, status: ReadingStatus.completed),
        StatusChip(label: ArabicStrings.pending, status: ReadingStatus.pending),
        StatusChip(label: ArabicStrings.late, status: ReadingStatus.late),
        StatusChip(label: ArabicStrings.missed, status: ReadingStatus.missed),
      ],
    );
  }
}
