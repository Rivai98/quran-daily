import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/dense_info_row.dart';
import '../widgets/state_panel.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.groupSelectionTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          StatePanel(
            icon: Icons.add_circle_outline,
            title: ArabicStrings.noApprovedGroups,
            message: ArabicStrings.publicDiscoveryHint,
            actionLabel: ArabicStrings.createGroup,
            onAction: () => _showCreateGroupSheet(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          DenseInfoRow(
            icon: Icons.travel_explore,
            title: ArabicStrings.discoverGroups,
            subtitle: ArabicStrings.pendingApproval,
            onTap: () => Navigator.pushNamed(context, AppRoutes.discovery),
            trailing: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: AppSpacing.sm),
          DenseInfoRow(
            icon: Icons.groups,
            title: ArabicStrings.groupFajr,
            subtitle:
                '${ArabicStrings.memberCount30} - ${ArabicStrings.timezoneCairo} - ${ArabicStrings.lastSyncFiveMinutes}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard),
            trailing: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ArabicStrings.createPublicGroup,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              const TextField(
                decoration: InputDecoration(
                  labelText: ArabicStrings.groupNameLabel,
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const TextField(
                decoration: InputDecoration(
                  labelText: ArabicStrings.shortDescriptionLabel,
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              const TextField(
                decoration: InputDecoration(
                  labelText: ArabicStrings.timezoneLabel,
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(ArabicStrings.createGroup),
              ),
            ],
          ),
        );
      },
    );
  }
}
