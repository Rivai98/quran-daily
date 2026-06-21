import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../widgets/assignment_list.dart';
import '../widgets/assignment_status_grid.dart';
import '../widgets/dashboard_progress_header.dart';
import '../widgets/offline_stale_banner.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          const OfflineStaleBanner(),
          const SizedBox(height: 12),
          const DashboardProgressHeader(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('وردك: جزء 2'),
              subtitle: const Text('البقرة 142 إلى البقرة 252'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.pushNamed(context, AppRoutes.assignment),
            ),
          ),
          const SizedBox(height: 16),
          Text('حالة الأجزاء', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const AssignmentStatusGrid(),
          const SizedBox(height: 16),
          Text('قائمة الأعضاء', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const AssignmentList(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.organizerReview),
                icon: const Icon(Icons.edit_calendar),
                label: const Text(ArabicStrings.organizerReviewTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.joinRequests),
                icon: const Icon(Icons.person_add),
                label: const Text(ArabicStrings.joinRequestsTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.members),
                icon: const Icon(Icons.groups),
                label: const Text(ArabicStrings.memberManagementTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                icon: const Icon(Icons.history),
                label: const Text(ArabicStrings.historyTitle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
