import 'package:flutter/material.dart';

import '../features/quran_groups/view/screens/history_screen.dart';
import '../features/quran_groups/view/screens/group_dashboard_screen.dart';
import '../features/quran_groups/view/screens/create_group_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/view/screens/member_management_screen.dart';
import '../features/quran_groups/view/screens/organizer_assignment_review_screen.dart';
import '../features/quran_groups/view/screens/organizer_join_requests_screen.dart';
import '../features/quran_groups/view/screens/personal_assignment_detail_screen.dart';
import '../features/quran_groups/view/screens/public_group_discovery_screen.dart';
import '../features/quran_groups/view/screens/settings_screen.dart';

/// Global navigator key so the auth gate can clear any pushed private
/// routes when the session ends (sign-out/expiry): back navigation and
/// deep links must never rebuild private content while unauthenticated.
final navigatorKey = GlobalKey<NavigatorState>();

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
    // The root "/" is owned by the auth gate in app.dart (home), so it is
    // deliberately absent from this table.
    return {
      groups: (_) => const GroupSelectionScreen(),
      '/groups/new': (_) => const CreateGroupScreen(),
      discovery: (_) => const PublicGroupDiscoveryScreen(),
      dashboard: (_) => const GroupDashboardScreen(),
      assignment: (_) => const PersonalAssignmentDetailScreen(),
      organizerReview: (_) => const OrganizerAssignmentReviewScreen(),
      joinRequests: (_) => const OrganizerJoinRequestsScreen(),
      members: (_) => const MemberManagementScreen(),
      history: (_) => const HistoryScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }
}

/// Clears every route above the gate (which re-decides auth vs private).
void resetToGate() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
