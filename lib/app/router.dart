import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/localization/arabic_strings.dart';
import '../core/quran/quran_metadata_repository.dart';
import '../core/design_system/widgets/state_panel.dart';
import '../features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import '../features/quran_groups/view/screens/daily_history_screen.dart';
import '../features/quran_groups/view/screens/group_dashboard_screen.dart';
import '../features/quran_groups/view/screens/create_group_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import '../features/quran_groups/cubit/members/members_cubit.dart';
import '../features/quran_groups/view/screens/join_requests_screen.dart';
import '../features/quran_groups/view/screens/members_screen.dart';
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
      dashboard: (context) {
        final groupId = ModalRoute.of(context)?.settings.arguments as String?;
        if (groupId == null || groupId.isEmpty) {
          return Scaffold(
            body: StatePanel(
              icon: Icons.groups,
              title: ArabicStrings.dashboardLoadError,
              message: ArabicStrings.networkFailure,
            ),
          );
        }
        return BlocProvider(
          create: (_) =>
              serviceLocator<DashboardCubit>(param1: groupId)..refresh(),
          child: GroupDashboardScreen(
            metadataRepository: serviceLocator<QuranMetadataRepository>(),
          ),
        );
      },
      assignment: (_) => const PersonalAssignmentDetailScreen(),
      joinRequests: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        return BlocProvider.value(
          value: args['cubit']! as JoinRequestsCubit,
          child: JoinRequestsScreen(groupId: args['groupId']! as String),
        );
      },
      members: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        return BlocProvider.value(
          value: args['cubit']! as MembersCubit,
          child: MembersScreen(
            groupId: args['groupId']! as String,
            isOwner: args['isOwner'] == true,
            isSupervisor: args['isSupervisor'] == true,
          ),
        );
      },
      history: (_) => const DailyHistoryScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }
}

/// Clears every route above the gate (which re-decides auth vs private).
void resetToGate() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
