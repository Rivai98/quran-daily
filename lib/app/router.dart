import 'package:flutter/material.dart';

import '../features/auth/view/auth_entry_screen.dart';
import '../features/quran_groups/view/screens/daily_history_screen.dart';
import '../features/quran_groups/view/screens/group_dashboard_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/view/screens/member_management_screen.dart';
import '../features/quran_groups/view/screens/organizer_assignment_review_screen.dart';
import '../features/quran_groups/view/screens/organizer_join_requests_screen.dart';
import '../features/quran_groups/view/screens/personal_assignment_detail_screen.dart';
import '../features/quran_groups/view/screens/public_group_discovery_screen.dart';
import '../features/quran_groups/view/screens/settings_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const auth = '/';
  static const groups = '/groups';
  static const discovery = '/groups/discovery';
  static const dashboard = '/groups/dashboard';
  static const assignment = '/groups/dashboard/assignment';
  static const organizerReview = '/groups/organizer/review';
  static const joinRequests = '/groups/organizer/join-requests';
  static const members = '/groups/organizer/members';
  static const history = '/groups/history';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      auth: (_) => const AuthEntryScreen(),
      groups: (_) => const GroupSelectionScreen(),
      discovery: (_) => const PublicGroupDiscoveryScreen(),
      dashboard: (_) => const GroupDashboardScreen(),
      assignment: (_) => const PersonalAssignmentDetailScreen(),
      organizerReview: (_) => const OrganizerAssignmentReviewScreen(),
      joinRequests: (_) => const OrganizerJoinRequestsScreen(),
      members: (_) => const MemberManagementScreen(),
      history: (_) => const DailyHistoryScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }
}
